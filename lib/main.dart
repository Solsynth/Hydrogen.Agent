import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:solian/background.dart';
import 'package:solian/firebase_options.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/attachment_uploader.dart';
import 'package:solian/providers/daily_sign.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/providers/database/services/messages.dart';
import 'package:solian/providers/last_read.dart';
import 'package:solian/providers/link_expander.dart';
import 'package:solian/providers/navigation.dart';
import 'package:solian/providers/notifications.dart';
import 'package:solian/providers/stickers.dart';
import 'package:solian/providers/subscription.dart';
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
  WidgetsFlutterBinding.ensureInitialized();

  await Future.wait([
    _initializeFirebase(),
    _initializePlatformComponents(),
    _initializeBackgroundNotificationService(),
  ]);

  GoRouter.optionURLReflectsImperativeAPIs = true;

  Get.put(DatabaseProvider());
  Get.put(AppTranslations());
  await AppTranslations.init();

  usePathUrlStrategy();
  runApp(const SolianApp());
}

Future<void> _initializeFirebase() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (PlatformInfo.isIOS || PlatformInfo.isAndroid || PlatformInfo.isMacOS) {
    // Initialize firebase crashlytics for the platform that supported
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}

Future<void> _initializeBackgroundNotificationService() async {
  autoConfigureBackgroundNotificationService();
  autoStartBackgroundNotificationService();
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
  lightThemeData: AppTheme.build(Brightness.light),
  darkThemeData: AppTheme.build(Brightness.dark),
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
          translations: Get.find<AppTranslations>(),
          locale: Get.deviceLocale,
          fallbackLocale: const Locale('en', 'US'),
          onInit: () {
            _initializeProviders(context);
          },
          builder: (context, child) {
            return SystemShell(
              child: ScaffoldMessenger(
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      }),
    );
  }

  void _initializeProviders(BuildContext context) async {
    Get.put(NavigationStateProvider());

    Get.lazyPut(() => AuthProvider());
    Get.lazyPut(() => WebSocketProvider());
    Get.lazyPut(() => RelationshipProvider());
    Get.lazyPut(() => PostProvider());
    Get.lazyPut(() => StickerProvider());
    Get.lazyPut(() => AttachmentProvider());
    Get.lazyPut(() => NotificationProvider());
    Get.lazyPut(() => StatusProvider());
    Get.lazyPut(() => ChannelProvider());
    Get.lazyPut(() => RealmProvider());
    Get.lazyPut(() => MessagesFetchingProvider());
    Get.lazyPut(() => ChatCallProvider());
    Get.lazyPut(() => AttachmentUploaderController());
    Get.lazyPut(() => LinkExpandProvider());
    Get.lazyPut(() => DailySignProvider());
    Get.lazyPut(() => LastReadProvider());
    Get.lazyPut(() => SubscriptionProvider());

    Get.find<NotificationProvider>().requestPermissions();
  }
}
