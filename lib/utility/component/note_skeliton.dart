import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

/// Loading placeholder. Mirrors the real note card's structure — hairline
/// border, metadata bar, title bar, body lines — so nothing shifts when the
/// data arrives.
class Skeliton extends StatelessWidget {
  const Skeliton({super.key});

  // Kept in sync with home_page.dart's _responsiveColumnCount so the
  // loading skeleton doesn't visibly reflow into a different column
  // count once real data loads.
  int _responsiveColumnCount(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1100) return 5;
    if (width >= 800) return 4;
    if (width >= 550) return 3;
    return 2;
  }

  Widget _bar({required double widthFactor, double height = 10}) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: height,
        decoration: const BoxDecoration(
          color: AppColors.surfaceHighest,
          borderRadius: AppRadius.sm,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MasonryGridView.count(
      padding: const EdgeInsets.fromLTRB(
          AppSpace.md, AppSpace.sm, AppSpace.md, 100),
      crossAxisCount: _responsiveColumnCount(context),
      mainAxisSpacing: AppSpace.sm,
      crossAxisSpacing: AppSpace.sm,
      itemCount: 6,
      itemBuilder: (context, index) {
        // Vary the body length a little so the grid looks like real content.
        final int lines = 2 + (index % 3);
        return Container(
          margin: const EdgeInsets.only(bottom: AppSpace.xs),
          padding: const EdgeInsets.all(AppSpace.md - 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
            borderRadius: AppRadius.std,
            border: Border.all(
                color: AppColors.outlineVariant, width: AppStroke.rule),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _bar(widthFactor: 0.55, height: 8),
              const SizedBox(height: AppSpace.sm),
              Container(
                  height: AppStroke.rule, color: AppColors.outlineVariant),
              const SizedBox(height: AppSpace.sm),
              _bar(widthFactor: 0.85, height: 14),
              const SizedBox(height: AppSpace.sm),
              for (int i = 0; i < lines; i++) ...[
                _bar(widthFactor: i == lines - 1 ? 0.5 : 0.95, height: 8),
                const SizedBox(height: 6),
              ],
            ],
          ),
        );
      },
    );
  }
}
