import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/post.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/account/friend.dart';
import 'package:solian/screens/account/personalize.dart';
import 'package:solian/screens/auth/signup.dart';
import 'package:solian/screens/chat/call.dart';
import 'package:solian/screens/chat/chat.dart';
import 'package:solian/screens/chat/chat_list.dart';
import 'package:solian/screens/chat/chat_detail.dart';
import 'package:solian/screens/chat/channel/channel_editor.dart';
import 'package:solian/screens/chat/channel/channel_member.dart';
import 'package:solian/screens/explore.dart';
import 'package:solian/screens/notification.dart';
import 'package:solian/screens/posts/comment_editor.dart';
import 'package:solian/screens/posts/moment_editor.dart';
import 'package:solian/screens/posts/screen.dart';
import 'package:solian/screens/auth/signin.dart';
import 'package:solian/screens/users/userinfo.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/empty.dart';
import 'package:solian/widgets/layouts/two_column.dart';

abstract class SolianRouter {
  static final router = GoRouter(
    routes: [
      GoRoute(
        path: '/notification',
        name: 'notification',
        builder: (context, state) => const NotificationScreen(),
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => defaultPageBuilder(
          context,
          state,
          SolianTheme.isLargeScreen(context)
              ? TwoColumnLayout(
                  sideChild: const ExplorePostScreen(),
                  mainChild: child,
                )
              : child,
        ),
        routes: [
          GoRoute(
            path: '/',
            name: 'explore',
            builder: (context, state) =>
                !SolianTheme.isLargeScreen(context) ? const ExplorePostScreen() : const PageEmptyWidget(),
          ),
          GoRoute(
            path: '/posts/publish/moments',
            name: 'posts.moments.editor',
            builder: (context, state) => MomentEditorScreen(editing: state.extra as Post?),
          ),
          GoRoute(
            path: '/posts/publish/comments',
            name: 'posts.comments.editor',
            builder: (context, state) {
              final args = state.extra as CommentPostArguments;
              return CommentEditorScreen(editing: args.editing, related: args.related);
            },
          ),
          GoRoute(
            path: '/posts/:dataset/:alias',
            name: 'posts.screen',
            builder: (context, state) => PostScreen(
              alias: state.pathParameters['alias'] as String,
              dataset: state.pathParameters['dataset'] as String,
            ),
          ),
        ],
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => defaultPageBuilder(
          context,
          state,
          SolianTheme.isLargeScreen(context)
              ? TwoColumnLayout(
                  sideChild: const ChatListScreen(),
                  mainChild: child,
                )
              : child,
        ),
        routes: [
          GoRoute(
            path: '/chat',
            name: 'chat',
            builder: (context, state) =>
                !SolianTheme.isLargeScreen(context) ? const ChatListScreen() : const PageEmptyWidget(),
          ),
          GoRoute(
            path: '/chat/create',
            name: 'chat.channel.editor',
            builder: (context, state) => ChannelEditorScreen(editing: state.extra as Channel?),
          ),
          GoRoute(
            path: '/chat/c/:channel',
            name: 'chat.channel',
            builder: (context, state) => ChatScreen(alias: state.pathParameters['channel'] as String),
          ),
          GoRoute(
            path: '/chat/c/:channel/call',
            name: 'chat.channel.call',
            builder: (context, state) => ChatCall(call: state.extra as Call),
          ),
          GoRoute(
            path: '/chat/c/:channel/manage',
            name: 'chat.channel.manage',
            builder: (context, state) => ChatDetailScreen(channel: state.extra as Channel),
          ),
          GoRoute(
            path: '/chat/c/:channel/member',
            name: 'chat.channel.member',
            builder: (context, state) => ChatMemberScreen(channel: state.extra as Channel),
          ),
        ],
      ),
      ShellRoute(
        pageBuilder: (context, state, child) => defaultPageBuilder(
          context,
          state,
          SolianTheme.isLargeScreen(context)
              ? TwoColumnLayout(
                  sideChild: const AccountScreen(),
                  mainChild: child,
                )
              : child,
        ),
        routes: [
          GoRoute(
            path: '/account',
            name: 'account',
            builder: (context, state) =>
                !SolianTheme.isLargeScreen(context) ? const AccountScreen() : const PageEmptyWidget(),
          ),
          GoRoute(
            path: '/auth/sign-in',
            name: 'auth.sign-in',
            builder: (context, state) => SignInScreen(),
          ),
          GoRoute(
            path: '/auth/sign-up',
            name: 'auth.sign-up',
            builder: (context, state) => SignUpScreen(),
          ),
          GoRoute(
            path: '/account/friend',
            name: 'account.friend',
            builder: (context, state) => const FriendScreen(),
          ),
          GoRoute(
            path: '/account/personalize',
            name: 'account.personalize',
            builder: (context, state) => const PersonalizeScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/users/:user',
        name: 'users.info',
        builder: (context, state) => UserInfoScreen(name: state.pathParameters['user'] as String),
      ),
    ],
  );

  static GoRoute get currentRoute => SolianRouter.router.routerDelegate.currentConfiguration.last.route;

  static Page defaultPageBuilder(
    BuildContext context,
    GoRouterState state,
    Widget child,
  ) =>
      MaterialPage(
        key: state.pageKey,
        restorationId: state.pageKey.value,
        child: child,
      );
}
