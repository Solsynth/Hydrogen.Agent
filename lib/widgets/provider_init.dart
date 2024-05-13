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
  void connect() async {
    final auth = context.read<AuthProvider>();
    final nty = context.read<NotifyProvider>();
    final chat = context.read<ChatProvider>();
    final keypair = context.read<KeypairProvider>();

    final notify = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.connectingServer),
        duration: const Duration(minutes: 1),
      ),
    );

    try {
      if (await auth.isAuthorized()) {
        if (auth.client == null) {
          await auth.loadClient();
        }

        nty.fetch(auth);
        chat.connect(auth);
        keypair.channel = await nty.connect(
          auth,
          onKexRequest: keypair.provideKeypair,
          onKexProvide: keypair.receiveKeypair,
        );

        Timer.periodic(const Duration(seconds: 1), (timer) {
          nty.connect(auth);
          chat.connect(auth);
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
