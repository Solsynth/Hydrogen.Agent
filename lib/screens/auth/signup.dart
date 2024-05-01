import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/indent_wrapper.dart';

class SignUpScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();

  SignUpScreen({super.key});

  void performSignIn(BuildContext context) {
    final auth = context.read<AuthProvider>();

    final email = _emailController.value.text;
    final username = _usernameController.value.text;
    final nickname = _passwordController.value.text;
    final password = _passwordController.value.text;
    if (email.isEmpty ||
        username.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty) return;
  }

  @override
  Widget build(BuildContext context) {
    return IndentWrapper(
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
