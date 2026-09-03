import 'package:atomic_notes/theme/app_tokens.dart';
import 'package:atomic_notes/theme/editorial.dart';
import 'package:flutter/material.dart';

/// Underline-only input, per the design system. The focus state is a bold 2px
/// Signal underline; the leading label is a mono eyebrow rather than a
/// floating hint, which keeps the field readable while typing.
class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Icon ico;

  /// Masks the input. Password fields were previously rendered in plain text
  /// on screen because this widget had no way to obscure them at all.
  final bool obscureText;

  /// Defaults to plain text; pass [TextInputType.emailAddress] for email
  /// fields so the keyboard offers "@" and ".".
  final TextInputType? keyboardType;

  const MyTextField({
    required this.ico,
    required this.hintText,
    required this.controller,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.screenMargin, vertical: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          MonoLabel(hintText, small: true),
          TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            // Never let the keyboard learn or suggest a password.
            autocorrect: !obscureText,
            enableSuggestions: !obscureText,
            cursorColor: AppColors.signal,
            style: AppType.bodyLg,
            decoration: InputDecoration(
              isDense: true,
              filled: false,
              suffixIcon: IconTheme(
                data: const IconThemeData(
                    color: AppColors.slateData, size: 18),
                child: ico,
              ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
              contentPadding: const EdgeInsets.only(top: 10, bottom: 10),
              enabledBorder: const UnderlineInputBorder(
                borderSide:
                    BorderSide(color: AppColors.ink, width: AppStroke.rule),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                    color: AppColors.signal, width: AppStroke.offset),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
