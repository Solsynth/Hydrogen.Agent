import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class ChatCallButton extends StatefulWidget {
  final Realm? realm;
  final Channel channel;
  final Call? ongoingCall;
  final Function? onStarted;
  final Function? onEnded;

  const ChatCallButton({
    super.key,
    required this.realm,
    required this.channel,
    required this.ongoingCall,
    this.onStarted,
    this.onEnded,
  });

  @override
  State<ChatCallButton> createState() => _ChatCallButtonState();
}

class _ChatCallButtonState extends State<ChatCallButton> {
  bool _isBusy = false;

  Future<void> makeCall() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    setState(() => _isBusy = true);

    final scope = (widget.realm?.alias.isNotEmpty ?? false)
        ? widget.realm?.alias
        : 'global';
    final resp = await client.post(
      '/api/channels/$scope/${widget.channel.alias}/calls',
      {},
    );
    if (resp.statusCode == 200) {
      if (widget.onStarted != null) widget.onStarted!();
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isBusy = false);
  }

  Future<void> endsCall() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    setState(() => _isBusy = true);

    final scope = (widget.realm?.alias.isNotEmpty ?? false)
        ? widget.realm?.alias
        : 'global';
    final resp = await client
        .delete('/api/channels/${scope}/${widget.channel.alias}/calls/ongoing');
    if (resp.statusCode == 200) {
      if (widget.onEnded != null) widget.onEnded!();
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _isBusy
          ? null
          : widget.ongoingCall == null
              ? makeCall
              : endsCall,
      icon: widget.ongoingCall == null
          ? const Icon(Icons.call)
          : const Icon(Icons.call_end),
    );
  }
}
