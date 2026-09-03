import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// System messages, styled as an inverted Ink strip with a Signal edge —
/// the design system's "system status" voice rather than a coloured toast.
class MySnackBar extends StatelessWidget {
  final String text;
  final int sec;

  const MySnackBar({
    required this.sec,
    required this.text,
    super.key,
  });

  void showMySnackBar(BuildContext context) {
    final messenger = ScaffoldMessenger.of(context);
    // Don't let messages pile up into a queue the user has to sit through.
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        // Sized to its content: an earlier fixed 100px height clipped the
        // 105px it actually asked for.
        content: Container(
          margin: const EdgeInsets.only(bottom: 48),
          decoration: const BoxDecoration(
            color: AppColors.ink,
            borderRadius: AppRadius.std,
          ),
          child: Row(
            children: [
              // Signal edge marker.
              Container(
                width: 3,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.signal,
                  borderRadius: BorderRadius.only(
                    topLeft: AppRadius.defaultRadius,
                    bottomLeft: AppRadius.defaultRadius,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 12, horizontal: AppSpace.md),
                  child: Text(
                    text,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.bodySm.copyWith(color: AppColors.onInk),
                  ),
                ),
              ),
            ],
          ),
        ),
        behavior: SnackBarBehavior.floating,
        duration: Duration(milliseconds: sec),
        backgroundColor: Colors.transparent,
        elevation: 0,
        padding: EdgeInsets.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This type is only ever constructed and then shown via showMySnackBar;
    // it is never mounted. Kept as a widget so the ~30 existing call sites
    // don't have to change.
    return const SizedBox.shrink();
  }
}
