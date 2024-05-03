import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/navigation.dart';
import 'package:solian/router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/utils/theme.dart';

class SolianNavigationDrawer extends StatefulWidget {
  const SolianNavigationDrawer({super.key});

  @override
  State<SolianNavigationDrawer> createState() => _SolianNavigationDrawerState();
}

class _SolianNavigationDrawerState extends State<SolianNavigationDrawer> {
  var _selectedIndex = 0;

  void _onSelect(String name, int idx) {
    setState(() => _selectedIndex = idx);
    context.read<NavigationProvider>().selectedIndex = idx;
    SolianRouter.router.goNamed(name);
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      setState(() {
        _selectedIndex = context.read<NavigationProvider>().selectedIndex;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = [
      (
        NavigationDrawerDestination(
          icon: const Icon(Icons.explore),
          label: Text(AppLocalizations.of(context)!.explore),
        ),
        'explore',
      ),
      (
        NavigationDrawerDestination(
          icon: const Icon(Icons.send),
          label: Text(AppLocalizations.of(context)!.chat),
        ),
        'chat',
      ),
      (
        NavigationDrawerDestination(
          icon: const Icon(Icons.account_circle),
          label: Text(AppLocalizations.of(context)!.account),
        ),
        'account',
      ),
    ];

    return NavigationDrawer(
      selectedIndex: _selectedIndex,
      elevation: SolianTheme.isLargeScreen(context) ? 20 : 0,
      shadowColor: SolianTheme.isLargeScreen(context) ? Theme.of(context).shadowColor : null,
      surfaceTintColor: Theme.of(context).colorScheme.background,
      onDestinationSelected: (int idx) {
        final element = navigationItems[idx];
        _onSelect(element.$2, idx);
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Image.asset('assets/logo.png', width: 26, height: 26),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.appName,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
        ...navigationItems.map((x) => x.$1)
      ],
    );
  }
}
