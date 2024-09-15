import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:solian/bootstrapper.dart';
import 'package:solian/firebase_options.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/attachment_uploader.dart';
import 'package:solian/providers/daily_sign.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/providers/database/services/messages.dart';
import 'package:solian/providers/last_read.dart';
import 'package:solian/providers/link_expander.dart';
import 'package:solian/providers/navigation.dart';
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
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}

Future<void> _initializeBackgroundNotificationService() async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool('service_background_notification') != true) return;

  final service = FlutterBackgroundService();

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onBackgroundNotificationServiceStart,
      autoStart: true,
      autoStartOnBoot: true,
      isForegroundMode: false,
    ),
    // This feature won't be able to use on iOS
    // We got APNs support covered
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );

  await service.startService();
}

@pragma('vm:entry-point')
void onBackgroundNotificationServiceStart(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();

  Get.put(AuthProvider());
  Get.put(WebSocketProvider());

  final auth = Get.find<AuthProvider>();
  await auth.refreshAuthorizeStatus();
  await auth.ensureCredentials();
  if (!auth.isAuthorized.value) {
    debugPrint(
      'Background notification do nothing due to user didn\'t sign in.',
    );
    return;
  }

  const notificationChannelId = 'solian_notification_service';

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final ws = Get.find<WebSocketProvider>();
  await ws.connect();
  debugPrint('Background notification has been started');
  ws.stream.stream.listen(
    (event) {
      debugPrint(
        'Background notification service incoming message: ${event.method} ${event.message}',
      );

      if (event.method == 'notifications.new' && event.payload != null) {
        final data = Notification.fromJson(event.payload!);
        debugPrint(
          'Background notification service got a notification id=${data.id}',
        );
        flutterLocalNotificationsPlugin.show(
          data.id,
          data.title,
          [data.subtitle, data.body].where((x) => x != null).join('\n'),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              notificationChannelId,
              'Solian Notification Service',
              channelDescription: 'Notifications that sent via Solar Network',
              importance: Importance.high,
              icon: 'mipmap/ic_launcher',
            ),
          ),
        );
      }
    },
  );
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
                child: BootstrapperShell(
                  child: child ?? const SizedBox.shrink(),
                ),
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
    Get.lazyPut(() => RelationshipProvider());
    Get.lazyPut(() => PostProvider());
    Get.lazyPut(() => StickerProvider());
    Get.lazyPut(() => AttachmentProvider());
    Get.lazyPut(() => WebSocketProvider());
    Get.lazyPut(() => StatusProvider());
    Get.lazyPut(() => ChannelProvider());
    Get.lazyPut(() => RealmProvider());
    Get.lazyPut(() => MessagesFetchingProvider());
    Get.lazyPut(() => ChatCallProvider());
    Get.lazyPut(() => AttachmentUploaderController());
    Get.lazyPut(() => LinkExpandProvider());
    Get.lazyPut(() => DailySignProvider());
    Get.lazyPut(() => LastReadProvider());

    Get.find<WebSocketProvider>().requestPermissions();
  }
}
