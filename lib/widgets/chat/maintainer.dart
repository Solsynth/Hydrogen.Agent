import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';

class ChatMaintainer extends StatefulWidget {
  final Widget child;
  final Function(Message val) onNewMessage;

  const ChatMaintainer({super.key, required this.child, required this.onNewMessage});

  @override
  State<ChatMaintainer> createState() => _ChatMaintainerState();
}

class _ChatMaintainerState extends State<ChatMaintainer> {
  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      final auth = context.read<AuthProvider>();
      final chat = context.read<ChatProvider>();

      chat.connect(auth).then((snapshot) {
        snapshot!.stream.listen((event) {
          final result = NetworkPackage.fromJson(jsonDecode(event));
          switch (result.method) {
            case 'messages.new':
              widget.onNewMessage(Message.fromJson(result.payload!));
          }
        });
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
