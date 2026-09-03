import 'package:atomic_notes/database/energy_service.dart';
import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/atomic_icon.dart';
import 'package:atomic_notes/utility/component/energy_bar.dart';
import 'package:flutter/material.dart';

/// Compact Atomic Energy / Coins popup shown on a long-press of the Sync
/// button. Anchored near the top-right (where the button lives), scales in from
/// that corner, dismisses on outside tap, and never overflows the screen.
///
/// Tapping a row opens the full Atomic Energy page.
Future<void> showEnergyPopup(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Dismiss',
    // ignore: deprecated_member_use
    barrierColor: Colors.black.withOpacity(0.10),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (ctx, a1, a2) => const _EnergyPopup(),
    transitionBuilder: (ctx, anim, sec, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          alignment: Alignment.topRight,
          child: child,
        ),
      );
    },
  );
}

class _EnergyPopup extends StatefulWidget {
  const _EnergyPopup();

  @override
  State<_EnergyPopup> createState() => _EnergyPopupState();
}

class _EnergyPopupState extends State<_EnergyPopup> {
  final EnergyService energy = EnergyService.instance;

  @override
  void initState() {
    super.initState();
    // Freshen quietly when opened; the popup renders cached values immediately.
    energy.refresh();
  }

  void _openPage() {
    Navigator.of(context).pop(); // close popup first
    Navigator.of(context).pushNamed('/energypage');
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width =
        (media.size.width - AppSpace.md * 2).clamp(0.0, 300.0).toDouble();

    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          // Sit just under the app bar, aligned to the right margin near the
          // Sync button. kToolbarHeight covers the app bar; +8 for breathing room.
          padding: const EdgeInsets.only(
              top: kToolbarHeight + AppSpace.sm, right: AppSpace.md),
          child: SizedBox(
            width: width,
            child: AnimatedBuilder(
              animation: energy,
              builder: (context, _) => EditorialModule(
                fill: AppColors.paper,
                padding: const EdgeInsets.all(AppSpace.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Row 1 — Atomic Energy
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openPage,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AtomicIcon.energy(size: 22),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const MonoLabel('ATOMIC ENERGY', small: true),
                                const SizedBox(height: AppSpace.xs),
                                EnergyBar(
                                  fraction: energy.wallet.energyFraction,
                                  color: EnergyBar.colorFor(energy.energy),
                                ),
                                const SizedBox(height: AppSpace.xs),
                                Text(
                                  '${energy.energy} / ${energy.energyCap}',
                                  style: AppType.labelMonoSm,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    const HairRule(),
                    const SizedBox(height: AppSpace.sm),
                    // Row 2 — Atomic Coins
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _openPage,
                      child: Row(
                        children: [
                          const AtomicIcon.coin(size: 22),
                          const SizedBox(width: AppSpace.sm),
                          const Expanded(
                            child: MonoLabel('ATOMIC COINS', small: true),
                          ),
                          Text(
                            '${energy.coins}',
                            style: AppType.headlineSm,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ArrowLink('Open energy', onTap: _openPage),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
