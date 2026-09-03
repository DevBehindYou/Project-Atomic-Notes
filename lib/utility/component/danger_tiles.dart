import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:atomic_notes/utility/component/dialog_box.dart';
import 'package:flutter/material.dart';

/// Destructive action row. Reads as a technical console entry: mono label,
/// then a bordered EXECUTE block in error red.
class DangerTile extends StatelessWidget {
  final Function func;
  final String txt;
  final String text;
  const DangerTile({
    required this.func,
    required this.txt,
    required this.text,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    showPopUp({required String txt, required Function func}) {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (_) {
          return DialogBox(
            action: func,
            text: txt,
          );
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpace.md - 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: AppRadius.std,
        border: Border.all(color: AppColors.outlineVariant, width: AppStroke.rule),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text.toUpperCase(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppType.labelMono.copyWith(color: AppColors.ink),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          GestureDetector(
            onTap: () => showPopUp(txt: txt, func: func),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.md - 2, vertical: AppSpace.sm),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: AppRadius.std,
                border: Border.all(
                    color: AppColors.error, width: AppStroke.rule),
              ),
              child: const MonoLabel('EXECUTE', color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
