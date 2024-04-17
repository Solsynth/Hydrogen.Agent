import 'package:go_router/go_router.dart';
import 'package:solian/models/post.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/chat/chat.dart';
import 'package:solian/screens/chat/index.dart';
import 'package:solian/screens/explore.dart';
import 'package:solian/screens/posts/comment_editor.dart';
import 'package:solian/screens/posts/moment_editor.dart';
import 'package:solian/screens/posts/screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'explore',
      builder: (context, state) => const ExploreScreen(),
    ),
    GoRoute(
      path: '/chat',
      name: 'chat',
      builder: (context, state) => const ChatIndexScreen(),
    ),
    GoRoute(
      path: '/chat/:channel',
      name: 'chat.channel',
      builder: (context, state) => ChatScreen(alias: state.pathParameters['channel'] as String),
    ),
    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/posts/publish/moments',
      name: 'posts.moments.editor',
      builder: (context, state) =>
          MomentEditorScreen(editing: state.extra as Post?),
    ),
    GoRoute(
      path: '/posts/publish/comments',
      name: 'posts.comments.editor',
      builder: (context, state) {
        final args = state.extra as CommentPostArguments;
        return CommentEditorScreen(
            editing: args.editing, related: args.related);
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
);
