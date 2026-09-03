import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'seed_phrase.dart';
import 'vault_crypto.dart';

/// Thrown when a vault already exists for the account, so creating a new one
/// would orphan every note already encrypted under the old key.
class VaultAlreadyExistsError implements Exception {
  const VaultAlreadyExistsError();
  @override
  String toString() => 'A vault already exists for this account';
}

/// Thrown when a phrase cannot be checked because the verifier is unreachable
/// and there is nothing local to test against.
class VaultUnverifiableError implements Exception {
  const VaultUnverifiableError();
  @override
  String toString() => 'Cannot verify the phrase while offline';
}

/// End-to-end encryption for note content.
///
/// The key is derived from the recovery phrase and the account id, and nothing
/// else:
///
///   key = Argon2id(phrase, salt = SHA-256("atomic-notes-vault-v1|<user id>"))
///
/// That is a pure function, which is the whole point. The same phrase on any
/// number of devices produces the same key, with no key material to fetch and
/// nothing that can drift out of sync. The server stores only a verifier (a
/// known constant sealed with the key) so a wrong phrase is rejected
/// immediately. The phrase and the key never leave the device.
///
/// This replaces an earlier design where a random key was generated at setup
/// and wrapped by the phrase. That design had a fatal multi-device failure:
/// running setup twice minted a second, unrelated key and overwrote the stored
/// copy of the first, so the same phrase on two devices produced two different
/// keys and each device could read only its own notes.
class Vault {
  Vault._();
  static final Vault instance = Vault._();

  static const String _table = 'vault';
  static const int encVersion = 1;

  /// Argon2id parameters. Stored on the row so they can be raised later without
  /// invalidating existing vaults: unlock always uses the values it reads back.
  /// 64 MB is heavy enough to hurt an offline attacker and still finishes in
  /// well under a second on a modern phone.
  static const int kdfMemory = 65536; // KiB
  static const int kdfIterations = 3;
  static const int kdfParallelism = 1;

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  SecretKey? _key;
  bool _enabled = false;
  String? _boundUser;

  SupabaseClient get _sb => Supabase.instance.client;
  String? get _uid => _sb.auth.currentUser?.id;
  String _keyStore(String uid) => 'atomic_vault_key_$uid';

  /// The account has a vault configured.
  bool get isEnabled => _enabled;

  /// The key is in memory, so vault notes can be read and written.
  bool get isUnlocked => _key != null;

  /// A vault exists but this device cannot open it yet.
  bool get isLocked => _enabled && _key == null;

  // ---- lifecycle --------------------------------------------------------

  /// Work out the vault state for the CURRENT user, and unlock from the device
  /// key store if this device has been unlocked before.
  ///
  /// This must run after every sign-in, not just at process start. It used to be
  /// called only from main(), which runs before the user has a session: on a
  /// second phone the account id was still null at that point, so the vault was
  /// recorded as not configured for the whole session. The unlock screen never
  /// appeared, encrypted notes were silently skipped as unreadable, and new
  /// notes were written in the clear. splash_screen now calls this on every
  /// launch and after every login, which is what makes it correct.
  Future<void> init() async {
    final uid = _uid;

    // A different account on this device must never inherit the previous key.
    if (uid != _boundUser) {
      _key = null;
      _enabled = false;
      _boundUser = uid;
    }
    if (uid == null) return;

    try {
      // Bounded: offline with an expired token, the client tries to refresh
      // before this request and would otherwise retry indefinitely — which,
      // since init() is awaited at startup, hangs the whole app on a blank
      // screen. Failing fast here drops to the cached-key path so the app
      // always opens (local-first).
      final row = await _sb
          .from(_table)
          .select('user_id')
          .eq('user_id', uid)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));
      _enabled = row != null;
    } catch (e) {
      // Offline: a key cached on this device proves a vault exists.
      _enabled = (await _secure.read(key: _keyStore(uid))) != null;
      debugPrint('Vault.init: state read failed, using cached state ($e)');
    }

    if (_enabled && _key == null) {
      final cached = await _secure.read(key: _keyStore(uid));
      if (cached != null) {
        _key = SecretKey(base64Decode(cached));
        debugPrint('Vault: unlocked from device key store');
      }
    }
  }

  // ---- setup ------------------------------------------------------------

  /// Turn on encryption for this account.
  ///
  /// Refuses if a vault already exists, checked against the server at call time
  /// rather than trusting cached state. Replacing a vault row is the one
  /// operation that can permanently orphan notes.
  Future<void> createVault(List<String> phrase) async {
    final uid = _uid;
    if (uid == null) throw StateError('Not signed in');

    final existing = await _sb
        .from(_table)
        .select('user_id')
        .eq('user_id', uid)
        .maybeSingle();
    if (existing != null) {
      _enabled = true;
      throw const VaultAlreadyExistsError();
    }

    final key = await _deriveKey(SeedPhrase.canonical(phrase), uid);
    final verifier = await VaultCrypto.makeVerifier(key);

    try {
      // insert, never upsert: if a row appeared in the meantime the primary key
      // rejects this instead of silently replacing the vault.
      await _sb.from(_table).insert({
        'user_id': uid,
        'verifier': verifier,
        'kdf': 'argon2id',
        'kdf_memory': kdfMemory,
        'kdf_iterations': kdfIterations,
        'kdf_parallelism': kdfParallelism,
        'enc_v': encVersion,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        _enabled = true;
        throw const VaultAlreadyExistsError();
      }
      rethrow;
    }

    _key = key;
    _enabled = true;
    await _cacheKey(uid, key);
    debugPrint('Vault: created and unlocked');
  }

  // ---- unlock -----------------------------------------------------------

  /// Try to open the vault with [phrase]. Returns true when it is correct.
  ///
  /// [sampleCiphertext] is any note payload this device already holds; it lets
  /// an offline device verify without the server. Throws
  /// [VaultUnverifiableError] when neither the verifier nor a sample is
  /// available, rather than accepting a phrase it could not check.
  Future<bool> unlock(List<String> phrase, {String? sampleCiphertext}) async {
    final uid = _uid;
    if (uid == null) return false;

    Map<String, dynamic>? row;
    try {
      row = await _sb.from(_table).select().eq('user_id', uid).maybeSingle();
    } catch (e) {
      debugPrint('Vault.unlock: verifier unreachable ($e)');
    }

    final key = await _deriveKey(
      SeedPhrase.canonical(phrase),
      uid,
      memory: row?['kdf_memory'] as int?,
      iterations: row?['kdf_iterations'] as int?,
      parallelism: row?['kdf_parallelism'] as int?,
    );

    final verifier = row?['verifier'] as String?;
    bool ok;
    if (verifier != null) {
      ok = await VaultCrypto.checkVerifier(verifier, key);
    } else if (sampleCiphertext != null) {
      ok = await _opens(sampleCiphertext, key);
    } else {
      throw const VaultUnverifiableError();
    }

    if (!ok) {
      debugPrint('Vault: unlock rejected, phrase did not verify');
      return false;
    }

    _key = key;
    _enabled = true;
    await _cacheKey(uid, key);
    debugPrint('Vault: unlocked');
    return true;
  }

  Future<bool> _opens(String payload, SecretKey key) async {
    try {
      await VaultCrypto.open(payload, key);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<SecretKey> _deriveKey(
    String canonicalPhrase,
    String uid, {
    int? memory,
    int? iterations,
    int? parallelism,
  }) async {
    final salt = await VaultCrypto.saltForUser(uid);
    return VaultCrypto.deriveKey(
      canonicalPhrase,
      salt,
      memory: memory ?? kdfMemory,
      iterations: iterations ?? kdfIterations,
      parallelism: parallelism ?? kdfParallelism,
    );
  }

  // ---- content ----------------------------------------------------------

  Future<String> encryptContent(Map<String, dynamic> content) {
    final key = _key;
    if (key == null) throw StateError('Vault is locked');
    return VaultCrypto.sealJson(content, key);
  }

  Future<Map<String, dynamic>> decryptContent(String payload) {
    final key = _key;
    if (key == null) throw StateError('Vault is locked');
    return VaultCrypto.openJson(payload, key);
  }

  // ---- device / session -------------------------------------------------

  /// Forget the key on this device only. The account stays encrypted and the
  /// phrase is needed to open it here again.
  Future<void> lockThisDevice() async {
    final uid = _uid;
    _key = null;
    if (uid != null) await _secure.delete(key: _keyStore(uid));
    debugPrint('Vault: locked on this device');
  }

  /// Drop the decryption key from RAM only, without deleting the device key
  /// store. Used by the session guard on any sign-out (including a session that
  /// simply expired): decrypted vault content is immediately unreadable, yet the
  /// same user signing back in on this device can still auto-unlock. A different
  /// user gets nothing — [init] rebinds per account and only reads that
  /// account's key store entry.
  void lockMemory() {
    _key = null;
  }

  /// Wipe key material for this device. Call on logout BEFORE signOut, while
  /// the user id is still readable.
  Future<void> clearLocal() async {
    final uid = _uid;
    _key = null;
    _enabled = false;
    _boundUser = null;
    if (uid != null) await _secure.delete(key: _keyStore(uid));
  }

  Future<void> _cacheKey(String uid, SecretKey key) async {
    final bytes = await key.extractBytes();
    await _secure.write(key: _keyStore(uid), value: base64Encode(bytes));
  }
}
