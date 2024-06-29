import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/account.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SignInPopup extends StatefulWidget {
  const SignInPopup({super.key});

  @override
  State<SignInPopup> createState() => _SignInPopupState();
}

class _SignInPopupState extends State<SignInPopup> {
  bool _isBusy = false;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  void performAction(BuildContext context) async {
    final AuthProvider provider = Get.find();

    final username = _usernameController.value.text;
    final password = _passwordController.value.text;
    if (username.isEmpty || password.isEmpty) return;

    setState(() => _isBusy = true);

    try {
      await provider.signin(context, username, password);
    } on RiskyAuthenticateException catch (e) {
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
                    '${ServiceFinder.services['passport']}/mfa?close=yes&ticketId=${e.ticketId}',
                  );
                  Navigator.pop(context);
                },
              )
            ],
          );
        },
      );
      return;
    } catch (e) {
      context.showErrorDialog(e);
      return;
    } finally {
      setState(() => _isBusy = false);
    }

    Get.find<AccountProvider>().registerPushNotifications();

    Navigator.pop(context, true);
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
                'signinGreeting'.tr,
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isBusy ? null : () => performAction(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('next'.tr),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
