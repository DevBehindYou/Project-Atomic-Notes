// ignore_for_file: use_super_parameters

import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:flutter/material.dart';

/// Confirmation dialog for destructive dev-tool actions. Framed like a system
/// prompt: mono eyebrow, rule, message, then a ghost/Ink button pair.
///
/// No fixed height — the messages passed in run to ~140 characters and used to
/// overflow a hardcoded 180x200 box.
class DialogBox extends StatelessWidget {
  final Function action;
  final String text;

  const DialogBox({
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
            const MonoLabel('CONFIRM ACTION', color: AppColors.error),
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
                    label: 'Execute',
                    danger: true,
                    onTap: () async {
                      await action();
                      // The action may itself have navigated (a sign-out
                      // pushes a replacement, which swaps out this dialog's
                      // own route). Popping blindly then removed whatever
                      // had taken its place.
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
