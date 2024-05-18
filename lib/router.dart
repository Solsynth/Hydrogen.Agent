import 'package:go_router/go_router.dart';
import 'package:solian/screens/account.dart';
import 'package:solian/screens/home.dart';
import 'package:solian/shells/nav_shell.dart';

class AppRouter {
  static GoRouter instance = GoRouter(
    routes: [
      ShellRoute(
        builder: (context, state, child) => NavShell(state: state, child: child),
        routes: [
          GoRoute(
            path: "/",
            name: "home",
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: "/account",
            name: "account",
            builder: (context, state) => const AccountScreen(),
          ),
        ],
      ),
    ],
  );
}
