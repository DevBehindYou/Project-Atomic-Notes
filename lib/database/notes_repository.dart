import 'dart:async';

import 'package:atomic_notes/database/energy_service.dart';
import 'package:atomic_notes/database/note.dart';
import 'package:atomic_notes/database/note_quota.dart';
import 'package:atomic_notes/database/sync_status.dart';
import 'package:atomic_notes/security/vault.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for notes, and the sync engine.
///
/// Replaces the old model where seven screens each built their own
/// `NotesDataBase` with its own in-memory copy, and where the entire notebook
/// was pushed as one base64 blob. That blob was last-write-wins across *every*
/// note at once: a second device syncing didn't merge with the first, it
/// replaced everything the first had written. That is why notes never appeared
/// on a second phone.
///
/// Now: one row per note, last-write-wins per note on a server-set
/// `updated_at`, tombstones for deletes, and a realtime subscription so a
/// change on one device lands on the others without a manual sync.
class NotesRepository extends ChangeNotifier {
  NotesRepository._();
  static final NotesRepository instance = NotesRepository._();

  static const String boxName = 'notesBox';
  static const String _table = 'note';

  /// Reserved Hive key tagging which account this local cache belongs to. Stored
  /// as a plain String, so the `is Map` guards in the loaders skip right over
  /// it. It is what lets a device keep one user's offline notes while refusing
  /// to show them to a different user who signs in later.
  static const String _ownerKey = '__cache_owner__';

  late Box _box;
  SupabaseClient get _sb => Supabase.instance.client;
  String? get _userId => _sb.auth.currentUser?.id;

  StreamSubscription<List<Map<String, dynamic>>>? _realtime;
  StreamSubscription<List<ConnectivityResult>>? _connectivity;

  /// Periodic background ("hourly") standard sync. Editing a note no longer
  /// uploads immediately — a change stays local until the user taps sync
  /// (instant) or this timer fires (standard, server-windowed to once/hour).
  Timer? _hourly;

  bool _syncing = false;
  bool get isSyncing => _syncing;

  String? lastError;
  DateTime? lastSyncedAt;

  /// In-memory index, id -> note.
  final Map<String, Note> _notes = {};

  // ---- lifecycle --------------------------------------------------------

  Future<void> init() async {
    _box = await Hive.openBox(boxName);
    await _loadFromDisk();

    // Push anything that was written while offline as soon as we're back.
    _connectivity = Connectivity().onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        unawaited(syncNow());
      }
    });
  }

  Future<void> _loadFromDisk() async {
    _notes.clear();
    // A cache written by a different account — a previous user whose session
    // expired without an explicit logout — must never surface for this one.
    // (Explicit logout already wipes the box; this covers the expiry path.)
    final owner = _box.get(_ownerKey);
    final uid = _userId;
    if (owner is String && uid != null && owner != uid) {
      await _box.clear();
      return;
    }
    for (final raw in _box.values) {
      if (raw is Map) {
        final opened = await _open(raw);
        if (opened == null) continue; // encrypted + locked: load after unlock
        final n = Note.fromMap(opened);
        _notes[n.id] = n;
      }
    }
  }

  // ---- encryption boundary ---------------------------------------------
  // When the vault is unlocked, note content (title/body/items) is sealed into
  // `payload` and the plaintext fields are emptied before anything is written
  // to Hive or Supabase, and re-opened on the way back. When encryption is off
  // these are pass-throughs, so plaintext behaviour is unchanged.

  Future<Map<String, dynamic>> _sealLocal(Note n) => _seal(n.toMap());
  Future<Map<String, dynamic>> _sealRemote(Note n, String uid) =>
      _seal(n.toRemote(uid));

  Future<Map<String, dynamic>> _seal(Map<String, dynamic> m) async {
    // T2T: the vault is off or locked on this device, so the note is stored in
    // the clear and stays readable to any signed-in device.
    if (!Vault.instance.isUnlocked) {
      m['enc_v'] = 0;
      m['payload'] = null;
      return m;
    }
    m['payload'] = await Vault.instance.encryptContent({
      'title': m['title'] ?? '',
      'body': m['body'] ?? '',
      'items': m['items'] ?? const <dynamic>[],
    });
    m['enc_v'] = Vault.encVersion;
    m['title'] = '';
    m['body'] = '';
    m['items'] = const <dynamic>[];
    return m;
  }

  /// Inverse of [_seal]. Returns a plaintext map ready for Note.fromMap/
  /// fromRemote, or null if the row is encrypted but the vault is locked or the
  /// content can't be decrypted (caller skips it and retries after unlock).
  Future<Map<String, dynamic>?> _open(Map<dynamic, dynamic> m) async {
    final out = m.map((k, v) => MapEntry(k.toString(), v));
    final encV = out['enc_v'] is int ? out['enc_v'] as int : 0;
    final payload = out['payload'];
    if (encV < 1 || payload is! String) return out;
    if (!Vault.instance.isUnlocked) return null;
    try {
      final content = await Vault.instance.decryptContent(payload);
      out['title'] = content['title'] ?? '';
      out['body'] = content['body'] ?? '';
      out['items'] = content['items'] ?? const <dynamic>[];
      return out;
    } catch (e) {
      debugPrint('NotesRepository: could not decrypt note ${out['id']}: $e');
      return null;
    }
  }

  /// Called after sign-in, and on startup when a session already exists.
  ///
  /// Returns as soon as the (cheap, local) subscription is registered — the
  /// actual network sync runs in the background. Nothing in the UI should
  /// ever wait for this.
  Future<void> start() async {
    final uid = _userId;
    if (uid == null) return;
    // Isolation on the hot path (logout/expiry then a different user signs in
    // without an app restart): if the disk cache belongs to another account,
    // drop it before this user's notes load in. Same user keeps their cache.
    final owner = _box.get(_ownerKey);
    if (owner is String && owner != uid) {
      _notes.clear();
      await _box.clear();
      notifyListeners();
    }
    await _box.put(_ownerKey, uid);
    _listenRealtime();
    // Initial sync: fetches existing cloud notes (a free pull when there's
    // nothing pending). Editing does NOT sync after this — only this hourly
    // timer or a manual sync uploads changes.
    unawaited(syncNow());
    _hourly?.cancel();
    _hourly = Timer.periodic(
        const Duration(hours: 1), (_) => unawaited(syncNow()));
  }

  Future<void> stop() async {
    await _realtime?.cancel();
    _realtime = null;
    _hourly?.cancel();
    _hourly = null;
  }

  /// Drop the in-memory notes without touching the on-disk cache. Used by the
  /// session guard on sign-out so the UI can't show the previous user's notes,
  /// while a same-user re-login can still reuse the local cache.
  void clearMemory() {
    _notes.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_realtime?.cancel());
    unawaited(_connectivity?.cancel());
    _hourly?.cancel();
    super.dispose();
  }

  // ---- reads ------------------------------------------------------------

  /// Live notes, tombstones excluded, pinned first.
  List<Note> visible({NoteFilter filter = NoteFilter.newest}) {
    final list = _notes.values.where((n) => !n.deleted).toList();

    switch (filter) {
      case NoteFilter.todos:
        list.retainWhere((n) => n.kind == NoteKind.todo);
      case NoteFilter.notes:
        list.retainWhere((n) => n.kind == NoteKind.text);
      case NoteFilter.newest:
      case NoteFilter.oldest:
        break;
    }

    list.sort((a, b) {
      if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
      return filter == NoteFilter.oldest
          ? a.createdAt.compareTo(b.createdAt)
          : b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }

  int get count => _notes.values.where((n) => !n.deleted).length;
  int get pendingCount => _notes.values.where((n) => n.dirty).length;

  Note? byId(String id) => _notes[id];

  // ---- quota ------------------------------------------------------------

  /// Notes and to-dos share one allowance — a checklist is a note.
  int get limit => NoteQuota.limit;

  int get remaining => (limit - count).clamp(0, limit);

  bool get isAtLimit => count >= limit;

  /// Tombstones don't count, so deleting frees a slot immediately.
  String get usageLabel => '$count / $limit';

  // ---- writes -----------------------------------------------------------

  Future<void> save(Note note) async {
    note.touch();
    _notes[note.id] = note;
    await _box.put(note.id, await _sealLocal(note));
    notifyListeners();
    // No auto-upload: the note is saved locally and marked dirty; it reaches the
    // cloud only on a manual (instant) sync or the hourly background sync.
  }

  /// Soft delete, so the removal can reach other devices.
  Future<void> deleteNotes(Iterable<String> ids) async {
    for (final id in ids) {
      final n = _notes[id];
      if (n == null) continue;
      n.deleted = true;
      n.touch();
      await _box.put(n.id, await _sealLocal(n));
    }
    notifyListeners();
    // Saved locally as a tombstone; the deletion reaches the cloud on the next
    // manual or hourly sync, not immediately.
  }

  /// Wipes the local cache only — used on logout. Does not touch the server.
  Future<void> clearLocal() async {
    _notes.clear();
    await _box.clear();
    lastSyncedAt = null;
    notifyListeners();
  }

  // ---- sync -------------------------------------------------------------

  /// How long a sync may take before we give up. A device can report a live
  /// connection and still have no route out (captive portals, hotel wifi), so
  /// a connectivity check alone isn't enough — without a deadline the request
  /// just sits there.
  static const Duration _netTimeout = Duration(seconds: 20);

  /// Push local changes, then pull remote ones. Safe to call often.
  ///
  /// Cloud sync is energy-gated. Uploading changes costs energy: [instant] sync
  /// (the manual button) costs 10 every time; a standard/background sync costs 5
  /// at most once per hour (free within the paid hour). A sync with nothing to
  /// upload (receive-only) is free. If the balance can't cover the upload, the
  /// notes stay safely on the device (still dirty) and nothing is pushed — so at
  /// zero energy local notes keep working but don't reach the cloud until energy
  /// is topped up.
  Future<bool> syncNow({bool instant = false}) async {
    if (_syncing) return true;
    final uid = _userId;
    if (uid == null) return false;
    if (!SyncStatusHelper.isSyncOn) return false;

    // Don't sit on a dead socket when we already know there's no network.
    final conn = await Connectivity().checkConnectivity();
    if (conn.contains(ConnectivityResult.none)) {
      lastError = 'Offline — changes are saved on this device';
      return false;
    }

    // Energy gate: only charge when there are local changes to upload. The
    // charge happens BEFORE the push (so a zero balance can't sync), and is
    // refunded below if the upload fails — energy is never lost to a dropped
    // network. [charged] is the exact amount taken (10 instant; 0 or 5 standard).
    final hasPending = _notes.values.any((n) => n.dirty);
    var charged = 0;
    if (hasPending) {
      if (instant) {
        final err = await EnergyService.instance.spendInstant();
        if (err != null) {
          lastError =
              'Not enough Atomic Energy to sync — changes saved on this device';
          notifyListeners();
          return false;
        }
        charged = EnergyService.syncInstantCost;
      } else {
        final amt = await EnergyService.instance.spendStandard();
        if (amt == null) {
          lastError =
              'Not enough Atomic Energy to sync — changes saved on this device';
          notifyListeners();
          return false;
        }
        charged = amt;
      }
    }

    _syncing = true;
    lastError = null;
    notifyListeners();
    try {
      await _push(uid).timeout(_netTimeout);
      await _pull(uid).timeout(_netTimeout);
      lastSyncedAt = DateTime.now();
      return true;
    } on TimeoutException {
      if (charged > 0) {
        unawaited(
            EnergyService.instance.refund(charged, 'Sync refund (timeout)'));
      }
      lastError = 'Sync timed out — changes are saved on this device';
      debugPrint('NotesRepository.syncNow timed out');
      return false;
    } catch (e) {
      if (charged > 0) {
        unawaited(
            EnergyService.instance.refund(charged, 'Sync refund (error)'));
      }
      // The server enforces the allowance too (migration 003). Translate its
      // error rather than showing the raw Postgres exception.
      lastError = e.toString().contains('note_limit_reached')
          ? 'Note limit reached on the server — delete a note and sync again'
          : e.toString();
      debugPrint('NotesRepository.syncNow failed: $e');
      return false;
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  Future<void> _push(String uid) async {
    final dirty = _notes.values.where((n) => n.dirty).toList();
    if (dirty.isEmpty) return;

    // One upsert for the batch. `id` is the conflict target, so a note
    // created offline on two devices can't duplicate. Content is sealed first
    // when encryption is on.
    final rows = await Future.wait(dirty.map((n) => _sealRemote(n, uid)));
    await _sb.from(_table).upsert(rows, onConflict: 'id');

    for (final n in dirty) {
      n.dirty = false;
      await _box.put(n.id, await _sealLocal(n));
    }
  }

  Future<void> _pull(String uid) async {
    // Incremental: only rows touched since the last successful pull. The
    // first pull after install fetches everything.
    var query = _sb.from(_table).select().eq('user_id', uid);
    // A device that cannot decrypt must not even fetch ciphertext: knowing the
    // account password is not enough to reach vault notes.
    if (!Vault.instance.isUnlocked) {
      query = query.eq('enc_v', 0);
    }
    final since = lastSyncedAt;
    if (since != null) {
      query = query.gt('updated_at', since.toUtc().toIso8601String());
    }
    final rows = await query;
    await _mergeAll((rows as List).cast<Map<String, dynamic>>(), uid);
  }

  void _listenRealtime() {
    final uid = _userId;
    if (uid == null || _realtime != null) return;

    // Realtime must be enabled on the table (see migration 002) or this
    // stream stays silent.
    _realtime = _sb
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .listen(
          (rows) => unawaited(_mergeAll(rows, uid)),
          onError: (e) {
            lastError = e.toString();
            debugPrint('NotesRepository realtime error: $e');
          },
        );
  }

  /// Last-write-wins per note, on the server's `updated_at`.
  ///
  /// [forUid] is the account the rows were fetched for. If the session has since
  /// changed (logout or expiry completed while this fetch/stream event was in
  /// flight), the rows are dropped rather than merged — otherwise a late fetch
  /// would repopulate the UI with the previous user's notes after sign-out.
  Future<void> _mergeAll(List<Map<String, dynamic>> rows, String forUid) async {
    if (_userId != forUid) return;
    var changed = false;
    for (final row in rows) {
      if (_userId != forUid) return; // session ended mid-merge
      final opened = await _open(row);
      if (opened == null) continue; // encrypted + locked: retry after unlock
      final remote = Note.fromRemote(opened);
      final local = _notes[remote.id];

      if (local == null) {
        _notes[remote.id] = remote;
        await _box.put(remote.id, await _sealLocal(remote));
        changed = true;
        continue;
      }

      // Never let a pull clobber an edit that hasn't been pushed yet.
      if (local.dirty && local.updatedAt.isAfter(remote.updatedAt)) continue;

      if (remote.updatedAt.isAfter(local.updatedAt)) {
        _notes[remote.id] = remote;
        await _box.put(remote.id, await _sealLocal(remote));
        changed = true;
      }
    }
    if (changed && _userId == forUid) notifyListeners();
  }

  /// Re-seal every note this device holds and push them.
  ///
  /// Runs after the vault is created and after every unlock, so notes written
  /// while the vault was off or locked (T2T) are converted to vault notes. It
  /// is idempotent: re-sealing an already-sealed note just rewrites it, so an
  /// interrupted run is safe to repeat.
  Future<void> migrateToVault() async {
    if (!Vault.instance.isUnlocked) return;
    if (_notes.isEmpty) return;
    debugPrint('NotesRepository: migrating ${_notes.length} notes into the vault');
    for (final n in _notes.values) {
      n.dirty = true;
      await _box.put(n.id, await _sealLocal(n));
    }
    notifyListeners();
    await syncNow();
    debugPrint('NotesRepository: vault migration complete');
  }

  /// After unlocking on a device that was holding notes it could not read,
  /// re-read the local cache, pull everything, and fold any plaintext notes
  /// into the vault.
  Future<void> reloadAfterUnlock() async {
    await _loadFromDisk();
    lastSyncedAt = null;
    notifyListeners();
    await syncNow();
    await migrateToVault();
  }

  /// Any sealed payload this device already holds, so an offline device can
  /// check a recovery phrase without reaching the server.
  String? get sampleCiphertext {
    for (final raw in _box.values) {
      if (raw is Map) {
        final v = raw['enc_v'];
        final p = raw['payload'];
        if (v is int && v >= 1 && p is String && p.isNotEmpty) return p;
      }
    }
    return null;
  }

  // ---- maintenance ------------------------------------------------------

  /// Number of live notes on the server, for the Database screen.
  ///
  /// Counts rows, not readable notes: an encrypted row still counts while this
  /// device is locked, which is what makes the on-device and in-cloud numbers
  /// comparable.
  Future<int> remoteCount() async {
    final uid = _userId;
    if (uid == null) return 0;
    try {
      final res = await _sb
          .from(_table)
          .select('id')
          .eq('user_id', uid)
          .eq('deleted', false)
          .count(CountOption.exact);
      return res.count;
    } catch (e) {
      debugPrint('NotesRepository.remoteCount failed: $e');
      return 0;
    }
  }

  /// Hard-deletes every note row for this user, tombstones included.
  ///
  /// Deliberately leaves the vault row alone: it holds the phrase verifier, and
  /// dropping it would strand notes still encrypted on other devices.
  Future<String> wipeRemote() async {
    final uid = _userId;
    if (uid == null) return 'Not signed in';
    try {
      await _sb.from(_table).delete().eq('user_id', uid);
      return 'Cloud data deleted successfully';
    } catch (e) {
      lastError = e.toString();
      debugPrint('NotesRepository.wipeRemote failed: $e');
      return 'Failed to delete data';
    }
  }
}
