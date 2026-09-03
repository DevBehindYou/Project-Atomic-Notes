/// App metadata shown in the UI.
///
/// Keep [version] and [buildNumber] in step with `version:` in pubspec.yaml.
/// They were previously hardcoded separately in settings_page.dart and
/// about_us_page.dart, and both had drifted (the UI said 1.11.1 while the
/// pubspec said 1.12.1).
class AppInfoText {
  AppInfoText._();

  static const String version = "1.12.1";
  static const String buildNumber = "3";
  static const String copyright = "© 2026 Atomic Notes";

  static String get versionLabel => "Version: $version ($buildNumber)";
}
