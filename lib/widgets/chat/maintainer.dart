import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatMaintainer extends StatefulWidget {
  final Widget child;
  final Function(Message val) onInsertMessage;
  final Function(Message val) onUpdateMessage;
  final Function(Message val) onDeleteMessage;

  const ChatMaintainer({
    super.key,
    required this.child,
    required this.onInsertMessage,
    required this.onUpdateMessage,
    required this.onDeleteMessage,
  });

  @override
  State<ChatMaintainer> createState() => _ChatMaintainerState();
}

class _ChatMaintainerState extends State<ChatMaintainer> {
  void connect() {
    final notify = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.connectingServer),
        duration: const Duration(minutes: 1),
      ),
    );

    final auth = context.read<AuthProvider>();
    final chat = context.read<ChatProvider>();

    chat.connect(auth).then((snapshot) {
      snapshot!.stream.listen(
        (event) {
          final result = NetworkPackage.fromJson(jsonDecode(event));
          switch (result.method) {
            case 'messages.new':
              widget.onInsertMessage(Message.fromJson(result.payload!));
              break;
            case 'messages.update':
              widget.onUpdateMessage(Message.fromJson(result.payload!));
              break;
            case 'messages.burnt':
              widget.onDeleteMessage(Message.fromJson(result.payload!));
              break;
          }
        },
        onError: (_, __) => connect(),
        onDone: () => connect(),
      );

      notify.close();
    });
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      connect();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();

    return widget.child;
  }
}
