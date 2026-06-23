import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recipe_creator_ai/theme/app_themes.dart';

class ThemeController extends ChangeNotifier {
  ThemeController({String? initialThemeId})
      : _themeId = initialThemeId ?? kDefaultThemeId;

  static const _prefsKey = 'app_theme_id';
  // Legacy key from the old light/dark/system selector. Migrated on load.
  static const _legacyKey = 'theme_mode';

  String _themeId;
  String get themeId => _themeId;

  /// The fully resolved theme currently in effect.
  AppThemeOption get current => themeById(_themeId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    var stored = prefs.getString(_prefsKey);

    // One-time migration from the previous theme_mode preference.
    if (stored == null) {
      final legacy = prefs.getString(_legacyKey);
      if (legacy == 'dark') {
        stored = 'dark';
      } else if (legacy == 'light') {
        stored = 'light';
      }
      if (stored != null) {
        await prefs.setString(_prefsKey, stored);
        await prefs.remove(_legacyKey);
      }
    }

    if (stored != null &&
        stored != _themeId &&
        kAppThemes.any((t) => t.id == stored)) {
      _themeId = stored;
      notifyListeners();
    }
  }

  Future<void> setTheme(String id) async {
    if (id == _themeId || !kAppThemes.any((t) => t.id == id)) return;
    _themeId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, id);
  }
}
