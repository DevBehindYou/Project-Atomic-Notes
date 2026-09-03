import 'package:atomic_notes/database/energy_models.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Single source of truth for Atomic Energy + Atomic Coins on the client.
///
/// Same shape as [NotesRepository]/[Vault]: a singleton [ChangeNotifier] that
/// reads server-authoritative balances and never computes its own. Every
/// mutation goes through a SECURITY DEFINER RPC (see
/// supabase/migrations/006_energy.sql); the client can read the balance but the
/// database is what changes it.
///
/// Modular by design: other features call [spend]/[convertCoins] without
/// importing the Energy screen.
class EnergyService extends ChangeNotifier {
  EnergyService._();
  static final EnergyService instance = EnergyService._();

  // Economy constants, mirrored from the SQL so the UI can explain them.
  // The server is authoritative; these are for display/estimation only.
  static const int coinToEnergy = 40; // 1 coin -> 40 energy
  static const int dailyGrant = 20; // +20 every 24h (server clock)
  // Note: the full capacity (120) is per-user and read from the wallet via the
  // `energyCap` instance getter below — no static constant, to avoid shadowing.
  static const int syncStandardCost = 5; // hourly/standard sync (4 per grant)
  static const int syncInstantCost = 10; // instant sync (2 per grant)

  SupabaseClient get _sb => Supabase.instance.client;
  String? get _uid => _sb.auth.currentUser?.id;

  Wallet _wallet = Wallet.empty;
  List<EnergyTx> _history = const [];
  bool _loading = false;
  String? _error;
  String? _boundUser;

  Wallet get wallet => _wallet;
  List<EnergyTx> get history => _history;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasLoaded => _boundUser != null && _boundUser == _uid;

  int get coins => _wallet.coins;
  int get energy => _wallet.energy;
  int get energyCap => _wallet.energyCap;

  // ---- lifecycle --------------------------------------------------------

  /// Run after sign-in (splash) and any time the screen wants fresh data.
  /// Ensures a wallet row exists, applies the daily grant, then loads.
  Future<void> init() async {
    final uid = _uid;
    // A different account must never see the previous user's balances.
    if (uid != _boundUser) {
      _wallet = Wallet.empty;
      _history = const [];
      _error = null;
      _boundUser = uid;
    }
    if (uid == null) return;
    try {
      await _sb.rpc('energy_ensure');
      await _sb.rpc('energy_grant_daily');
    } catch (e) {
      // Non-fatal: the account may be offline. refresh() will still try.
      debugPrint('EnergyService.init grant skipped: $e');
    }
    await refresh();
  }

  /// Drop in-memory balances (called on logout by SessionGuard).
  void clear() {
    _wallet = Wallet.empty;
    _history = const [];
    _error = null;
    _boundUser = null;
    notifyListeners();
  }

  // ---- reads ------------------------------------------------------------

  Future<void> refresh() async {
    final uid = _uid;
    if (uid == null) return;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final row = await _sb
          .from('atomicuser')
          .select('coins,energy,energy_cap,last_daily_grant_at')
          .eq('user_id', uid)
          .maybeSingle();
      if (row != null) _wallet = Wallet.fromMap(row);

      final rows = await _sb
          .from('energy_ledger')
          .select()
          .eq('user_id', uid)
          .order('created_at', ascending: false)
          .limit(200);
      _history = (rows as List)
          .map((e) => EnergyTx.fromMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = _friendly(e);
      debugPrint('EnergyService.refresh failed: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // ---- mutations (server-authoritative) --------------------------------

  /// Convert [coins] Atomic Coins into Energy. Returns null on success, or a
  /// user-facing error string (insufficient coins, cap overflow, ...).
  Future<String?> convertCoins(int coins) async {
    if (_uid == null) return 'You are signed out.';
    try {
      await _sb.rpc('energy_convert', params: {'p_coins': coins});
      await refresh();
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  /// Spend energy directly. Returns null on success, else a message.
  Future<String?> spend(int amount, String reason) async {
    if (_uid == null) return 'You are signed out.';
    try {
      await _sb.rpc('energy_spend',
          params: {'p_amount': amount, 'p_reason': reason});
      await refresh();
      return null;
    } catch (e) {
      return _friendly(e);
    }
  }

  /// Instant sync: always costs [syncInstantCost] (10). Returns null on success,
  /// else a message. On success the caller knows the exact amount charged
  /// ([syncInstantCost]), so it can refund it if the upload later fails.
  Future<String?> spendInstant() => spend(syncInstantCost, 'Instant sync');

  /// Standard (background) sync: costs [syncStandardCost] (5) at most once per
  /// hour — free inside the paid hour (server-enforced window). Returns the
  /// amount actually charged (0 within the free hour, else 5), or null when the
  /// balance can't cover it. The amount lets the caller refund on upload failure.
  Future<int?> spendStandard() async {
    if (_uid == null) return null;
    try {
      final res = await _sb.rpc('energy_spend_standard');
      await refresh();
      if (res is int) return res;
      if (res is num) return res.toInt();
      return 0;
    } catch (e) {
      debugPrint('EnergyService.spendStandard failed: $e');
      return null;
    }
  }

  /// Return energy that was charged for a sync that then failed to upload, so a
  /// dropped network never costs the user energy. Capped, and a no-op for 0.
  Future<void> refund(int amount, String reason) async {
    if (_uid == null || amount <= 0) return;
    try {
      await _sb.rpc('energy_refund',
          params: {'p_amount': amount, 'p_reason': reason});
      await refresh();
    } catch (e) {
      debugPrint('EnergyService.refund failed: $e');
    }
  }

  // ---- errors -----------------------------------------------------------

  /// Map raised Postgres exceptions to plain messages.
  String _friendly(Object e) {
    final s = e.toString();
    if (s.contains('insufficient_coins')) return 'Not enough Atomic Coins.';
    if (s.contains('insufficient_energy')) return 'Not enough Atomic Energy.';
    if (s.contains('energy_cap_exceeded')) {
      return 'That would overflow your Energy cap. Use some first.';
    }
    if (s.contains('invalid_amount')) return 'Enter a valid amount.';
    if (s.contains('SocketException') || s.contains('Failed host')) {
      return 'You appear to be offline.';
    }
    return 'Something went wrong. Please try again.';
  }
}
