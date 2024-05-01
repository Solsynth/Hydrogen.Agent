import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/exts.dart';

class ChannelCallAction extends StatefulWidget {
  final Call? call;
  final Channel channel;
  final Function onUpdate;

  const ChannelCallAction(
      {super.key, this.call, required this.channel, required this.onUpdate});

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

    var uri = getRequestUri(
        'messaging', '/api/channels/${widget.channel.alias}/calls');

    var res = await auth.client!.post(uri);
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> endsCall() async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var uri = getRequestUri(
        'messaging', '/api/channels/${widget.channel.alias}/calls/ongoing');

    var res = await auth.client!.delete(uri);
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
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
      icon: widget.call == null
          ? const Icon(Icons.call)
          : const Icon(Icons.call_end),
    );
  }
}

class ChannelManageAction extends StatelessWidget {
  final Channel channel;
  final Function onUpdate;

  const ChannelManageAction(
      {super.key, required this.channel, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () async {
        final result = await router.pushNamed(
          'chat.channel.manage',
          extra: channel,
          pathParameters: {'channel': channel.alias},
        );
        switch (result) {
          case 'disposed':
            if (router.canPop()) router.pop('refresh');
          case 'refresh':
            onUpdate();
        }
      },
      icon: const Icon(Icons.settings),
    );
  }
}
