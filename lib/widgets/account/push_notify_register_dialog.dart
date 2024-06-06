import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/account.dart';

class PushNotifyRegisterDialog extends StatefulWidget {
  const PushNotifyRegisterDialog({super.key});

  @override
  State<PushNotifyRegisterDialog> createState() =>
      _PushNotifyRegisterDialogState();
}

class _PushNotifyRegisterDialogState extends State<PushNotifyRegisterDialog> {
  bool _isBusy = false;

  void performAction() async {
    setState(() => _isBusy = true);

    try {
      await Get.find<AccountProvider>().registerPushNotifications();
      context.showSnackbar('pushNotifyRegisterDone'.tr);
      Navigator.pop(context);
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('pushNotifyRegister'.tr),
      content: Text('pushNotifyRegisterCaption'.tr),
      actions: [
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context),
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
