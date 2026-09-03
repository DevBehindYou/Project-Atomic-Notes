// Regression tests for the Atomic Energy / Coins and Notification client logic
// that can be exercised without Supabase or Hive. The balance mutations
// themselves are server-authoritative (Postgres RPCs) and are verified against
// the live/test project, not here.

import 'package:atomic_notes/database/energy_models.dart';
import 'package:atomic_notes/database/notification_models.dart';
import 'package:atomic_notes/utility/component/energy_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnergyBar.colorFor thresholds', () {
    // <10 -> magenta, 10..79 -> Signal, >=80 -> amber.
    test('below 10 is the low/warning colour', () {
      expect(EnergyBar.colorFor(0), EnergyBar.low);
      expect(EnergyBar.colorFor(9), EnergyBar.low);
    });
    test('10 to 79 is the Signal colour', () {
      expect(EnergyBar.colorFor(10), const Color(0xFF3A2FF0));
      expect(EnergyBar.colorFor(79), const Color(0xFF3A2FF0));
    });
    test('80 and above is the high colour', () {
      expect(EnergyBar.colorFor(80), EnergyBar.high);
      expect(EnergyBar.colorFor(120), EnergyBar.high);
    });
  });

  group('Wallet', () {
    test('empty wallet has the 120 cap and zero balances', () {
      expect(Wallet.empty.energyCap, 120);
      expect(Wallet.empty.energy, 0);
      expect(Wallet.empty.coins, 0);
    });
    test('energyFraction is clamped 0..1', () {
      const full = Wallet(coins: 0, energy: 120, energyCap: 120, lastDailyGrantAt: null);
      const over = Wallet(coins: 0, energy: 999, energyCap: 120, lastDailyGrantAt: null);
      const half = Wallet(coins: 0, energy: 60, energyCap: 120, lastDailyGrantAt: null);
      expect(full.energyFraction, 1.0);
      expect(over.energyFraction, 1.0);
      expect(half.energyFraction, closeTo(0.5, 1e-9));
    });
    test('fromMap tolerates string numbers and missing cap', () {
      final w = Wallet.fromMap({'coins': '5', 'energy': 40});
      expect(w.coins, 5);
      expect(w.energy, 40);
      expect(w.energyCap, 120); // default when absent
    });
  });

  group('EnergyTxKind', () {
    test('maps raw strings, unknowns fall back', () {
      expect(EnergyTxKind.fromRaw('daily_grant'), EnergyTxKind.dailyGrant);
      expect(EnergyTxKind.fromRaw('convert'), EnergyTxKind.convert);
      expect(EnergyTxKind.fromRaw('spend'), EnergyTxKind.spend);
      expect(EnergyTxKind.fromRaw('admin_adjust'), EnergyTxKind.adminAdjust);
      expect(EnergyTxKind.fromRaw('something_new'), EnergyTxKind.unknown);
      expect(EnergyTxKind.fromRaw(null), EnergyTxKind.unknown);
    });
    test('every kind has a non-empty label', () {
      for (final k in EnergyTxKind.values) {
        expect(k.label.isNotEmpty, isTrue);
      }
    });
  });

  group('AppNotification.fromMap', () {
    test('parses a full row and detects a valid CTA', () {
      final n = AppNotification.fromMap({
        'id': 'notif_1',
        'type': 'server_down',
        'subject': 'Sync down',
        'description': 'Cloud sync is briefly unavailable.',
        'priority': 'critical',
        'status': 'active',
        'action': 'View Status',
        'action_url': '/status',
        'icon': 'server',
        'created_at': '2026-08-23T18:15:00Z',
        'is_read': false,
      });
      expect(n.id, 'notif_1');
      expect(n.isCritical, isTrue);
      expect(n.hasAction, isTrue);
      expect(n.isRead, isFalse);
      expect(n.expiresAt, isNull);
    });
    test('a missing/empty CTA is not treated as actionable', () {
      final n = AppNotification.fromMap({
        'id': 'notif_2',
        'type': 'general',
        'subject': 'Hello',
        'description': 'No action here.',
        'priority': 'normal',
        'status': 'active',
        'created_at': '2026-08-23T18:15:00Z',
        'is_read': true,
      });
      expect(n.hasAction, isFalse);
      expect(n.isRead, isTrue);
      expect(n.isCritical, isFalse);
    });
  });
}
