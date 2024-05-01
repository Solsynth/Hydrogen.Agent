import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ChatMaintainer extends StatefulWidget {
  final Widget child;
  final Channel channel;
  final Function(Message val) onInsertMessage;
  final Function(Message val) onUpdateMessage;
  final Function(Message val) onDeleteMessage;
  final Function(Call val) onCallStarted;
  final Function() onCallEnded;

  const ChatMaintainer({
    super.key,
    required this.child,
    required this.channel,
    required this.onInsertMessage,
    required this.onUpdateMessage,
    required this.onDeleteMessage,
    required this.onCallStarted,
    required this.onCallEnded,
  });

  @override
  State<ChatMaintainer> createState() => _ChatMaintainerState();
}

class _ChatMaintainerState extends State<ChatMaintainer> {
  void connect() {
    ScaffoldMessenger.of(context).clearSnackBars();

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
              final payload = Message.fromJson(result.payload!);
              if (payload.channelId == widget.channel.id)
                widget.onInsertMessage(payload);
              break;
            case 'messages.update':
              final payload = Message.fromJson(result.payload!);
              if (payload.channelId == widget.channel.id)
                widget.onUpdateMessage(payload);
              break;
            case 'messages.burnt':
              final payload = Message.fromJson(result.payload!);
              if (payload.channelId == widget.channel.id)
                widget.onDeleteMessage(payload);
              break;
            case 'calls.new':
              final payload = Call.fromJson(result.payload!);
              if (payload.channelId == widget.channel.id)
                widget.onCallStarted(payload);
              break;
            case 'calls.end':
              final payload = Call.fromJson(result.payload!);
              if (payload.channelId == widget.channel.id) widget.onCallEnded();
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
    return widget.child;
  }
}
