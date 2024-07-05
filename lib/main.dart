import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:get/get.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:solian/exts.dart';
import 'package:solian/firebase_options.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/account.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/providers/content/call.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/content/post.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/providers/friend.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/router.dart';
import 'package:solian/shells/listener_shell.dart';
import 'package:solian/theme.dart';
import 'package:solian/translations.dart';

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

      _initializeFirebase();
      _initializePlatformComponents();

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
        Window.hideCloseButton(),
        Window.hideMiniaturizeButton(),
        Window.hideZoomButton(),
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
      theme: SolianTheme.build(Brightness.light),
      darkTheme: SolianTheme.build(Brightness.dark),
      themeMode: ThemeMode.system,
      routerDelegate: AppRouter.instance.routerDelegate,
      routeInformationParser: AppRouter.instance.routeInformationParser,
      routeInformationProvider: AppRouter.instance.routeInformationProvider,
      translations: SolianMessages(),
      locale: Get.deviceLocale,
      fallbackLocale: const Locale('en', 'US'),
      onInit: () => _initializeProviders(context),
      builder: (context, child) {
        return ListenerShell(
          child: ScaffoldMessenger(
            child: child ?? Container(),
          ),
        );
      },
    );
  }

  void _initializeProviders(BuildContext context) {
    Get.lazyPut(() => AuthProvider());
    Get.lazyPut(() => FriendProvider());
    Get.lazyPut(() => PostProvider());
    Get.lazyPut(() => AttachmentProvider());
    Get.lazyPut(() => ChatProvider());
    Get.lazyPut(() => AccountProvider());
    Get.lazyPut(() => StatusProvider());
    Get.lazyPut(() => ChannelProvider());
    Get.lazyPut(() => RealmProvider());
    Get.lazyPut(() => ChatCallProvider());

    final AuthProvider auth = Get.find();
    auth.isAuthorized.then((value) async {
      if (value) {
        Get.find<AccountProvider>().connect();
        Get.find<ChatProvider>().connect();

        try {
          Get.find<AccountProvider>().registerPushNotifications();
        } catch (err) {
          context.showSnackbar(
            'pushNotifyRegisterFailed'.trParams({'reason': err.toString()}),
          );
        }
      }
    });
  }
}
