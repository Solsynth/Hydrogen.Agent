import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/services_url.dart';
import 'package:solian/widgets/exts.dart';

class ChannelCallAction extends StatefulWidget {
  final Call? call;
  final Channel channel;
  final String realm;
  final Function onUpdate;

  const ChannelCallAction({
    super.key,
    this.call,
    required this.channel,
    required this.onUpdate,
    this.realm = 'global',
  });

  @override
  State<ChannelCallAction> createState() => _ChannelCallActionState();
}

class _ChannelCallActionState extends State<ChannelCallAction> {
  bool _isSubmitting = false;

  Future<void> makeCall() async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var uri = getRequestUri('messaging', '/api/channels/${widget.realm}/${widget.channel.alias}/calls');

    var res = await auth.client!.post(uri);
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> endsCall() async {
    setState(() => _isSubmitting = true);

    final chat = context.read<ChatProvider>();
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var uri = getRequestUri('messaging', '/api/channels/${widget.realm}/${widget.channel.alias}/calls/ongoing');

    var res = await auth.client!.delete(uri);
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    } else {
      if (chat.currentCall != null && chat.currentCall?.info.channelId == widget.channel.id) {
        chat.currentCall!.deactivate();
        chat.currentCall!.dispose();
      }
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isSubmitting
          ? null
          : () {
              if (widget.call == null) {
                makeCall();
              } else {
                endsCall();
              }
            },
      icon: widget.call == null ? const Icon(Icons.call) : const Icon(Icons.call_end),
    );
  }
}

class ChannelManageAction extends StatelessWidget {
  final Channel channel;
  final Function onUpdate;
  final String realm;

  const ChannelManageAction({
    super.key,
    required this.channel,
    required this.onUpdate,
    this.realm = 'global',
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final result = await SolianRouter.router.pushNamed(
          realm == 'global' ? 'chat.channel.manage' : 'realms.chat.channel.manage',
          extra: channel,
          pathParameters: {
            'channel': channel.alias,
            ...(realm == 'global' ? {} : {'realm': realm}),
          },
        );
        switch (result) {
          case 'disposed':
            if (SolianRouter.router.canPop()) SolianRouter.router.pop('refresh');
          case 'refresh':
            onUpdate();
        }
      },
      icon: const Icon(Icons.settings),
    );
  }
}
