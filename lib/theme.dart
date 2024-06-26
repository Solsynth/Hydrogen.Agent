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

  static ThemeData build(Brightness brightness) {
    return ThemeData(
      brightness: brightness,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
          brightness: brightness, seedColor: Colors.indigo),
    );
  }
}
