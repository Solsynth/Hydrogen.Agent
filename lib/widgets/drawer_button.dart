import 'package:flutter/material.dart';
import 'package:solian/shells/root_shell.dart';

class DrawerButton extends StatelessWidget {
  const DrawerButton({super.key});

  void openDrawer() {
    rootScaffoldKey.currentState!.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
      onPressed: openDrawer,
    );
  }
}
