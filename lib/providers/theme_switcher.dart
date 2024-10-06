import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/models/theme.dart';
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
    if (prefs.containsKey('global_theme')) {
      final value = SolianThemeData.fromJson(
        jsonDecode(prefs.getString('global_theme')!),
      );
      final agedTheme = prefs.getBool('aged_theme');
      lightThemeData = AppTheme.buildFromData(
        Brightness.light,
        value,
        useMaterial3: agedTheme == null ? true : !agedTheme,
      );
      darkThemeData = AppTheme.buildFromData(
        Brightness.dark,
        value,
        useMaterial3: agedTheme == null ? true : !agedTheme,
      );
      notifyListeners();
    }
  }

  void setTheme(ThemeData light, dark) {
    lightThemeData = light;
    darkThemeData = dark;
    notifyListeners();
  }

  Future<void> setThemeData(SolianThemeData? data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data == null) {
      prefs.remove('global_theme');
    } else {
      prefs.setString(
        'global_theme',
        jsonEncode(data.toJson()),
      );
      lightThemeData = AppTheme.buildFromData(Brightness.light, data);
      darkThemeData = AppTheme.buildFromData(Brightness.dark, data);
      notifyListeners();
    }
  }

  Future<void> setAgedTheme(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('aged_theme', enabled);
    await restoreTheme();
  }
}
