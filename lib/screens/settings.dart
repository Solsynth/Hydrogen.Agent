import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/theme_switcher.dart';
import 'package:solian/router.dart';
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
        context.read<ThemeSwitcher>().setTheme(
              SolianTheme.build(
                Brightness.light,
                seedColor: color,
              ),
              SolianTheme.build(
                Brightness.dark,
                seedColor: color,
              ),
            );
        _prefs.setInt('global_theme_color', color.value);
        context.clearSnackbar();
        context.showSnackbar('themeColorApplied'.tr);
      },
    );
  }

  static final List<(String, Color)> _presentTheme = [
    ('themeColorRed', const Color.fromRGBO(154, 98, 91, 1)),
    ('themeColorBlue', const Color.fromRGBO(103, 96, 193, 1)),
    ('themeColorMiku', const Color.fromRGBO(56, 120, 126, 1)),
    ('themeColorKagamine', const Color.fromRGBO(244, 183, 63, 1)),
    ('themeColorLuka', const Color.fromRGBO(243, 174, 218, 1)),
  ];

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
              children: _presentTheme
                  .map((x) => _buildThemeColorButton(x.$1, x.$2))
                  .toList(),
            ).paddingSymmetric(horizontal: 12, vertical: 8),
          ),
          _buildCaptionHeader('more'.tr),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextButton(
                style: const ButtonStyle(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                ),
                child: Text('about'.tr),
                onPressed: () {
                  AppRouter.instance.pushNamed('about');
                },
              ),
              TextButton(
                style: const ButtonStyle(
                  visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                ),
                child: Text('messageHistoryWipe'.tr),
                onPressed: () {
                  final chatHistory = ChatEventController();
                  chatHistory.initialize().then((_) async {
                    await chatHistory.database.localEvents.wipeLocalEvents();
                  });
                },
              ),
            ],
          ).paddingSymmetric(horizontal: 12, vertical: 8),
        ],
      ),
    );
  }
}
