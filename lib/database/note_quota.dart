import 'package:hive_ce/hive_ce.dart';

/// How many notes this account may hold.
///
/// Deliberately a stored value rather than a constant: the plan is to sell
/// extra capacity later (watch ads -> coins -> more notes, longer sync
/// intervals, AI features, task notifications). When that lands, raising a
/// user's cap is [setLimit] plus whatever grants the entitlement — no change
/// to the enforcement code.
///
/// **This is a client-side cap only.** It stops honest over-use and keeps the
/// UI honest, but anyone can bypass it by talking to the API directly. The
/// moment capacity is something people pay for, the real limit has to be
/// enforced in Postgres — see supabase/migrations/003_note_limit.sql, which
/// does exactly that and is the number that actually counts.
class NoteQuota {
  NoteQuota._();

  static const String boxName = 'prefsBox';
  static const String _limitKey = 'noteLimit';

  /// What a new account gets.
  static const int freeLimit = 20;

  static Box? _box;

  static Future<void> init() async {
    _box = await Hive.openBox(boxName);
  }

  /// Current cap. Counts notes and to-dos together — a checklist is a note.
  static int get limit {
    final v = _box?.get(_limitKey);
    return v is int && v > 0 ? v : freeLimit;
  }

  /// Raise (or lower) the cap. The hook the future coin system writes to.
  static Future<void> setLimit(int value) async {
    await _box?.put(_limitKey, value);
  }

  /// Back to the free tier.
  static Future<void> reset() async {
    await _box?.delete(_limitKey);
  }
}
