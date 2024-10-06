import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:get/get_connect/http/src/exceptions/exceptions.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/root_container.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _isBusy = true;

  Map<String, bool> _config = {};

  final Map<String, String> _topicMap = {
    'interactive.feedback': 'notificationTopicPostFeedback'.tr,
    'interactive.subscription': 'notificationTopicPostSubscription'.tr,
  };

  Future<void> _getPreferences() async {
    setState(() => _isBusy = true);

    final auth = Get.find<AuthProvider>();
    if (!auth.isAuthorized.value) throw UnauthorizedException();

    final client = await auth.configureClient('id');
    final resp = await client.get('/preferences/notifications');
    if (resp.statusCode != 200 && resp.statusCode != 404) {
      context.showErrorDialog(RequestException(resp));
    }

    if (resp.statusCode == 200) {
      _config = resp.body['config']
          .map((k, v) => MapEntry(k, v as bool))
          .cast<String, bool>();
    }

    setState(() => _isBusy = false);
  }

  Future<void> _savePreferences() async {
    setState(() => _isBusy = true);

    final auth = Get.find<AuthProvider>();
    if (!auth.isAuthorized.value) throw UnauthorizedException();

    final client = await auth.configureClient('id');
    final resp = await client.put('/preferences/notifications', {
      'config': _config,
    });
    if (resp.statusCode != 200) {
      context.showErrorDialog(RequestException(resp));
    }

    context.showSnackbar('preferencesApplied'.tr);

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();
    _getPreferences();
  }

  @override
  Widget build(BuildContext context) {
    return RootContainer(
      child: Column(
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
            child: ListView.builder(
              itemCount: _topicMap.length,
              itemBuilder: (context, index) {
                final element = _topicMap.entries.elementAt(index);
                return CheckboxListTile(
                  title: Text(element.value),
                  subtitle: Text(
                    element.key,
                    style: GoogleFonts.robotoMono(fontSize: 12),
                  ),
                  value: _config[element.key] ?? true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  onChanged: (value) {
                    setState(() {
                      _config[element.key] = value ?? false;
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
