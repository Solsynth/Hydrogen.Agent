import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/root_container.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:url_launcher/url_launcher_string.dart';

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

  void _performAction(BuildContext context) async {
    final email = _emailController.value.text;
    final username = _usernameController.value.text;
    final nickname = _nicknameController.value.text;
    final password = _passwordController.value.text;
    if (email.isEmpty ||
        username.isEmpty ||
        nickname.isEmpty ||
        password.isEmpty) return;

    final client = await ServiceFinder.configureClient('auth');

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

  bool _isTermAccepted = false;

  @override
  Widget build(BuildContext context) {
    return RootContainer(
      child: CenteredContainer(
        maxWidth: 360,
        child: ListView(
          shrinkWrap: true,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Image.asset('assets/logo.png', width: 64, height: 64),
              ).paddingOnly(bottom: 8, left: 4),
            ),
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
              onSubmitted: (_) => _performAction(context),
            ),
            const Gap(8),
            CheckboxListTile(
              value: _isTermAccepted,
              title: Text(
                'termAccept'.tr,
                style: const TextStyle(height: 1.2),
              ).paddingOnly(bottom: 4),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(
                  Radius.circular(8),
                ),
              ),
              subtitle: RichText(
                text: TextSpan(
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.75),
                      ),
                  children: [
                    TextSpan(text: 'termAcceptDesc'.tr),
                    WidgetSpan(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('termAcceptLink'.tr),
                              const Gap(4),
                              const Icon(Icons.launch, size: 14),
                            ],
                          ),
                          onTap: () {
                            launchUrlString('https://solsynth.dev/terms');
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              onChanged: (value) {
                setState(() => _isTermAccepted = value ?? false);
              },
            ),
            const Gap(16),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed:
                    !_isTermAccepted ? null : () => _performAction(context),
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
      ).paddingAll(24),
    );
  }
}
