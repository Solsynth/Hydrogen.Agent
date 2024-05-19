import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void performAction(BuildContext context) {
    final AuthProvider provider = Get.find();

    final username = _usernameController.value.text;
    final password = _passwordController.value.text;
    if (username.isEmpty || password.isEmpty) return;
    provider.signin(context, username, password).then((_) {
      AppRouter.instance.pop(true);
    }).catchError((e) {
      List<String> messages = e.toString().split('\n');
      if (messages.last.contains('risk')) {
        final ticketId = RegExp(r'ticketId=(\d+)').firstMatch(messages.last);
        if (ticketId == null) {
          context.showErrorDialog('Requested to multi-factor authenticate, but the ticket id was not found');
        }
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text('riskDetection'.tr),
              content: Text('signinRiskDetected'.tr),
              actions: [
                TextButton(
                  child: Text('next'.tr),
                  onPressed: () {
                    launchUrlString(
                      '${ServiceFinder.services['passport']}/mfa?ticket=${ticketId!.group(1)}',
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
                  labelText: 'password'.tr,
                ),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                onSubmitted: (_) => performAction(context),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                child: Text('signin'.tr),
                onPressed: () => performAction(context),
              )
            ],
          ),
        ),
      ),
    );
  }
}
