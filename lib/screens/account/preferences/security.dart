import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/exceptions/exceptions.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';

class AuthPreferencesScreen extends StatefulWidget {
  const AuthPreferencesScreen({super.key});

  @override
  State<AuthPreferencesScreen> createState() => _AuthPreferencesScreenState();
}

class _AuthPreferencesScreenState extends State<AuthPreferencesScreen> {
  bool _isBusy = true;

  Map<String, dynamic> _config = {
    'maximum_auth_steps': 2,
  };

  Future<void> _getPreferences() async {
    setState(() => _isBusy = true);

    final auth = Get.find<AuthProvider>();
    if (!auth.isAuthorized.value) throw UnauthorizedException();

    final client = await auth.configureClient('id');
    final resp = await client.get('/preferences/auth');
    if (resp.statusCode != 200 && resp.statusCode != 404) {
      context.showErrorDialog(RequestException(resp));
    }

    if (resp.statusCode == 200) {
      _config = resp.body;
    }

    setState(() => _isBusy = false);
  }

  Future<void> _savePreferences() async {
    setState(() => _isBusy = true);

    final auth = Get.find<AuthProvider>();
    if (!auth.isAuthorized.value) throw UnauthorizedException();

    final client = await auth.configureClient('id');
    final resp = await client.put('/preferences/auth', _config);
    if (resp.statusCode != 200) {
      context.showErrorDialog(RequestException(resp));
    } else {
      context.showSnackbar('preferencesApplied'.tr);
    }

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();
    _getPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
        ListTile(
          tileColor: Theme.of(context).colorScheme.surfaceContainer,
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: const Icon(Icons.save),
          title: Text('save'.tr),
          enabled: !_isBusy,
          onTap: () {
            _savePreferences();
          },
        ),
        Expanded(
          child: ListView(
            children: [
              ListTile(
                title: Text('authMaximumAuthSteps'.tr),
                subtitle: Text('authMaximumAuthStepsDesc'.tr),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                trailing: SizedBox(
                  width: 60,
                  child: _isBusy
                      ? null
                      : TextFormField(
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                          initialValue:
                              _config['maximum_auth_steps']?.toString() ?? '2',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onTapOutside: (_) =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          onChanged: (value) {
                            _config['maximum_auth_steps'] =
                                int.tryParse(value) ?? 2;
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
