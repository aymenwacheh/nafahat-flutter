import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nafahat/services/appearance_config_service.dart';

/// Configuration visuelle globale de la LandingPage.
///
/// Le manager est un singleton ChangeNotifier : dès qu'un administrateur
/// enregistre une nouvelle configuration, les pages qui l'écoutent se
/// reconstruisent immédiatement, sans rechargement navigateur.
class LandingAppearanceConfig {
  String themeMode; // light | dark
  Color pageBackgroundColor;
  Color sectionBackgroundColor;
  Color primaryColor;
  Color accentColor;
  Color titleColor;
  Color textColor;
  Color mutedTextColor;

  String titleFontFamily;
  double titleFontSize;
  FontWeight titleFontWeight;

  double horizontalPadding;
  double sectionSpacing;
  double sectionRadius;
  bool showSectionCards;
  bool showSectionTitles;
  bool enableSectionShadow;
  bool compactMode;

  LandingAppearanceConfig({
    this.themeMode = 'light',
    this.pageBackgroundColor = const Color(0xfffcfbfa),
    this.sectionBackgroundColor = Colors.white,
    this.primaryColor = const Color(0xff0D443E),
    this.accentColor = const Color(0xffd57653),
    this.titleColor = const Color(0xff994a2b),
    this.textColor = const Color(0xff2c221e),
    this.mutedTextColor = const Color(0xff7c6e68),
    this.titleFontFamily = 'Cairo',
    this.titleFontSize = 28,
    this.titleFontWeight = FontWeight.w700,
    this.horizontalPadding = 24,
    this.sectionSpacing = 18,
    this.sectionRadius = 20,
    this.showSectionCards = false,
    this.showSectionTitles = false,
    this.enableSectionShadow = false,
    this.compactMode = false,
  });

  factory LandingAppearanceConfig.defaultConfig() =>
      LandingAppearanceConfig();

  factory LandingAppearanceConfig.fromJson(Map<String, dynamic> json) {
    return LandingAppearanceConfig(
      themeMode: json['themeMode']?.toString() ?? 'light',
      pageBackgroundColor:
          _color(json['pageBackgroundColor'], const Color(0xfffcfbfa)),
      sectionBackgroundColor:
          _color(json['sectionBackgroundColor'], Colors.white),
      primaryColor: _color(json['primaryColor'], const Color(0xff0D443E)),
      accentColor: _color(json['accentColor'], const Color(0xffd57653)),
      titleColor: _color(json['titleColor'], const Color(0xff994a2b)),
      textColor: _color(json['textColor'], const Color(0xff2c221e)),
      mutedTextColor:
          _color(json['mutedTextColor'], const Color(0xff7c6e68)),
      titleFontFamily: json['titleFontFamily']?.toString() ?? 'Cairo',
      titleFontSize: (json['titleFontSize'] as num?)?.toDouble() ?? 28,
      titleFontWeight:
          _fontWeight((json['titleFontWeight'] as num?)?.toInt() ?? 700),
      horizontalPadding:
          (json['horizontalPadding'] as num?)?.toDouble() ?? 24,
      sectionSpacing: (json['sectionSpacing'] as num?)?.toDouble() ?? 18,
      sectionRadius: (json['sectionRadius'] as num?)?.toDouble() ?? 20,
      showSectionCards: json['showSectionCards'] == true,
      showSectionTitles: json['showSectionTitles'] == true,
      enableSectionShadow: json['enableSectionShadow'] == true,
      compactMode: json['compactMode'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'pageBackgroundColor': _hex(pageBackgroundColor),
        'sectionBackgroundColor': _hex(sectionBackgroundColor),
        'primaryColor': _hex(primaryColor),
        'accentColor': _hex(accentColor),
        'titleColor': _hex(titleColor),
        'textColor': _hex(textColor),
        'mutedTextColor': _hex(mutedTextColor),
        'titleFontFamily': titleFontFamily,
        'titleFontSize': titleFontSize,
        'titleFontWeight': titleFontWeight.value,
        'horizontalPadding': horizontalPadding,
        'sectionSpacing': sectionSpacing,
        'sectionRadius': sectionRadius,
        'showSectionCards': showSectionCards,
        'showSectionTitles': showSectionTitles,
        'enableSectionShadow': enableSectionShadow,
        'compactMode': compactMode,
      };

  LandingAppearanceConfig copyWith({
    String? themeMode,
    Color? pageBackgroundColor,
    Color? sectionBackgroundColor,
    Color? primaryColor,
    Color? accentColor,
    Color? titleColor,
    Color? textColor,
    Color? mutedTextColor,
    String? titleFontFamily,
    double? titleFontSize,
    FontWeight? titleFontWeight,
    double? horizontalPadding,
    double? sectionSpacing,
    double? sectionRadius,
    bool? showSectionCards,
    bool? showSectionTitles,
    bool? enableSectionShadow,
    bool? compactMode,
  }) {
    return LandingAppearanceConfig(
      themeMode: themeMode ?? this.themeMode,
      pageBackgroundColor: pageBackgroundColor ?? this.pageBackgroundColor,
      sectionBackgroundColor:
          sectionBackgroundColor ?? this.sectionBackgroundColor,
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      titleColor: titleColor ?? this.titleColor,
      textColor: textColor ?? this.textColor,
      mutedTextColor: mutedTextColor ?? this.mutedTextColor,
      titleFontFamily: titleFontFamily ?? this.titleFontFamily,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      titleFontWeight: titleFontWeight ?? this.titleFontWeight,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      sectionRadius: sectionRadius ?? this.sectionRadius,
      showSectionCards: showSectionCards ?? this.showSectionCards,
      showSectionTitles: showSectionTitles ?? this.showSectionTitles,
      enableSectionShadow: enableSectionShadow ?? this.enableSectionShadow,
      compactMode: compactMode ?? this.compactMode,
    );
  }

  TextStyle titleStyle({double? size}) {
    try {
      return GoogleFonts.getFont(
        titleFontFamily,
        fontSize: size ?? titleFontSize,
        fontWeight: titleFontWeight,
        color: titleColor,
      );
    } catch (_) {
      return GoogleFonts.cairo(
        fontSize: size ?? titleFontSize,
        fontWeight: titleFontWeight,
        color: titleColor,
      );
    }
  }

  static Color _color(dynamic value, Color fallback) {
    if (value == null) return fallback;
    if (value is int) return Color(value);
    var s = value.toString().trim();
    if (s.isEmpty) return fallback;
    s = s.replaceFirst('#', '').replaceFirst('0x', '');
    if (s.length == 6) s = 'FF$s';
    final n = int.tryParse(s, radix: 16);
    return n == null ? fallback : Color(n);
  }

  static String _hex(Color color) =>
      '#${color.value.toRadixString(16).padLeft(8, '0')}';

  static FontWeight _fontWeight(int value) {
    const values = <int, FontWeight>{
      100: FontWeight.w100,
      200: FontWeight.w200,
      300: FontWeight.w300,
      400: FontWeight.w400,
      500: FontWeight.w500,
      600: FontWeight.w600,
      700: FontWeight.w700,
      800: FontWeight.w800,
      900: FontWeight.w900,
    };
    return values[value] ?? FontWeight.w700;
  }
}

class LandingAppearanceManager extends ChangeNotifier {
  LandingAppearanceManager._();
  static final LandingAppearanceManager _instance =
      LandingAppearanceManager._();
  factory LandingAppearanceManager() => _instance;

  static const _storageKey = 'landing_appearance_config_v2';

  LandingAppearanceConfig _config =
      LandingAppearanceConfig.defaultConfig();
  bool _initialized = false;

  LandingAppearanceConfig get config => _config;
  bool get isInitialized => _initialized;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    // Toujours repartir d'une configuration saine. Ensuite on applique le
    // cache local immédiatement, puis le serveur s'il répond.
    _config = LandingAppearanceConfig.defaultConfig();

    try {
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          _config = LandingAppearanceConfig.fromJson(
            Map<String, dynamic>.from(decoded),
          );
        }
      }
    } catch (e) {
      debugPrint('LandingAppearanceManager cache: $e');
    }

    try {
      final remote = await AppearanceConfigService.load('landing');
      if (remote != null && remote.isNotEmpty) {
        _config = LandingAppearanceConfig.fromJson(remote);
        await prefs.setString(_storageKey, jsonEncode(remote));
      }
    } catch (e) {
      debugPrint('LandingAppearanceManager remote: $e');
    } finally {
      _initialized = true;
      notifyListeners();
    }
  }

  Future<bool> save(LandingAppearanceConfig config) async {
    _config = config;
    final prefs = await SharedPreferences.getInstance();
    final jsonMap = config.toJson();

    // Le cache local permet le retour visuel immédiat, même hors-ligne.
    await prefs.setString(_storageKey, jsonEncode(jsonMap));
    final remoteSaved = await AppearanceConfigService.save('landing', jsonMap);
    notifyListeners();
    return remoteSaved;
  }

  /// Utilisé par la page d'administration pour prévisualiser en direct
  /// avant même l'enregistrement.
  void preview(LandingAppearanceConfig config) {
    _config = config;
    notifyListeners();
  }

  Future<void> reset() async {
    _config = LandingAppearanceConfig.defaultConfig();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    await AppearanceConfigService.delete('landing');
    notifyListeners();
  }

  bool get isDark => _config.themeMode == 'dark';
}
