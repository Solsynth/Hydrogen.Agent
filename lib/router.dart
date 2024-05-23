import 'package:go_router/go_router.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/account/friend.dart';
import 'package:solian/screens/account/personalize.dart';
import 'package:solian/screens/auth/signin.dart';
import 'package:solian/screens/auth/signup.dart';
import 'package:solian/screens/contact.dart';
import 'package:solian/screens/social.dart';
import 'package:solian/screens/posts/publish.dart';
import 'package:solian/shells/basic_shell.dart';
import 'package:solian/shells/nav_shell.dart';

abstract class AppRouter {
  static GoRouter instance = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            NavShell(state: state, child: child),
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
            path: '/auth/sign-in',
            name: 'signin',
            builder: (context, state) => const SignInScreen(),
          ),
          GoRoute(
            path: '/auth/sign-up',
            name: 'signup',
            builder: (context, state) => const SignUpScreen(),
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
    ],
  );
}
