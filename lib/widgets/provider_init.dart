import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/providers/keypair.dart';
import 'package:solian/providers/notify.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/widgets/exts.dart';

class ProviderInitializer extends StatefulWidget {
  final Widget child;

  const ProviderInitializer({super.key, required this.child});

  @override
  State<ProviderInitializer> createState() => _ProviderInitializerState();
}

class _ProviderInitializerState extends State<ProviderInitializer> {
  void showConnectionStatus(bool status) {
    if (status) {
      showConnectionSnackbar();
    } else {
      ScaffoldMessenger.of(context).clearSnackBars();
    }
  }

  void showConnectionSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(AppLocalizations.of(context)!.connectingServer),
      duration: const Duration(minutes: 1),
    ));
  }

  void connect() async {
    final auth = context.read<AuthProvider>();
    final nty = context.read<NotifyProvider>();
    final chat = context.read<ChatProvider>();
    final keypair = context.read<KeypairProvider>();

    final notify = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.connectingServer),
        duration: const Duration(seconds: 3),
      ),
    );

    try {
      if (await auth.isAuthorized()) {
        if (auth.client == null) {
          await auth.loadClient();
        }

        nty.connect(
          auth,
          onKexRequest: keypair.provideKeypair,
          onKexProvide: keypair.receiveKeypair,
            onStateUpdated: showConnectionStatus
        ).then((value) {
          keypair.channel = value;
        });
        chat.connect(auth, onStateUpdated: showConnectionStatus);

        nty.fetch(auth);

        Timer.periodic(const Duration(seconds: 1), (timer) {
          nty.connect(auth, onStateUpdated: showConnectionStatus);
          chat.connect(auth, onStateUpdated: showConnectionStatus);
        });
      }
    } catch (e) {
      context.showErrorDialog(e);
    }

    notify.close();
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () => connect());
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
