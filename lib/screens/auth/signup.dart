import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/router.dart';
import 'package:solian/services.dart';

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
    final nickname = _passwordController.value.text;
    final password = _passwordController.value.text;
    if (email.isEmpty ||
        username.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty) return;

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    final res = await client.post('/api/users', {
      'name': username,
      'nick': nickname,
      'email': email,
      'password': password,
    });

    if (res.statusCode == 200) {
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
      Get.showSnackbar(GetSnackBar(
        title: 'errorHappened'.tr,
        message: res.bodyString,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Image.asset('assets/logo.png', width: 72, height: 72),
              ),
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
              ElevatedButton(
                child: Text('signup'.tr),
                onPressed: () => performAction(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}
