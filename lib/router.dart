import 'package:go_router/go_router.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/screens/about.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/account/friend.dart';
import 'package:solian/screens/account/personalize.dart';
import 'package:solian/screens/channel/channel_chat.dart';
import 'package:solian/screens/channel/channel_detail.dart';
import 'package:solian/screens/channel/channel_organize.dart';
import 'package:solian/screens/contact.dart';
import 'package:solian/screens/posts/post_detail.dart';
import 'package:solian/screens/realms.dart';
import 'package:solian/screens/realms/realm_detail.dart';
import 'package:solian/screens/realms/realm_organize.dart';
import 'package:solian/screens/realms/realm_view.dart';
import 'package:solian/screens/social.dart';
import 'package:solian/screens/posts/post_publish.dart';
import 'package:solian/shells/basic_shell.dart';
import 'package:solian/shells/nav_shell.dart';

abstract class AppRouter {
  static GoRouter instance = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            NavShell(state: state, showAppBar: false, child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'social',
            builder: (context, state) => const SocialScreen(),
          ),
          GoRoute(
            path: '/contact',
            name: 'contact',
            builder: (context, state) => const ContactScreen(),
          ),
          GoRoute(
            path: '/realms',
            name: 'realms',
            builder: (context, state) => const RealmListScreen(),
          ),
          GoRoute(
            path: '/account',
            name: 'account',
            builder: (context, state) => const AccountScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            BasicShell(state: state, child: child),
        routes: [
          GoRoute(
            path: '/posts/view/:alias',
            name: 'postDetail',
            builder: (context, state) => PostDetailScreen(
              alias: state.pathParameters['alias']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/posts/publish',
        name: 'postPublishing',
        builder: (context, state) {
          final arguments = state.extra as PostPublishingArguments?;
          return PostPublishingScreen(
            edit: arguments?.edit,
            reply: arguments?.reply,
            repost: arguments?.repost,
            realm: arguments?.realm,
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) =>
            BasicShell(state: state, child: child),
        routes: [
          GoRoute(
            path: '/account/friend',
            name: 'accountFriend',
            builder: (context, state) => const FriendScreen(),
          ),
          GoRoute(
            path: '/account/personalize',
            name: 'accountPersonalize',
            builder: (context, state) => const PersonalizeScreen(),
          ),
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            BasicShell(state: state, child: child),
        routes: [
          GoRoute(
            path: '/chat/:alias/detail',
            name: 'channelDetail',
            builder: (context, state) => ChannelDetailScreen(
              channel: state.extra as Channel,
              realm: state.uri.queryParameters['realm'] ?? 'global',
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/chat/organize',
        name: 'channelOrganizing',
        builder: (context, state) {
          final arguments = state.extra as ChannelOrganizeArguments?;
          return ChannelOrganizeScreen(
            edit: arguments?.edit,
            realm: arguments?.realm,
          );
        },
      ),
      GoRoute(
        path: '/chat/:alias',
        name: 'channelChat',
        builder: (context, state) {
          return ChannelChatScreen(
            alias: state.pathParameters['alias']!,
            realm: state.uri.queryParameters['realm'] ?? 'global',
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) =>
            BasicShell(state: state, child: child),
        routes: [
          GoRoute(
            path: '/realms/:alias/detail',
            name: 'realmDetail',
            builder: (context, state) => RealmDetailScreen(
              realm: state.extra as Realm,
              alias: state.pathParameters['alias']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/realm/organize',
        name: 'realmOrganizing',
        builder: (context, state) {
          final arguments = state.extra as RealmOrganizeArguments?;
          return RealmOrganizeScreen(
            edit: arguments?.edit,
          );
        },
      ),
      GoRoute(
        path: '/realm/:alias',
        name: 'realmView',
        builder: (context, state) {
          return RealmViewScreen(
            alias: state.pathParameters['alias']!,
          );
        },
      ),
    ],
  );
}
