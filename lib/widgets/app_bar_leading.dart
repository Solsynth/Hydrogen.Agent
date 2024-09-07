import 'package:flutter/material.dart';
import 'package:solian/shells/root_shell.dart';

class AppBarLeadingButton extends StatelessWidget {
  const AppBarLeadingButton({super.key});

  static Widget? adaptive(BuildContext context) {
    final hasContent =
        Navigator.canPop(context) || rootScaffoldKey.currentState!.hasDrawer;
    return hasContent ? const AppBarLeadingButton() : null;
  }

  @override
  Widget build(BuildContext context) {
    if (Navigator.canPop(context)) {
      return BackButton(
        onPressed: () => Navigator.pop(context),
      );
    }
    if (rootScaffoldKey.currentState!.hasDrawer) {
      return DrawerButton(
        onPressed: () => rootScaffoldKey.currentState!.openDrawer(),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
