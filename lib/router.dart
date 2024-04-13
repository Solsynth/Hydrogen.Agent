import 'package:go_router/go_router.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/explore.dart';
import 'package:solian/screens/posts/new_moment.dart';
import 'package:solian/screens/posts/screen.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'explore',
      builder: (context, state) => const ExploreScreen(),
    ),
    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) => const AccountScreen(),
    ),
    GoRoute(
      path: '/posts/moments/new',
      name: 'posts.moments.new',
      builder: (context, state) => const NewMomentScreen(),
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
