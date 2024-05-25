import 'package:go_router/go_router.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/account/friend.dart';
import 'package:solian/screens/account/personalize.dart';
import 'package:solian/screens/channel/channel_chat.dart';
import 'package:solian/screens/channel/channel_organize.dart';
import 'package:solian/screens/contact.dart';
import 'package:solian/screens/posts/post_detail.dart';
import 'package:solian/screens/social.dart';
import 'package:solian/screens/posts/post_publish.dart';
import 'package:solian/shells/basic_shell.dart';
import 'package:solian/shells/nav_shell.dart';

abstract class AppRouter {
  static GoRouter instance = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            NavShell(state: state, child: child, showAppBar: false),
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
            path: '/posts/:alias',
            name: 'postDetail',
            builder: (context, state) => PostDetailScreen(
              alias: state.pathParameters['alias']!,
            ),
          ),
        ],
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
            realm: state.uri.queryParameters['realm'],
          );
        },
      ),
      GoRoute(
        path: '/chat/organize',
        name: 'channelOrganizing',
        builder: (context, state) {
          final arguments = state.extra as ChannelOrganizeArguments?;
          return ChannelOrganizeScreen(
            edit: arguments?.edit,
            realm: state.uri.queryParameters['realm'],
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
    ],
  );
}
