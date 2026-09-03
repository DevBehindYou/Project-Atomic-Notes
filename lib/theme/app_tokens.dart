import 'package:flutter/widgets.dart';

/// Design tokens for the "Technical Editorial" system.
///
/// Ported from New-Design-Inspiration-Files/.../technical_editorial/DESIGN.md.
/// Every colour, type style, radius and spacing step in the app comes from
/// here — no screen should hardcode a hex value or a font size.
///
/// The aesthetic in one line: ink on paper, interrupted only by Signal.
class AppColors {
  AppColors._();

  // ---- Core triad -------------------------------------------------------
  /// Primary driver: all primary type, heavy borders, inverted backgrounds.
  static const Color ink = Color(0xFF15171B);

  /// The canvas. A slightly warm off-white — easier on the eye than pure
  /// white and keeps the "printed page" feel.
  static const Color paper = Color(0xFFF4F5F1);

  /// The digital pulse. Used sparingly: CTAs, active states, critical data.
  static const Color signal = Color(0xFF3A2FF0);

  // ---- Surfaces ---------------------------------------------------------
  static const Color surface = Color(0xFFF9FAF4);
  static const Color surfaceLowest = Color(0xFFFFFFFF);
  static const Color surfaceLow = Color(0xFFF3F4EE);
  static const Color surfaceContainer = Color(0xFFEDEEE8);
  static const Color surfaceHigh = Color(0xFFE8E9E3);
  static const Color surfaceHighest = Color(0xFFE2E3DD);
  static const Color surfaceDim = Color(0xFFD9DBD5);

  // ---- Content ----------------------------------------------------------
  static const Color onSurface = Color(0xFF1A1C19);
  static const Color onSurfaceVariant = Color(0xFF45474B);

  /// Muted metadata text — dates, counts, captions.
  static const Color slateData = Color(0xFF4A4D55);

  /// On an Ink background.
  static const Color onInk = Color(0xFFF0F1EB);

  // ---- Lines ------------------------------------------------------------
  static const Color outline = Color(0xFF76777B);
  static const Color outlineVariant = Color(0xFFC6C6CB);

  // ---- Status -----------------------------------------------------------
  static const Color error = Color(0xFFBA1A1A);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);
}

/// 8px base unit. Use these instead of arbitrary numbers so vertical rhythm
/// stays consistent across screens.
class AppSpace {
  AppSpace._();

  static const double unit = 8;

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Outer page margin on phones.
  static const double screenMargin = 20;

  /// Internal padding for a bento module.
  static const double modulePadding = 20;
}

/// "Technical and crisp": a very slight radius everywhere, so the design reads
/// as engineered rather than hostile. Chips are the one rounded exception.
class AppRadius {
  AppRadius._();

  static const Radius smRadius = Radius.circular(2);
  static const Radius defaultRadius = Radius.circular(4);
  static const Radius mdRadius = Radius.circular(6);
  static const Radius lgRadius = Radius.circular(8);

  static const BorderRadius sm = BorderRadius.all(smRadius);

  /// Bento modules, buttons, inputs.
  static const BorderRadius std = BorderRadius.all(defaultRadius);
  static const BorderRadius md = BorderRadius.all(mdRadius);
  static const BorderRadius lg = BorderRadius.all(lgRadius);

  /// Data chips / status tags only.
  static const BorderRadius chip = BorderRadius.all(Radius.circular(12));

  /// Square — checkboxes, switches-as-blocks.
  static const BorderRadius none = BorderRadius.zero;
}

/// Structural outlines instead of soft shadows. This system has no blurs.
class AppStroke {
  AppStroke._();

  /// Consistent container stroke. Don't mix weights within one view.
  static const double hairline = 1.5;

  /// Thin separator rules between list rows.
  static const double rule = 1;

  /// The "solid offset print" pseudo-shadow on tactile elements.
  static const double offset = 2;
}

/// Font families as registered in pubspec.yaml.
class AppFonts {
  AppFonts._();

  static const String display = 'BebasNeue';
  static const String body = 'HankenGrotesk';
  static const String mono = 'JetBrainsMono';
}

/// The type scale, adapted from the design system's web sizes down to phone
/// sizes. Headlines are uppercase by convention — callers should pass already
/// uppercased strings (or use [AppText.upper]).
class AppType {
  AppType._();

  // ---- Display / headings (Bebas Neue) ----------------------------------
  static const TextStyle displayLg = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 48,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: -0.5,
    color: AppColors.ink,
  );

  static const TextStyle headlineLg = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 36,
    fontWeight: FontWeight.w400,
    height: 1.1,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 26,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );

  static const TextStyle headlineSm = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    height: 1.2,
    letterSpacing: 0.8,
    color: AppColors.ink,
  );

  /// Button / CTA label.
  static const TextStyle cta = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 1.2,
    color: AppColors.ink,
  );

  // ---- Body (Hanken Grotesk) -------------------------------------------
  static const TextStyle bodyLg = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 17,
    fontWeight: FontWeight.w400,
    height: 1.6,
    color: AppColors.onSurface,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.onSurfaceVariant,
  );

  static const TextStyle bodyMedium15 = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.onSurface,
  );

  // ---- Metadata (JetBrains Mono) ---------------------------------------
  /// Small uppercase technical label: dates, tags, counts, section eyebrows.
  static const TextStyle labelMono = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.9,
    color: AppColors.slateData,
  );

  static const TextStyle labelMonoSm = TextStyle(
    fontFamily: AppFonts.mono,
    fontSize: 9.5,
    fontWeight: FontWeight.w500,
    height: 1.4,
    letterSpacing: 0.8,
    color: AppColors.slateData,
  );

  /// Numerals in stat modules.
  static const TextStyle statNumber = TextStyle(
    fontFamily: AppFonts.display,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    height: 1.0,
    letterSpacing: 0.5,
    color: AppColors.ink,
  );
}

/// Small helper so screens read declaratively.
class AppText {
  AppText._();

  /// Headlines are uppercase by default in this system.
  static String upper(String s) => s.toUpperCase();
}
