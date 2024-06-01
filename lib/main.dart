import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:solian/providers/account.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/providers/content/call.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/content/post.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/providers/friend.dart';
import 'package:solian/router.dart';
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
    appRunner: () => runApp(const SolianApp()),
  );
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
      onInit: () {
        Get.lazyPut(() => AuthProvider());
        Get.lazyPut(() => FriendProvider());
        Get.lazyPut(() => PostProvider());
        Get.lazyPut(() => AttachmentProvider());
        Get.lazyPut(() => ChatProvider());
        Get.lazyPut(() => AccountProvider());
        Get.lazyPut(() => ChannelProvider());
        Get.lazyPut(() => RealmProvider());
        Get.lazyPut(() => ChatCallProvider());

        final AuthProvider auth = Get.find();
        auth.isAuthorized.then((value) async {
          if (value) {
            Get.find<AccountProvider>().connect();
            Get.find<ChatProvider>().connect();
          }
        });
      },
      builder: (context, child) {
        return ScaffoldMessenger(
          child: child ?? Container(),
        );
      },
    );
  }
}
