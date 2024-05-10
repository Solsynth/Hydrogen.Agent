import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/utils/services_url.dart';
import 'package:solian/widgets/exts.dart';

class RealmDeletion extends StatefulWidget {
  final Realm realm;
  final bool isOwned;

  const RealmDeletion({
    super.key,
    required this.realm,
    required this.isOwned,
  });

  @override
  State<RealmDeletion> createState() => _RealmDeletionState();
}

class _RealmDeletionState extends State<RealmDeletion> {
  bool _isSubmitting = false;

  Future<void> deleteChannel() async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var res = await auth.client!.delete(
      getRequestUri('passport', '/api/realms/${widget.realm.alias}'),
    );
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> leaveChannel() async {
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    if (!await auth.isAuthorized()) {
      setState(() => _isSubmitting = false);
      return;
    }

    var res = await auth.client!.delete(
      getRequestUri('passport', '/api/realms/${widget.realm.alias}/members/me'),
    );
    if (res.statusCode != 200) {
      var message = utf8.decode(res.bodyBytes);
      context.showErrorDialog(message);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.isOwned
        ? AppLocalizations.of(context)!.chatChannelDeleteConfirm
        : AppLocalizations.of(context)!.chatChannelLeaveConfirm;

    return AlertDialog(
      title: Text(AppLocalizations.of(context)!.confirmation),
      content: Text(content),
      actions: <Widget>[
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.confirmCancel),
        ),
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  if (widget.isOwned) {
                    deleteChannel();
                  } else {
                    leaveChannel();
                  }
                },
          child: Text(AppLocalizations.of(context)!.confirmOkay),
        ),
      ],
    );
  }
}
