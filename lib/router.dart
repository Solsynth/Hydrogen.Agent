import 'package:go_router/go_router.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/screens/about.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/account/friend.dart';
import 'package:solian/screens/account/personalize.dart';
import 'package:solian/screens/articles/article_publish.dart';
import 'package:solian/screens/channel/channel_chat.dart';
import 'package:solian/screens/channel/channel_detail.dart';
import 'package:solian/screens/channel/channel_organize.dart';
import 'package:solian/screens/chat.dart';
import 'package:solian/screens/feed/search.dart';
import 'package:solian/screens/posts/post_detail.dart';
import 'package:solian/screens/feed/draft_box.dart';
import 'package:solian/screens/realms.dart';
import 'package:solian/screens/realms/realm_detail.dart';
import 'package:solian/screens/realms/realm_organize.dart';
import 'package:solian/screens/realms/realm_view.dart';
import 'package:solian/screens/feed.dart';
import 'package:solian/screens/posts/post_publish.dart';
import 'package:solian/shells/basic_shell.dart';
import 'package:solian/shells/root_shell.dart';
import 'package:solian/shells/title_shell.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/sidebar/empty_placeholder.dart';

abstract class AppRouter {
  static GoRouter instance = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => RootShell(
          state: state,
          child: child,
        ),
        routes: [
          _feedRoute,
          _chatRoute,
          _realmRoute,
          _accountRoute,
        ],
      ),
    ],
  );

  static final ShellRoute _feedRoute = ShellRoute(
    builder: (context, state, child) => child,
    routes: [
      GoRoute(
        path: '/',
        name: 'feed',
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: '/feed/search',
        name: 'feedSearch',
        builder: (context, state) => TitleShell(
          state: state,
          child: FeedSearchScreen(
            tag: state.uri.queryParameters['tag'],
            category: state.uri.queryParameters['category'],
          ),
        ),
      ),
      GoRoute(
        path: '/drafts',
        name: 'draftBox',
        builder: (context, state) => const DraftBoxScreen(),
      ),
      GoRoute(
        path: '/posts/view/:alias',
        name: 'postDetail',
        builder: (context, state) => TitleShell(
          state: state,
          child: PostDetailScreen(
            alias: state.pathParameters['alias']!,
          ),
        ),
      ),
      GoRoute(
        path: '/posts/publish',
        name: 'postCreate',
        builder: (context, state) {
          final arguments = state.extra as PostPublishArguments?;
          return PostPublishScreen(
            edit: arguments?.edit,
            reply: arguments?.reply,
            repost: arguments?.repost,
            realm: arguments?.realm,
          );
        },
      ),
      GoRoute(
        path: '/articles/publish',
        name: 'articleCreate',
        builder: (context, state) {
          final arguments = state.extra as ArticlePublishArguments?;
          return ArticlePublishScreen(
            edit: arguments?.edit,
            realm: arguments?.realm,
          );
        },
      )
    ],
  );

  static final ShellRoute _chatRoute = ShellRoute(
    builder: (context, state, child) => BasicShell(
      state: state,
      sidebarFirst: true,
      showAppBar: false,
      sidebar: const ChatScreen(),
      child: child,
    ),
    routes: [
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => SolianTheme.isExtraLargeScreen(context)
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
    builder: (context, state, child) => BasicShell(
      state: state,
      sidebarFirst: true,
      showAppBar: false,
      sidebar: const RealmListScreen(),
      child: child,
    ),
    routes: [
      GoRoute(
        path: '/realms',
        name: 'realms',
        builder: (context, state) => SolianTheme.isExtraLargeScreen(context)
            ? const EmptyPagePlaceholder()
            : const RealmListScreen(),
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
    builder: (context, state, child) => BasicShell(
      state: state,
      sidebarFirst: true,
      showAppBar: false,
      sidebar: const AccountScreen(),
      child: child,
    ),
    routes: [
      GoRoute(
        path: '/account',
        name: 'account',
        builder: (context, state) => SolianTheme.isExtraLargeScreen(context)
            ? const EmptyPagePlaceholder()
            : const AccountScreen(),
      ),
      GoRoute(
        path: '/account/friend',
        name: 'accountFriend',
        builder: (context, state) => TitleShell(
          state: state,
          child: const FriendScreen(),
        ),
      ),
      GoRoute(
        path: '/account/personalize',
        name: 'accountPersonalize',
        builder: (context, state) => TitleShell(
          state: state,
          child: const PersonalizeScreen(),
        ),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) => TitleShell(
          state: state,
          child: const AboutScreen(),
        ),
      ),
    ],
  );
}
