import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Sync action in the app bar. Signal-filled, because syncing is the single
/// most important action on the notes screen and Signal is reserved for
/// exactly that.
///
/// [clr] stays in the API so call sites compile unchanged; the fill now comes
/// from the design system instead.
class CloudButton extends StatefulWidget {
  final VoidCallback action;
  final String ico;
  final int clr;
  final bool isLoading;
  const CloudButton({
    required this.ico,
    required this.action,
    required this.clr,
    required this.isLoading,
    super.key,
  });

  @override
  State<CloudButton> createState() => _CloudButtonState();
}

class _CloudButtonState extends State<CloudButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.action,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 38,
        width: 46,
        padding: const EdgeInsets.all(AppSpace.sm),
        decoration: BoxDecoration(
          color: widget.isLoading ? AppColors.surfaceHigh : AppColors.signal,
          borderRadius: AppRadius.std,
          border: Border.all(color: AppColors.ink, width: AppStroke.rule),
        ),
        child: widget.isLoading
            ? const Center(
                child: SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.signal,
                  ),
                ),
              )
            : SvgPicture.asset(
                widget.ico,
                colorFilter:
                    const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              ),
      ),
    );
  }
}
