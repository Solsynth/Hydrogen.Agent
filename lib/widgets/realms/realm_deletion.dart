import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/services.dart';

class RealmDeletionDialog extends StatefulWidget {
  final Realm realm;
  final bool isOwned;

  const RealmDeletionDialog({
    super.key,
    required this.realm,
    required this.isOwned,
  });

  @override
  State<RealmDeletionDialog> createState() => _RealmDeletionDialogState();
}

class _RealmDeletionDialogState extends State<RealmDeletionDialog> {
  bool _isBusy = false;

  Future<void> deleteChannel() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    setState(() => _isBusy = true);

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp = await client.delete('/api/realms/${widget.realm.id}');
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

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['passport'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

    final resp =
        await client.delete('/api/realms/${widget.realm.id}/members/me');
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
      title: Text('realmDeletionConfirm'.tr),
      content: Text(
        'realmDeletionConfirmCaption'
            .trParams({'realm': '#${widget.realm.alias}'}),
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
