import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class ChannelDeletion extends StatefulWidget {
  final Channel channel;
  final String realm;
  final bool isOwned;

  const ChannelDeletion({
    super.key,
    required this.channel,
    required this.realm,
    required this.isOwned,
  });

  @override
  State<ChannelDeletion> createState() => _ChannelDeletionState();
}

class _ChannelDeletionState extends State<ChannelDeletion> {
  bool _isBusy = false;

  Future<void> deleteChannel() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    setState(() => _isBusy = true);

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client
        .delete('/api/channels/${widget.realm}/${widget.channel.id}');
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, 'OK');
    }

    setState(() => _isBusy = false);
  }

  Future<void> leaveChannel() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    setState(() => _isBusy = true);

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.delete(
      '/api/channels/${widget.realm}/${widget.channel.alias}/members/me',
    );
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, 'OK');
    }

    setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('channelDeletionConfirm'.tr),
      content: Text(
        'channelDeletionConfirmCaption'
            .trParams({'channel': '#${widget.channel.alias}'}),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: _isBusy
              ? null
              : widget.isOwned
                  ? deleteChannel
                  : leaveChannel,
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}