import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/providers/friend.dart';
import 'package:solian/providers/navigation.dart';
import 'package:solian/providers/notify.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/utils/timeago.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/utils/video_player.dart';
import 'package:solian/widgets/chat/call/call_overlay.dart';
import 'package:solian/widgets/notification_notifier.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  initVideo();
  initTimeAgo();

  runApp(const SolianApp());
}

class SolianApp extends StatelessWidget {
  const SolianApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Solian',
      theme: SolianTheme.build(Brightness.light),
      darkTheme: SolianTheme.build(Brightness.dark),
      themeMode: ThemeMode.system,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            Provider(create: (_) => NavigationProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => NotifyProvider()),
            ChangeNotifierProvider(create: (_) => FriendProvider()),
          ],
          child: Overlay(
            initialEntries: [
              OverlayEntry(builder: (context) {
                return NotificationNotifier(child: child ?? Container());
              }),
              OverlayEntry(builder: (context) => const CallOverlay()),
            ],
          ),
        );
      },
    );
  }
}
