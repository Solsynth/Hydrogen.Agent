import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:http/http.dart' as http;

class SignUpScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();

  final http.Client _client = http.Client();

  SignUpScreen({super.key});

  void performSignIn(BuildContext context) async {
    final email = _emailController.value.text;
    final username = _usernameController.value.text;
    final nickname = _passwordController.value.text;
    final password = _passwordController.value.text;
    if (email.isEmpty ||
        username.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty) return;

    final uri = getRequestUri('passport', '/api/users');
    final res = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': username,
        'nick': nickname,
        'email': email,
        'password': password,
      }),
    );

    if (res.statusCode == 200) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.signUpDone),
            content: Text(AppLocalizations.of(context)!.signUpDoneCaption),
            actions: [
              TextButton(
                child: Text(AppLocalizations.of(context)!.confirmOkay),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      ).then((_) {
        SolianRouter.router.replaceNamed('auth.sign-in');
      });
    } else {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IndentScaffold(
      title: AppLocalizations.of(context)!.signUp,
      hideDrawer: true,
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
                  labelText: AppLocalizations.of(context)!.username,
                  prefixText: '@',
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
                  labelText: AppLocalizations.of(context)!.nickname,
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
                  labelText: AppLocalizations.of(context)!.email,
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
                  labelText: AppLocalizations.of(context)!.password,
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                onSubmitted: (_) => performSignIn(context),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.signUp),
                onPressed: () => performSignIn(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}
