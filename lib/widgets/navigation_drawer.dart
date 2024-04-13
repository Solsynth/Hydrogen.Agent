import 'package:flutter/material.dart';
import 'package:solian/router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SolianNavigationDrawer extends StatefulWidget {
  const SolianNavigationDrawer({super.key});

  @override
  State<SolianNavigationDrawer> createState() => _SolianNavigationDrawerState();
}

class _SolianNavigationDrawerState extends State<SolianNavigationDrawer> {
  var _selectedIndex = 0;

  void _onSelect(String name, int idx) {
    setState(() => _selectedIndex = idx);
    router.goNamed(name);
  }

  @override
  Widget build(BuildContext context) {
    final navigationItems = [
      (
        NavigationDrawerDestination(
          icon: const Icon(Icons.explore),
          label: Text(AppLocalizations.of(context)!.explore),
        ),
        "explore",
      ),
      (
        NavigationDrawerDestination(
          icon: const Icon(Icons.account_circle),
          label: Text(AppLocalizations.of(context)!.account),
        ),
        "account",
      ),
    ];

    return NavigationDrawer(
      selectedIndex: _selectedIndex,
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
              Image.asset("assets/logo.png", width: 26, height: 26),
              const SizedBox(width: 10),
              Text(
                AppLocalizations.of(context)!.solian,
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
