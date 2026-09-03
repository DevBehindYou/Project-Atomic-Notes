import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Primary auth action: full-bleed Ink block with a Bebas Neue label and the
/// solid offset shadow. The reference's "GET IN TOUCH" button, essentially.
class LoginButton extends StatefulWidget {
  final VoidCallback signIn;
  final bool isLoading;
  final String ico;
  final String text;
  const LoginButton({
    super.key,
    required this.isLoading,
    required this.signIn,
    required this.ico,
    required this.text,
  });

  @override
  State<LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<LoginButton> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isLoading ? null : widget.signIn,
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
          height: 54,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: AppRadius.std,
            border: Border.all(color: AppColors.ink, width: AppStroke.hairline),
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.paper),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 18,
                      width: 18,
                      child: SvgPicture.asset(
                        widget.ico,
                        colorFilter: const ColorFilter.mode(
                            AppColors.paper, BlendMode.srcIn),
                      ),
                    ),
                    const SizedBox(width: AppSpace.md - 4),
                    Text(
                      widget.text.toUpperCase(),
                      style: AppType.cta.copyWith(color: AppColors.paper),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
