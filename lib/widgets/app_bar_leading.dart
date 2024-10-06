import 'package:flutter/material.dart';

class AppBarLeadingButton extends StatelessWidget {
  final bool forceBack;

  const AppBarLeadingButton({super.key, this.forceBack = false});

  static Widget? adaptive(BuildContext context, {bool forceBack = false}) {
    final hasContent = Navigator.canPop(context) || forceBack;
    return hasContent ? AppBarLeadingButton(forceBack: forceBack) : null;
  }

  @override
  Widget build(BuildContext context) {
    if (Navigator.canPop(context) || forceBack) {
      return BackButton(
        onPressed: () => Navigator.pop(context),
      );
    }
    return const SizedBox.shrink();
  }
}
