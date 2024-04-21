import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/indent_wrapper.dart';

class SignInScreen extends StatelessWidget {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return IndentWrapper(
      title: AppLocalizations.of(context)!.signIn,
      hideDrawer: true,
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.6,
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                autocorrect: false,
                enableSuggestions: false,
                controller: _usernameController,
                decoration: InputDecoration(
                  isDense: true,
                  border: const UnderlineInputBorder(),
                  hintText: AppLocalizations.of(context)!.username,
                ),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              ),
              const SizedBox(height: 12),
              TextField(
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                controller: _passwordController,
                decoration: InputDecoration(
                  isDense: true,
                  border: const UnderlineInputBorder(),
                  hintText: AppLocalizations.of(context)!.password,
                ),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
              ),
              const SizedBox(height: 16),
              TextButton(
                child: Text(AppLocalizations.of(context)!.next),
                onPressed: () {
                  final username = _usernameController.value.text;
                  final password = _passwordController.value.text;
                  if (username.isEmpty || password.isEmpty) return;
                  auth.signin(context, username, password).then((_) {
                    router.pop(true);
                  }).catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(e.toString()),
                    ));
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
