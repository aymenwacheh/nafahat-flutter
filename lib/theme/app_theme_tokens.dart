import 'package:flutter/material.dart';
import 'package:nafahat/services/landing_appearance_manager.dart';

/// Pont unique entre le thème choisi dans « Apparence Landing » et les
/// anciennes pages qui utilisent encore des couleurs explicites.
class AppThemeTokens {
  AppThemeTokens._();

  static LandingAppearanceConfig get _c => LandingAppearanceManager().config;

  static Color get background => _c.pageBackgroundColor;
  static Color get surface => _c.sectionBackgroundColor;
  static Color get primary => _c.primaryColor;
  static Color get accent => _c.accentColor;
  static Color get title => _c.titleColor;
  static Color get text => _c.textColor;
  static Color get muted => _c.mutedTextColor;
  static bool get isDark => _c.themeMode == 'dark';

  static Color get border => muted.withOpacity(isDark ? .34 : .20);
  static Color get primarySoft => primary.withOpacity(isDark ? .20 : .10);
  static Color get accentSoft => accent.withOpacity(isDark ? .20 : .10);
  static Color get onPrimary =>
      ThemeData.estimateBrightnessForColor(primary) == Brightness.dark
          ? Colors.white
          : Colors.black87;
  static Color get onAccent =>
      ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
          ? Colors.white
          : Colors.black87;
}
