import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/providers/notify.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/services_url.dart';
import 'package:solian/widgets/exts.dart';
import 'package:solian/widgets/scaffold.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SignInScreen extends StatelessWidget {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  SignInScreen({super.key});

  void performSignIn(BuildContext context) {
    final auth = context.read<AuthProvider>();

    final username = _usernameController.value.text;
    final password = _passwordController.value.text;
    if (username.isEmpty || password.isEmpty) return;
    auth.signin(context, username, password).then((_) {
      context.read<ChatProvider>().connect(auth);
      context.read<NotifyProvider>().connect(auth);
      SolianRouter.router.pop(true);
    }).catchError((e) {
      List<String> messages = e.toString().split('\n');
      if (messages.last.contains('risk')) {
        final ticketId = RegExp(r'ticketId=(\d+)').firstMatch(messages.last);
        if (ticketId == null) {
          context.showErrorDialog('requested to multi-factor authenticate, but the ticket id was not found');
        }
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.riskDetection),
              content: Text(AppLocalizations.of(context)!.signInRiskDetected),
              actions: [
                TextButton(
                  child: Text(AppLocalizations.of(context)!.next),
                  onPressed: () {
                    launchUrlString(
                      getRequestUri('passport', '/mfa?ticket=${ticketId!.group(1)}').toString(),
                    );
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                )
              ],
            );
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(messages.last),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndentScaffold(
      title: AppLocalizations.of(context)!.signIn,
      hideDrawer: true,
      body: Center(
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
                ),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                onSubmitted: (_) => performSignIn(context),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: Text(AppLocalizations.of(context)!.signIn),
                onPressed: () => performSignIn(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}
