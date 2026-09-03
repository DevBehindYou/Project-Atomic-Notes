import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// A Technical-Editorial progress bar for Atomic Energy: a thin ink-bordered
/// track with a solid fill and a zero-blur feel — no Material rounded
/// `LinearProgressIndicator`, which would look foreign here.
///
/// [fraction] is clamped to 0..1. [color] defaults to Signal; use
/// [EnergyBar.colorFor] to tint by the raw energy level. Animates on change.
class EnergyBar extends StatelessWidget {
  final double fraction;
  final double height;
  final Color? color;

  const EnergyBar({
    required this.fraction,
    this.height = 10,
    this.color,
    super.key,
  });

  /// Fill colour by energy level: below 10 a warning magenta, the normal
  /// Signal band up to 80, then amber as the bar approaches full (120 cap).
  static const Color low = Color(0xFF601D49);
  static const Color high = Color(0xFFEB7D00);

  static Color colorFor(int energy) {
    if (energy < 10) return low;
    if (energy >= 80) return high;
    return AppColors.signal;
  }

  @override
  Widget build(BuildContext context) {
    final f = fraction.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: AppRadius.sm,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.ink, width: AppStroke.rule),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, c) => AnimatedContainer(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              width: c.maxWidth * f,
              decoration: BoxDecoration(color: color ?? AppColors.signal),
            ),
          ),
        ),
      ),
    );
  }
}
