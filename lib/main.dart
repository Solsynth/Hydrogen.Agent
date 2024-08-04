import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:solian/bootstrapper.dart';
import 'package:solian/firebase_options.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/attachment_uploader.dart';
import 'package:solian/providers/stickers.dart';
import 'package:solian/providers/theme_switcher.dart';
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
        _initializeFirebase(),
        _initializePlatformComponents(),
      ]);

      GoRouter.optionURLReflectsImperativeAPIs = true;

      usePathUrlStrategy();
      runApp(const SolianApp());
    },
  );
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

final themeSwitcher = ThemeSwitcher(
  lightThemeData: SolianTheme.build(Brightness.light),
  darkThemeData: SolianTheme.build(Brightness.dark),
);

class SolianApp extends StatelessWidget {
  const SolianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: themeSwitcher,
      child: Builder(builder: (context) {
        final theme = Provider.of<ThemeSwitcher>(context);

        return GetMaterialApp.router(
          title: 'Solian',
          theme: theme.lightThemeData,
          darkTheme: theme.darkThemeData,
          themeMode: ThemeMode.system,
          routerDelegate: AppRouter.instance.routerDelegate,
          routeInformationParser: AppRouter.instance.routeInformationParser,
          routeInformationProvider: AppRouter.instance.routeInformationProvider,
          backButtonDispatcher: AppRouter.instance.backButtonDispatcher,
          translations: SolianMessages(),
          locale: const Locale('en', 'US'),
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
      }),
    );
  }

  void _initializeProviders(BuildContext context) async {
    Get.lazyPut(() => AuthProvider());
    Get.lazyPut(() => RelationshipProvider());
    Get.lazyPut(() => PostProvider());
    Get.lazyPut(() => StickerProvider());
    Get.lazyPut(() => AttachmentProvider());
    Get.lazyPut(() => WebSocketProvider());
    Get.lazyPut(() => StatusProvider());
    Get.lazyPut(() => ChannelProvider());
    Get.lazyPut(() => RealmProvider());
    Get.lazyPut(() => ChatCallProvider());
    Get.lazyPut(() => AttachmentUploaderController());
  }
}
