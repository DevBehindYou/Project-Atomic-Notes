// ignore_for_file: use_super_parameters

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:flutter/material.dart';

/// Confirmation for logout and cloud-fetch. Same frame as [DialogBox] but with
/// a neutral eyebrow — these are deliberate, not destructive-by-accident.
class DialogBoxLogout extends StatelessWidget {
  final Function action;
  final String text;

  const DialogBoxLogout({
    required this.action,
    required this.text,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.std,
        side: BorderSide(color: AppColors.ink, width: AppStroke.hairline),
      ),
      insetPadding: const EdgeInsets.all(AppSpace.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpace.lg),
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MonoLabel('CONFIRM'),
            const SizedBox(height: AppSpace.sm),
            const HairRule(color: AppColors.ink),
            const SizedBox(height: AppSpace.md),
            Flexible(
              child: SingleChildScrollView(
                child: Text(text, style: AppType.bodyMd),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: GhostButton(
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: AppSpace.sm + 2),
                Expanded(
                  child: InkActionButton(
                    label: 'Confirm',
                    onTap: () async {
                      await action();
                      // Signing out pushes a replacement route, which swaps
                      // out this dialog's own route — popping unguarded then
                      // removed the page that replaced it.
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
