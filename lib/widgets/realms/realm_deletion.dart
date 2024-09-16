import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';

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

  Future<void> deleteRealm() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    setState(() => _isBusy = true);

    final client = await auth.configureClient('auth');

    final resp = await client.delete('/realms/${widget.realm.id}');
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context, 'OK');
    }

    setState(() => _isBusy = false);
  }

  Future<void> leaveRealm() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    setState(() => _isBusy = true);

    final client = await auth.configureClient('auth');

    final resp = await client.delete('/realms/${widget.realm.id}/members/me');
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
      title: Text(widget.isOwned
          ? 'realmDeletionConfirm'.tr
          : 'channelLeaveConfirm'.tr),
      content: Text(
        widget.isOwned
            ? 'realmDeletionConfirmCaption'
                .trParams({'realm': '#${widget.realm.alias}'})
            : 'realmLeaveConfirmCaption'
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
                  ? deleteRealm
                  : leaveRealm,
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
