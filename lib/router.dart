import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/bootstrapper.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/screens/about.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/account/friend.dart';
import 'package:solian/screens/account/preferences/notifications.dart';
import 'package:solian/screens/account/profile_edit.dart';
import 'package:solian/screens/account/profile_page.dart';
import 'package:solian/screens/auth/signin.dart';
import 'package:solian/screens/auth/signup.dart';
import 'package:solian/screens/channel/channel_chat.dart';
import 'package:solian/screens/channel/channel_detail.dart';
import 'package:solian/screens/channel/channel_organize.dart';
import 'package:solian/screens/chat.dart';
import 'package:solian/screens/dashboard.dart';
import 'package:solian/screens/feed/search.dart';
import 'package:solian/screens/posts/post_detail.dart';
import 'package:solian/screens/feed/draft_box.dart';
import 'package:solian/screens/realms.dart';
import 'package:solian/screens/realms/realm_detail.dart';
import 'package:solian/screens/realms/realm_organize.dart';
import 'package:solian/screens/realms/realm_view.dart';
import 'package:solian/screens/explore.dart';
import 'package:solian/screens/posts/post_editor.dart';
import 'package:solian/screens/settings.dart';
import 'package:solian/shells/root_shell.dart';
import 'package:solian/shells/title_shell.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/sidebar/empty_placeholder.dart';

abstract class AppRouter {
  static GoRouter instance = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => BootstrapperShell(
          key: const Key('global-bootstrapper'),
          child: RootShell(
            state: state,
            child: child,
          ),
        ),
        routes: [
          GoRoute(
            path: '/',
            name: 'dashboard',
            builder: (context, state) => TitleShell(
              state: state,
              child: const DashboardScreen(),
            ),
          ),
          _feedRoute,
          _chatRoute,
          _realmRoute,
          _accountRoute,
          GoRoute(
            path: '/about',
            name: 'about',
            builder: (context, state) => TitleShell(
              state: state,
              child: const AboutScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => TitleShell(
              state: state,
              child: const SettingScreen(),
            ),
          ),
        ],
      ),
    ],
  );

  static final ShellRoute _feedRoute = ShellRoute(
    builder: (context, state, child) => child,
    routes: [
      GoRoute(
        path: '/explore',
        name: 'explore',
        builder: (context, state) => const ExploreScreen(),
      ),
      GoRoute(
        path: '/drafts',
        name: 'draftBox',
        builder: (context, state) => const DraftBoxScreen(),
      ),
      GoRoute(
        path: '/posts/search',
        name: 'postSearch',
        builder: (context, state) => TitleShell(
          state: state,
          child: FeedSearchScreen(
            tag: state.uri.queryParameters['tag'],
            category: state.uri.queryParameters['category'],
          ),
        ),
      ),
      GoRoute(
        path: '/posts/view/:id',
        name: 'postDetail',
        builder: (context, state) => TitleShell(
          state: state,
          child: PostDetailScreen(
            id: state.pathParameters['id']!,
          ),
        ),
      ),
      GoRoute(
        path: '/posts/editor',
        name: 'postEditor',
        pageBuilder: (context, state) {
          final arguments = state.extra as PostPublishArguments?;
          return CustomTransitionPage(
            child: PostPublishScreen(
              edit: arguments?.edit,
              reply: arguments?.reply,
              repost: arguments?.repost,
              realm: arguments?.realm,
              mode: int.tryParse(state.uri.queryParameters['mode'] ?? '0') ?? 0,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeThroughTransition(
                fillColor: Theme.of(context).scaffoldBackgroundColor,
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                child: child,
              );
            },
          );
        },
      ),
    ],
  );

  static final ShellRoute _chatRoute = ShellRoute(
    builder: (context, state, child) =>
        AppTheme.isLargeScreen(context) ? ChatListShell(child: child) : child,
    routes: [
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => AppTheme.isLargeScreen(context)
            ? const EmptyPagePlaceholder()
            : const ChatScreen(),
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
            key: UniqueKey(),
            alias: state.pathParameters['alias']!,
            realm: state.uri.queryParameters['realm'] ?? 'global',
          );
        },
      ),
      GoRoute(
        path: '/chat/:alias/detail',
        name: 'channelDetail',
        builder: (context, state) {
          final arguments = state.extra as ChannelDetailArguments;
          return TitleShell(
            state: state,
            isResponsive: true,
            child: ChannelDetailScreen(
              channel: arguments.channel,
              profile: arguments.profile,
              realm: state.uri.queryParameters['realm'] ?? 'global',
            ),
          );
        },
      ),
    ],
  );

  static final ShellRoute _realmRoute = ShellRoute(
    builder: (context, state, child) => child,
    routes: [
      GoRoute(
        path: '/realms',
        name: 'realms',
        builder: (context, state) => const RealmListScreen(),
      ),
      GoRoute(
        path: '/realms/:alias/detail',
        name: 'realmDetail',
        builder: (context, state) => TitleShell(
          state: state,
          child: RealmDetailScreen(
            realm: state.extra as Realm,
            alias: state.pathParameters['alias']!,
          ),
        ),
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

  static final ShellRoute _accountRoute = ShellRoute(
    builder: (context, state, child) => child,
    routes: [
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => TitleShell(
          state: state,
          isCenteredTitle: true,
          child: const AccountScreen(),
        ),
      ),
      GoRoute(
        path: '/account/friend',
        name: 'accountFriend',
        builder: (context, state) => const FriendScreen(),
      ),
      GoRoute(
        path: '/account/personalize',
        name: 'accountProfile',
        builder: (context, state) => TitleShell(
          state: state,
          child: const PersonalizeScreen(),
        ),
      ),
      GoRoute(
        path: '/account/preferences/notifications',
        name: 'notificationPreferences',
        builder: (context, state) => TitleShell(
          state: state,
          child: const NotificationPreferencesScreen(),
        ),
      ),
      GoRoute(
        path: '/account/view/:name',
        name: 'accountProfilePage',
        builder: (context, state) => AccountProfilePage(
          name: state.pathParameters['name']!,
        ),
      ),
      GoRoute(
        path: '/auth/sign-in',
        name: 'signin',
        builder: (context, state) => TitleShell(
          state: state,
          isCenteredTitle: true,
          child: const SignInScreen(),
        ),
      ),
      GoRoute(
        path: '/auth/sign-up',
        name: 'signup',
        builder: (context, state) => TitleShell(
          state: state,
          isCenteredTitle: true,
          child: const SignUpScreen(),
        ),
      ),
    ],
  );
}
