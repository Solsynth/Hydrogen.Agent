import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/router.dart';
import 'package:solian/services.dart';

class SignUpPopup extends StatefulWidget {
  const SignUpPopup({super.key});

  @override
  State<SignUpPopup> createState() => _SignUpPopupState();
}

class _SignUpPopupState extends State<SignUpPopup> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();

  void performAction(BuildContext context) async {
    final email = _emailController.value.text;
    final username = _usernameController.value.text;
    final nickname = _passwordController.value.text;
    final password = _passwordController.value.text;
    if (email.isEmpty ||
        username.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty) return;

    final client = ServiceFinder.configureClient('passport');

    final resp = await client.post('/api/users', {
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
                child: Text('confirmOkay'.tr),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      ).then((_) {
        AppRouter.instance.replaceNamed('auth.sign-in');
      });
    } else {
      context.showErrorDialog(resp.bodyString);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.9,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset('assets/logo.png', width: 64, height: 64)
                  .paddingOnly(bottom: 4),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),
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
      ),
    );
  }
}
