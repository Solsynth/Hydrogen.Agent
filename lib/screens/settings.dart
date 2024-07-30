import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/exts.dart';
import 'package:solian/theme.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  late final SharedPreferences _prefs;

  Widget _buildCaptionHeader(String title) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: Theme.of(context).colorScheme.surfaceContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Text(title),
    );
  }

  Widget _buildThemeColorButton(String label, Color color) {
    return IconButton(
      icon: Icon(Icons.circle, color: color),
      tooltip: label,
      onPressed: () {
        currentLightTheme =
            SolianTheme.build(Brightness.light, seedColor: color);
        currentDarkTheme = SolianTheme.build(Brightness.dark, seedColor: color);
        _prefs.setInt('global_theme_color', color.value);
        context.showSnackbar('themeColorApplied'.tr);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((inst) {
      _prefs = inst;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        children: [
          _buildCaptionHeader('themeColor'.tr),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildThemeColorButton(
                  'themeColorRed'.tr,
                  const Color.fromRGBO(154, 98, 91, 1),
                ),
                _buildThemeColorButton(
                  'themeColorBlue'.tr,
                  const Color.fromRGBO(103, 96, 193, 1),
                ),
                _buildThemeColorButton(
                  'themeColorMiku'.tr,
                  const Color.fromRGBO(56, 120, 126, 1),
                ),
              ],
            ).paddingSymmetric(horizontal: 12, vertical: 8),
          ),
        ],
      ),
    );
  }
}
