import 'package:go_router/go_router.dart';
import 'package:solian/screens/explore.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      name: 'explore',
      builder: (context, state) => const ExploreScreen(),
    ),
  ],
);
