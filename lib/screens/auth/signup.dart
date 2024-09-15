import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/sized_container.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();

  void performAction(BuildContext context) async {
    final email = _emailController.value.text;
    final username = _usernameController.value.text;
    final nickname = _nicknameController.value.text;
    final password = _passwordController.value.text;
    if (email.isEmpty ||
        username.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty) return;

    final client = ServiceFinder.configureClient('auth');

    final resp = await client.post('/users', {
      'name': username,
      'nick': nickname,
      'email': email,
      'password': password,
    });

    if (resp.statusCode == 200) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('signupDone'.tr),
            content: Text('signupDoneCaption'.tr),
            actions: [
              TextButton(
                child: Text('okay'.tr),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      ).then((_) {
        Navigator.pop(context);
      });
    } else {
      context.showErrorDialog(resp.bodyString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CenteredContainer(
        maxWidth: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(8)),
              child: Image.asset('assets/logo.png', width: 64, height: 64),
            ).paddingOnly(bottom: 4),
            Text(
              'signupGreeting'.tr,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ).paddingOnly(left: 4, bottom: 16),
            TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: _usernameController,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                labelText: 'username'.tr,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const Gap(12),
            TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: _nicknameController,
              autofillHints: const [AutofillHints.nickname],
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                labelText: 'nickname'.tr,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const Gap(12),
            TextField(
              autocorrect: false,
              enableSuggestions: false,
              controller: _emailController,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                labelText: 'email'.tr,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const Gap(12),
            TextField(
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              autofillHints: const [AutofillHints.password],
              controller: _passwordController,
              decoration: InputDecoration(
                isDense: true,
                border: const OutlineInputBorder(),
                labelText: 'password'.tr,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
              onSubmitted: (_) => performAction(context),
            ),
            const Gap(16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('next'.tr),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onPressed: () => performAction(context),
              ),
            )
          ],
        ),
      ),
    );
  }
}
