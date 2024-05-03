import 'package:flutter/material.dart';

abstract class SolianTheme {
  static bool isColumnMode(BuildContext context) =>
      MediaQuery.of(context).size.width > 640;

  static ThemeData build(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(brightness: brightness, seedColor: Colors.indigo),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}