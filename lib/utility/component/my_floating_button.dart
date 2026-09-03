import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Square-ish icon action with the system's solid offset "print" shadow.
///
/// [colorValue] is kept in the API so existing call sites compile unchanged,
/// but it is now read as *intent* rather than as a literal colour: the old
/// red values map to the error token, everything else to Ink. That keeps the
/// palette inside the design system no matter what a caller passes.
class MyFloatingButton extends StatelessWidget {
  final VoidCallback action;
  final String ico;
  final int colorValue;
  const MyFloatingButton({
    required this.colorValue,
    required this.ico,
    required this.action,
    super.key,
  });

  static bool isDestructive(int value) =>
      value == 0xffa60000 || value == 0xffff2b00;

  @override
  Widget build(BuildContext context) {
    final bool danger = isDestructive(colorValue);
    final Color fill = danger ? AppColors.error : AppColors.ink;

    return GestureDetector(
      onTap: action,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: AppRadius.std,
          boxShadow: [
            BoxShadow(
              color: AppColors.ink,
              offset: Offset(AppStroke.offset, AppStroke.offset),
              blurRadius: 0,
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: AppRadius.std,
            border: Border.all(color: AppColors.ink, width: AppStroke.hairline),
          ),
          child: SizedBox(
            height: 20,
            width: 22,
            child: SvgPicture.asset(
              ico,
              colorFilter:
                  const ColorFilter.mode(AppColors.paper, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
