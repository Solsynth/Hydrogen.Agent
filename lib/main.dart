import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/translations.dart';

void main() {
  runApp(const SolianApp());
}

class SolianApp extends StatelessWidget {
  const SolianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'Solian',
      theme: SolianTheme.build(Brightness.light),
      darkTheme: SolianTheme.build(Brightness.dark),
      themeMode: ThemeMode.system,
      routerDelegate: AppRouter.instance.routerDelegate,
      routeInformationParser: AppRouter.instance.routeInformationParser,
      routeInformationProvider: AppRouter.instance.routeInformationProvider,
      translations: SolianMessages(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(
              builder: (context) => ScaffoldMessenger(
                child: child ?? Container(),
              ),
            ),
          ],
        );
      },
    );
  }
}
