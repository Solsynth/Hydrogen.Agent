import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/theme.dart';

class ThemeSwitcher extends ChangeNotifier {
  ThemeData lightThemeData;
  ThemeData darkThemeData;

  ThemeSwitcher({
    required this.lightThemeData,
    required this.darkThemeData,
  });

  Future<void> restoreTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('global_theme_color')) {
      final value = prefs.getInt('global_theme_color')!;
      final color = Color(value);
      lightThemeData = SolianTheme.build(Brightness.light, seedColor: color);
      darkThemeData = SolianTheme.build(Brightness.dark, seedColor: color);
      notifyListeners();
    }
  }

  void setTheme(ThemeData light, dark) {
    lightThemeData = light;
    darkThemeData = dark;
    notifyListeners();
  }
}
