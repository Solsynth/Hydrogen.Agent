import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/models/post.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/service_url.dart';

class ItemDeletionDialog extends StatefulWidget {
  final Post item;
  final String dataset;
  final Function? onDelete;

  const ItemDeletionDialog({
    super.key,
    required this.item,
    required this.dataset,
    this.onDelete,
  });

  @override
  State<ItemDeletionDialog> createState() => _ItemDeletionDialogState();
}

class _ItemDeletionDialogState extends State<ItemDeletionDialog> {
  bool _isSubmitting = false;

  void doDeletion(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) return;

    final uri =
        getRequestUri('interactive', '/api/p/moments/${widget.item.id}');

    setState(() => _isSubmitting = true);
    final res = await auth.client!.delete(uri);
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Something went wrong... $message")),
      );
      setState(() => _isSubmitting = false);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.confirmation),
      content: Text(AppLocalizations.of(context)!.postDeleteConfirm),
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
