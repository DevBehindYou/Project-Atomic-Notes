import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// A settings row as a minimalist rule-separated line rather than a filled
/// pill — the FAQ-accordion treatment from the reference, with a Signal
/// chevron as the only colour.
class SettingsTiles extends StatelessWidget {
  final VoidCallback action;
  final String text;
  const SettingsTiles({
    required this.action,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    text.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.headlineSm,
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                const Icon(Icons.arrow_forward,
                    size: 16, color: AppColors.signal),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Container(height: AppStroke.rule, color: AppColors.outlineVariant),
          ],
        ),
      ),
    );
  }
}
