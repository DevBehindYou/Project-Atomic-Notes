// Data models for Atomic Energy + Atomic Coins.
//
// Plain value types with no Supabase/Flutter coupling, mirroring how
// `Note`/`TodoItem` stay separate from the repository. All balance mutation
// lives server-side (see supabase/migrations/006_energy.sql); these just carry
// what the client reads back.

/// One kind of ledger entry. String values match the `kind` column check
/// constraint in Postgres.
enum EnergyTxKind {
  dailyGrant,
  convert,
  spend,
  purchase,
  adminAdjust,
  unknown;

  static EnergyTxKind fromRaw(String? raw) {
    switch (raw) {
      case 'daily_grant':
        return EnergyTxKind.dailyGrant;
      case 'convert':
        return EnergyTxKind.convert;
      case 'spend':
        return EnergyTxKind.spend;
      case 'purchase':
        return EnergyTxKind.purchase;
      case 'admin_adjust':
        return EnergyTxKind.adminAdjust;
      default:
        return EnergyTxKind.unknown;
    }
  }

  /// Human label for the history row.
  String get label {
    switch (this) {
      case EnergyTxKind.dailyGrant:
        return 'Daily energy';
      case EnergyTxKind.convert:
        return 'Coins converted';
      case EnergyTxKind.spend:
        return 'Energy used';
      case EnergyTxKind.purchase:
        return 'Coins purchased';
      case EnergyTxKind.adminAdjust:
        return 'Adjustment';
      case EnergyTxKind.unknown:
        return 'Transaction';
    }
  }
}

/// A single balance-changing event, read from `energy_ledger`.
class EnergyTx {
  final String id;
  final EnergyTxKind kind;
  final int coinsDelta;
  final int energyDelta;
  final int resultingCoins;
  final int resultingEnergy;
  final String? note;
  final DateTime createdAt;

  const EnergyTx({
    required this.id,
    required this.kind,
    required this.coinsDelta,
    required this.energyDelta,
    required this.resultingCoins,
    required this.resultingEnergy,
    required this.note,
    required this.createdAt,
  });

  factory EnergyTx.fromMap(Map<String, dynamic> m) {
    int asInt(dynamic v) => v is int ? v : int.tryParse('${v ?? 0}') ?? 0;
    return EnergyTx(
      id: '${m['id']}',
      kind: EnergyTxKind.fromRaw(m['kind'] as String?),
      coinsDelta: asInt(m['coins_delta']),
      energyDelta: asInt(m['energy_delta']),
      resultingCoins: asInt(m['resulting_coins']),
      resultingEnergy: asInt(m['resulting_energy']),
      note: m['note'] as String?,
      createdAt:
          DateTime.tryParse('${m['created_at']}')?.toLocal() ?? DateTime.now(),
    );
  }
}

/// The current balances, read from the `atomicuser` row.
class Wallet {
  final int coins;
  final int energy;
  final int energyCap;
  final DateTime? lastDailyGrantAt;

  const Wallet({
    required this.coins,
    required this.energy,
    required this.energyCap,
    required this.lastDailyGrantAt,
  });

  /// Empty wallet used before the first load / for a fresh account.
  static const Wallet empty =
      Wallet(coins: 0, energy: 0, energyCap: 120, lastDailyGrantAt: null);

  /// 0..1 fill for the energy bar.
  double get energyFraction =>
      energyCap <= 0 ? 0 : (energy / energyCap).clamp(0.0, 1.0);

  factory Wallet.fromMap(Map<String, dynamic> m) {
    int asInt(dynamic v, [int fallback = 0]) =>
        v is int ? v : int.tryParse('${v ?? fallback}') ?? fallback;
    return Wallet(
      coins: asInt(m['coins']),
      energy: asInt(m['energy']),
      energyCap: asInt(m['energy_cap'], 120),
      lastDailyGrantAt: m['last_daily_grant_at'] == null
          ? null
          : DateTime.tryParse('${m['last_daily_grant_at']}')?.toLocal(),
    );
  }
}
