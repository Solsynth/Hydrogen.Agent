import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/bootstrapper.dart';
import 'package:solian/firebase_options.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/providers/call.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/router.dart';
import 'package:solian/shells/system_shell.dart';
import 'package:solian/theme.dart';
import 'package:solian/translations.dart';
import 'package:flutter_web_plugins/url_strategy.dart' show usePathUrlStrategy;

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://55438cdff9048aa2225df72fdc629c42@o4506965897117696.ingest.us.sentry.io/4507357676437504';
      options.tracesSampleRate = 1.0;
      options.profilesSampleRate = 1.0;
    },
    appRunner: () async {
      WidgetsFlutterBinding.ensureInitialized();
      MediaKit.ensureInitialized();

      await Future.wait([
        _initializeTheme(),
        _initializeFirebase(),
        _initializePlatformComponents(),
      ]);

      GoRouter.optionURLReflectsImperativeAPIs = true;

      usePathUrlStrategy();
      runApp(const SolianApp());
    },
  );
}

Future<void> _initializeTheme() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.containsKey('global_theme_color')) {
    final value = prefs.getInt('global_theme_color')!;
    final color = Color(value);
    currentLightTheme = SolianTheme.build(Brightness.light, seedColor: color);
    currentDarkTheme = SolianTheme.build(Brightness.dark, seedColor: color);
  }
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> _initializePlatformComponents() async {
  if (!PlatformInfo.isWeb) {
    await protocolHandler.register('solink');
  }

  if (PlatformInfo.isDesktop) {
    await Window.initialize();

    if (PlatformInfo.isMacOS) {
      await Future.wait([
        Window.hideTitle(),
        Window.makeTitlebarTransparent(),
        Window.enableFullSizeContentView(),
      ]);
    }
  }
}

class SolianApp extends StatelessWidget {
  const SolianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'Solian',
      theme: currentLightTheme,
      darkTheme: currentDarkTheme,
      themeMode: ThemeMode.system,
      routerDelegate: AppRouter.instance.routerDelegate,
      routeInformationParser: AppRouter.instance.routeInformationParser,
      routeInformationProvider: AppRouter.instance.routeInformationProvider,
      backButtonDispatcher: AppRouter.instance.backButtonDispatcher,
      translations: SolianMessages(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      onInit: () => _initializeProviders(context),
      builder: (context, child) {
        return SystemShell(
          child: ScaffoldMessenger(
            child: BootstrapperShell(
              child: child ?? const SizedBox(),
            ),
          ),
        );
      },
    );
  }

  void _initializeProviders(BuildContext context) async {
    Get.lazyPut(() => AuthProvider());
    Get.lazyPut(() => RelationshipProvider());
    Get.lazyPut(() => PostProvider());
    Get.lazyPut(() => AttachmentProvider());
    Get.lazyPut(() => WebSocketProvider());
    Get.lazyPut(() => StatusProvider());
    Get.lazyPut(() => ChannelProvider());
    Get.lazyPut(() => RealmProvider());
    Get.lazyPut(() => ChatCallProvider());
  }
}
