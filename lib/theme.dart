import 'package:flutter/material.dart';
import 'package:solian/platform.dart';

abstract class SolianTheme {
  static bool isLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 640;

  static bool isExtraLargeScreen(BuildContext context) =>
      MediaQuery.of(context).size.width > 720;

  static bool isSpecializedMacOS(BuildContext context) =>
      PlatformInfo.isMacOS && !SolianTheme.isLargeScreen(context);

  static double? titleSpacing(BuildContext context) {
    if (SolianTheme.isSpecializedMacOS(context)) {
      return 24;
    } else {
      return SolianTheme.isLargeScreen(context) ? null : 24;
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
}
