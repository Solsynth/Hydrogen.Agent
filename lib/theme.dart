import 'package:flutter/material.dart';
import 'package:solian/models/theme.dart';
import 'package:solian/platform.dart';

abstract class AppTheme {
  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 640;

  static bool isExtraLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 920;

  static bool isUltraLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 1200;

  static bool isSpecializedMacOS(BuildContext context) =>
      PlatformInfo.isMacOS && !AppTheme.isLargeScreen(context);

  static double? titleSpacing(BuildContext context) {
    if (AppTheme.isSpecializedMacOS(context)) {
      return 24;
    } else {
      return AppTheme.isLargeScreen(context) ? null : 24;
    }
  }

  static double toolbarHeight(BuildContext context) {
    if (isLargeScreen(context)) {
      return kToolbarHeight;
    } else {
      return PlatformInfo.isMacOS ? 50 : kToolbarHeight;
    }
  }

  static ThemeData build(Brightness brightness, {Color? seedColor}) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: seedColor ?? const Color.fromRGBO(154, 98, 91, 1),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
      ),
      fontFamily: 'Comfortaa',
      fontFamilyFallback: [
        'NotoSansSC',
        'NotoSansHK',
        'NotoSansJP',
        if (PlatformInfo.isWeb) 'NotoSansEmoji',
      ],
      typography: Typography.material2021(
        colorScheme: brightness == Brightness.light
            ? const ColorScheme.light()
            : const ColorScheme.dark(),
      ),
    );
  }

  static ThemeData buildFromData(
    Brightness brightness,
    SolianThemeData data, {
    bool useMaterial3 = true,
  }) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: useMaterial3,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: data.seedColor,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent),
      fontFamily: data.fontFamily ?? 'Comfortaa',
      fontFamilyFallback: data.fontFamilyFallback ??
          [
            'NotoSansSC',
            'NotoSansHK',
            'NotoSansJP',
            if (PlatformInfo.isWeb) 'NotoSansEmoji',
          ],
      typography: Typography.material2021(
        colorScheme: brightness == Brightness.light
            ? const ColorScheme.light()
            : const ColorScheme.dark(),
      ),
    );
  }
}
