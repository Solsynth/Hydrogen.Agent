import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/layout_provider.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/timeago.dart';
import 'package:solian/widgets/wrapper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() {
  initTimeAgo();

  runApp(const SolianApp());
}

class SolianApp extends StatelessWidget {
  const SolianApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Solian',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(builder: (context) {
              return MultiProvider(
                providers: [
                  Provider(create: (_) => LayoutConfig(context))
                ],
                child: LayoutWrapper(
                  child: child,
                ),
              );
            })
          ],
        );
      },
    );
  }
}
