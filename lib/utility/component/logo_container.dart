import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:flutter/material.dart';

/// Wordmark lockup. The atom PNG is light-on-dark, so it sits inside an Ink
/// block — the reference treats logos the same way, and it keeps the mark
/// legible on the Paper canvas without redrawing the asset.
class LogoContainer extends StatelessWidget {
  final bool showTagline;
  const LogoContainer({super.key, this.showTagline = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const InkLogoMark(size: 46),
            const SizedBox(width: AppSpace.md),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ATOMIC',
                    style: AppType.headlineLg.copyWith(height: 0.95)),
                Text('NOTES',
                    style: AppType.headlineSm.copyWith(
                      color: AppColors.slateData,
                      height: 1.0,
                    )),
              ],
            ),
          ],
        ),
        if (showTagline) ...[
          const SizedBox(height: AppSpace.md),
          const SizedBox(
            width: 250,
            child: Column(
              children: [
                HairRule(color: AppColors.ink),
                SizedBox(height: AppSpace.sm),
                MonoLabel(
                  'LOCAL-FIRST · SYNCED · YOURS',
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
