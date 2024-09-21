import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/exceptions/request.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';

class AbuseReportDialog extends StatefulWidget {
  final String? resourceId;

  const AbuseReportDialog({super.key, this.resourceId});

  @override
  State<AbuseReportDialog> createState() => _AbuseReportDialogState();
}

class _AbuseReportDialogState extends State<AbuseReportDialog> {
  final TextEditingController _resourceController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  bool _isBusy = false;

  Future<void> _submit() async {
    final auth = Get.find<AuthProvider>();
    if (!auth.isAuthorized.value) return;
    final client = await auth.configureClient('id');

    setState(() => _isBusy = true);

    final resp = await client.post('/reports/abuse', {
      'resource': _resourceController.text,
      'reason': _reasonController.text,
    });

    setState(() => _isBusy = false);

    if (resp.statusCode != 200) {
      context.showErrorDialog(RequestException(resp));
    } else {
      context.showSnackbar('reportSubmitted'.tr);
      Navigator.pop(context, true);
    }
  }

  @override
  void initState() {
    if (widget.resourceId != null) {
      _resourceController.text = widget.resourceId!;
    }
    super.initState();
  }

  @override
  void dispose() {
    _resourceController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('reportAbuse'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Gap(4),
          TextField(
            controller: _resourceController,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'reportAbuseResource'.tr,
              enabled: widget.resourceId == null,
              isDense: true,
            ),
          ),
          const Gap(12),
          TextField(
            controller: _reasonController,
            textInputAction: TextInputAction.newline,
            minLines: 1,
            maxLines: 3,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'reportAbuseReason'.tr,
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isBusy
              ? null
              : () {
                  Navigator.pop(context);
                },
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: _isBusy ? null : () => _submit(),
          child: Text('okay'.tr),
        ),
      ],
    );
  }
}
