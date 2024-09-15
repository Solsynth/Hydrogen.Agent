import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/sized_container.dart';

class SigninRequiredOverlay extends StatelessWidget {
  final Function onDone;

  const SigninRequiredOverlay({super.key, required this.onDone});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: CenteredContainer(
        maxWidth: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.login,
              size: 48,
            ),
            const Gap(8),
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
      onTap: () {
        AppRouter.instance.pushNamed('signin').then((value) {
          if (value != null) onDone();
        });
      },
    );
  }
}
