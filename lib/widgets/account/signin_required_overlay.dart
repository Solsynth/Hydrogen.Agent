import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/screens/auth/signin.dart';

class SigninRequiredOverlay extends StatelessWidget {
  final Function onSignedIn;

  const SigninRequiredOverlay({super.key, required this.onSignedIn});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.login,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'signinRequired'.tr,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              Text(
                'signinRequiredHint'.tr,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        showModalBottomSheet(
          useRootNavigator: true,
          isScrollControlled: true,
          context: context,
          builder: (context) => const SignInPopup(),
        ).then((value) {
          if (value != null) onSignedIn();
        });
      },
    );
  }
}
