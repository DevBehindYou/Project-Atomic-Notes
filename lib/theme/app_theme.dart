import 'package:flutter/material.dart';
import 'package:atomic_notes/theme/app_tokens.dart';

/// Assembles the tokens in [AppColors]/[AppType] into a single ThemeData, so
/// widgets that aren't explicitly styled (dialogs, text selection, the default
/// TextField, scrollbars) still land inside the design system instead of
/// falling back to stock Material blue-on-white.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    const scheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.ink,
      onPrimary: AppColors.paper,
      primaryContainer: AppColors.ink,
      onPrimaryContainer: AppColors.paper,
      secondary: AppColors.signal,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.surfaceHighest,
      onSecondaryContainer: AppColors.onSurface,
      tertiary: AppColors.signal,
      onTertiary: Colors.white,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.paper,
      onSurface: AppColors.onSurface,
      surfaceContainerLowest: AppColors.surfaceLowest,
      surfaceContainerLow: AppColors.surfaceLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceHigh,
      surfaceContainerHighest: AppColors.surfaceHighest,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      inverseSurface: AppColors.ink,
      onInverseSurface: AppColors.onInk,
      inversePrimary: AppColors.paper,
      shadow: Colors.black,
      scrim: Colors.black,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.paper,
      canvasColor: AppColors.paper,
      fontFamily: AppFonts.body,
      splashFactory: InkRipple.splashFactory,

      textTheme: const TextTheme(
        displayLarge: AppType.displayLg,
        displayMedium: AppType.headlineLg,
        headlineLarge: AppType.headlineLg,
        headlineMedium: AppType.headlineMd,
        headlineSmall: AppType.headlineSm,
        titleLarge: AppType.headlineSm,
        titleMedium: AppType.bodyMedium15,
        bodyLarge: AppType.bodyLg,
        bodyMedium: AppType.bodyMd,
        bodySmall: AppType.bodySm,
        labelLarge: AppType.cta,
        labelMedium: AppType.labelMono,
        labelSmall: AppType.labelMonoSm,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.paper,
        foregroundColor: AppColors.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.headlineMd,
      ),

      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.paper,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.std,
          side: BorderSide(color: AppColors.ink, width: AppStroke.hairline),
        ),
      ),

      // Flat by design: depth comes from tonal layering and outlines, never
      // from blur.
      cardTheme: const CardThemeData(
        color: AppColors.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.std,
          side: BorderSide(color: AppColors.outlineVariant, width: AppStroke.rule),
        ),
      ),

      dividerTheme: const DividerThemeData(
        color: AppColors.outlineVariant,
        thickness: AppStroke.rule,
        space: AppSpace.md,
      ),

      // Underline-only inputs; focus is a bold Signal underline.
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        hintStyle: AppType.bodyMd.copyWith(color: AppColors.outline),
        labelStyle: AppType.labelMono,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.outline, width: AppStroke.rule),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.signal, width: AppStroke.offset),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: AppStroke.rule),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.error, width: AppStroke.offset),
        ),
      ),

      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.signal,
        selectionColor: Color(0x333A2FF0),
        selectionHandleColor: AppColors.signal,
      ),

      // Primary button: Ink fill, Paper label, Bebas Neue, square-ish.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.paper,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.md),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.std),
          textStyle: AppType.cta.copyWith(color: AppColors.paper),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.signal,
          textStyle: AppType.labelMono.copyWith(color: AppColors.signal),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.std),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: AppStroke.hairline),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg, vertical: AppSpace.md),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.std),
          textStyle: AppType.cta,
        ),
      ),

      snackBarTheme: const SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 14,
          color: AppColors.onInk,
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.std),
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.signal,
        linearTrackColor: AppColors.surfaceHighest,
        circularTrackColor: AppColors.surfaceHighest,
      ),

      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.outline),
        radius: AppRadius.smRadius,
        thickness: WidgetStateProperty.all(4),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.paper
              : AppColors.surfaceLowest,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppColors.signal
              : AppColors.surfaceDim,
        ),
        trackOutlineColor: WidgetStateProperty.all(AppColors.outline),
      ),

      iconTheme: const IconThemeData(color: AppColors.ink, size: 20),
    );
  }
}
