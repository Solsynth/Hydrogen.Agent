import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/message.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';
import 'package:solian/widgets/exts.dart';

class ChatMessageDeletionDialog extends StatefulWidget {
  final String channel;
  final Message item;

  const ChatMessageDeletionDialog({
    super.key,
    required this.item,
    required this.channel,
  });

  @override
  State<ChatMessageDeletionDialog> createState() =>
      _ChatMessageDeletionDialogState();
}

class _ChatMessageDeletionDialogState extends State<ChatMessageDeletionDialog> {
  bool _isSubmitting = false;

  void doDeletion(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final uri = getRequestUri('messaging',
        '/api/channels/global/${widget.channel}/messages/${widget.item.id}');

    setState(() => _isSubmitting = true);
    final res = await auth.client!.delete(uri);
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
      setState(() => _isSubmitting = false);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.confirmation),
      content: Text(AppLocalizations.of(context)!.chatMessageDeleteConfirm),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context, false),
          child: Text(AppLocalizations.of(context)!.confirmCancel),
        ),
        TextButton(
          onPressed: _isSubmitting ? null : () => doDeletion(context),
          child: Text(AppLocalizations.of(context)!.confirmOkay),
        ),
      ],
    );
  }
}
