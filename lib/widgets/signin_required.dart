import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/router.dart';

class SignInRequiredScreen extends StatelessWidget {
  const SignInRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 40),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.signInRequired,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                AppLocalizations.of(context)!.signInCaption,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              )
            ],
          ),
        ),
      ),
      onTap: () {
        SolianRouter.router.goNamed('account');
      },
    );
  }
}
