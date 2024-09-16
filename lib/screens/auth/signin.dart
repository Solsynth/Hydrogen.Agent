import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/background.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/auth.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/sized_container.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  bool _isBusy = false;

  AuthTicket? _currentTicket;

  List<AuthFactor>? _factors;
  int? _factorPicked;
  int? _factorPickedType;

  int _period = 0;

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final Map<int, (String label, IconData icon, bool isOtp)> _factorLabelMap = {
    0: ('authFactorPassword'.tr, Icons.password, false),
    1: ('authFactorEmail'.tr, Icons.email, true),
  };

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  void _requestResetPassword() async {
    final username = _usernameController.value.text;
    if (username.isEmpty) {
      context.showErrorDialog('signinResetPasswordHint'.tr);
      return;
    }

    setState(() => _isBusy = true);

    final client = await ServiceFinder.configureClient('auth');
    final lookupResp = await client.get('/users/lookup?probe=$username');
    if (lookupResp.statusCode != 200) {
      context.showErrorDialog(lookupResp.bodyString);
      setState(() => _isBusy = false);
      return;
    }

    final resp = await client.post('/users/me/password-reset', {
      'user_id': lookupResp.body['id'],
    });
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
      setState(() => _isBusy = false);
      return;
    }

    setState(() => _isBusy = false);
    context.showModalDialog('done'.tr, 'signinResetPasswordSent'.tr);
  }

  void _performNewTicket() async {
    final username = _usernameController.value.text;
    if (username.isEmpty) return;

    final client = await ServiceFinder.configureClient('auth');

    setState(() => _isBusy = true);

    try {
      // Create ticket
      final resp = await client.post('/auth', {
        'username': username,
      });
      if (resp.statusCode != 200) {
        throw RequestException(resp);
      } else {
        final result = AuthResult.fromJson(resp.body);
        _currentTicket = result.ticket;
      }

      // Pull factors
      final factorResp = await client.get('/auth/factors',
          query: {'ticketId': _currentTicket!.id.toString()});
      if (factorResp.statusCode != 200) {
        throw RequestException(factorResp);
      } else {
        final result = List<AuthFactor>.from(
          factorResp.body.map((x) => AuthFactor.fromJson(x)),
        );
        _factors = result;
      }

      setState(() => _period++);
    } catch (e) {
      context.showErrorDialog(e);
      return;
    } finally {
      setState(() => _isBusy = false);
    }
  }

  void _performGetFactorCode() async {
    if (_factorPicked == null) return;

    final client = await ServiceFinder.configureClient('auth');

    setState(() => _isBusy = true);

    try {
      // Request one-time-password code
      final resp = await client.post('/auth/factors/$_factorPicked', {});
      if (resp.statusCode != 200 && resp.statusCode != 204) {
        throw RequestException(resp);
      } else {
        _factorPickedType = _factors!
            .where(
              (x) => x.id == _factorPicked,
            )
            .first
            .type;
      }

      setState(() => _period++);
    } catch (e) {
      context.showErrorDialog(e);
      return;
    } finally {
      setState(() => _isBusy = false);
    }
  }

  void _performCheckTicket() async {
    final AuthProvider auth = Get.find();

    final password = _passwordController.value.text;
    if (password.isEmpty) return;

    final client = await ServiceFinder.configureClient('auth');

    setState(() => _isBusy = true);

    try {
      // Check ticket
      final resp = await client.patch('/auth', {
        'ticket_id': _currentTicket!.id,
        'factor_id': _factorPicked!,
        'code': password,
      });
      if (resp.statusCode != 200) {
        throw RequestException(resp);
      }

      final result = AuthResult.fromJson(resp.body);
      _currentTicket = result.ticket;

      // Finish sign in if possible
      if (result.isFinished) {
        await auth.signin(context, _currentTicket!);

        await Future.delayed(const Duration(milliseconds: 250), () async {
          await auth.refreshAuthorizeStatus();
          await auth.refreshUserProfile();

          Get.find<WebSocketProvider>().registerPushNotifications();
          autoConfigureBackgroundNotificationService();
          autoStartBackgroundNotificationService();

          Navigator.pop(context, true);
        });
      } else {
        // Skip the first step
        _factorPicked = null;
        _factorPickedType = null;
        setState(() => _period += 2);
      }
    } catch (e) {
      context.showErrorDialog(e);
      return;
    } finally {
      setState(() => _isBusy = false);
    }
  }

  void _previousStep() {
    assert(_period > 0);
    switch (_period % 3) {
      case 1:
        _currentTicket = null;
        _factors = null;
        _factorPicked = null;
      case 2:
        _passwordController.clear();
        _factorPickedType = null;
      default:
        setState(() => _period--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: CenteredContainer(
        maxWidth: 360,
        child: PageTransitionSwitcher(
          transitionBuilder: (
            Widget child,
            Animation<double> primaryAnimation,
            Animation<double> secondaryAnimation,
          ) {
            return SharedAxisTransition(
              animation: primaryAnimation,
              secondaryAnimation: secondaryAnimation,
              transitionType: SharedAxisTransitionType.horizontal,
              child: child,
            );
          },
          child: switch (_period % 3) {
            1 => Column(
                key: const ValueKey<int>(1),
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child:
                        Image.asset('assets/logo.png', width: 64, height: 64),
                  ).paddingOnly(bottom: 8, left: 4),
                  Text(
                    'signinPickFactor'.tr,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ).paddingOnly(left: 4, bottom: 16),
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      children: _factors
                              ?.map(
                                (x) => CheckboxListTile(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                      Radius.circular(8),
                                    ),
                                  ),
                                  secondary: Icon(
                                    _factorLabelMap[x.type]?.$2 ??
                                        Icons.question_mark,
                                  ),
                                  title: Text(
                                    _factorLabelMap[x.type]?.$1 ?? 'unknown'.tr,
                                  ),
                                  enabled: !_currentTicket!.factorTrail
                                      .contains(x.id),
                                  value: _factorPicked == x.id,
                                  onChanged: (value) {
                                    if (value == true) {
                                      setState(() => _factorPicked = x.id);
                                    }
                                  },
                                ),
                              )
                              .toList() ??
                          List.empty(),
                    ),
                  ),
                  Text(
                    'signinMultiFactor'.trParams(
                      {'n': _currentTicket!.stepRemain.toString()},
                    ),
                    style: TextStyle(color: _unFocusColor, fontSize: 12),
                  ).paddingOnly(left: 16, right: 16),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: (_isBusy || _period > 1)
                            ? null
                            : () => _previousStep(),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.grey),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_left),
                            Text('prev'.tr),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed:
                            _isBusy ? null : () => _performGetFactorCode(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('next'.tr),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            2 => Column(
                key: const ValueKey<int>(2),
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child:
                        Image.asset('assets/logo.png', width: 64, height: 64),
                  ).paddingOnly(bottom: 8, left: 4),
                  Text(
                    'signinEnterPassword'.tr,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ).paddingOnly(left: 4, bottom: 16),
                  TextField(
                    autocorrect: false,
                    enableSuggestions: false,
                    controller: _passwordController,
                    obscureText: true,
                    autofillHints: [
                      (_factorLabelMap[_factorPickedType]?.$3 ?? true)
                          ? AutofillHints.password
                          : AutofillHints.oneTimeCode
                    ],
                    decoration: InputDecoration(
                      isDense: true,
                      border: const OutlineInputBorder(),
                      labelText:
                          (_factorLabelMap[_factorPickedType]?.$3 ?? true)
                              ? 'passwordOneTime'.tr
                              : 'password'.tr,
                      helperText:
                          (_factorLabelMap[_factorPickedType]?.$3 ?? true)
                              ? 'passwordOneTimeInputHint'.tr
                              : 'passwordInputHint'.tr,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onSubmitted: _isBusy ? null : (_) => _performCheckTicket(),
                  ),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _isBusy ? null : () => _previousStep(),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.grey),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.chevron_left),
                            Text('prev'.tr),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: _isBusy ? null : () => _performCheckTicket(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('next'.tr),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            _ => Column(
                key: const ValueKey<int>(0),
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(8)),
                    child:
                        Image.asset('assets/logo.png', width: 64, height: 64),
                  ).paddingOnly(bottom: 8, left: 4),
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
                      helperText: 'usernameInputHint'.tr,
                    ),
                    onTapOutside: (_) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    onSubmitted: _isBusy ? null : (_) => _performNewTicket(),
                  ),
                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed:
                            _isBusy ? null : () => _requestResetPassword(),
                        style:
                            TextButton.styleFrom(foregroundColor: Colors.grey),
                        child: Text('forgotPassword'.tr),
                      ),
                      TextButton(
                        onPressed: _isBusy ? null : () => _performNewTicket(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('next'.tr),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          },
        ),
      ),
    );
  }
}
