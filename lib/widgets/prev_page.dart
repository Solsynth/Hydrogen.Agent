import 'package:flutter/material.dart';
import 'package:solian/router.dart';

class PrevPageButton extends StatelessWidget {
  const PrevPageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: () {
        if (AppRouter.instance.canPop()) {
          AppRouter.instance.pop();
        }
      },
    );
  }
}
