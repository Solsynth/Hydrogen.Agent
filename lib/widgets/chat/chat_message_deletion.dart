import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';

class ChatMessageDeletionDialog extends StatefulWidget {
  final Channel channel;
  final Realm? realm;
  final Message item;

  const ChatMessageDeletionDialog({
    super.key,
    required this.channel,
    required this.realm,
    required this.item,
  });

  @override
  State<ChatMessageDeletionDialog> createState() =>
      _ChatMessageDeletionDialogState();
}

class _ChatMessageDeletionDialogState extends State<ChatMessageDeletionDialog> {
  bool _isBusy = false;

  void performAction() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = auth.configureClient(service: 'messaging');

    setState(() => _isBusy = true);

    final scope = (widget.realm?.alias.isNotEmpty ?? false)
        ? widget.realm?.alias
        : 'global';
    final resp = await client.delete(
      '/api/channels/$scope/${widget.channel.alias}/messages/${widget.item.id}',
    );
    if (resp.statusCode == 200) {
      Navigator.pop(context, resp.body);
    } else {
      context.showErrorDialog(resp.bodyString);
      setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('messageDeletionConfirm'.tr),
      content: Text('messageDeletionConfirmCaption'.trParams({
        'id': '#${widget.item.id}',
      })),
      actions: <Widget>[
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context, false),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: _isBusy ? null : performAction,
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
