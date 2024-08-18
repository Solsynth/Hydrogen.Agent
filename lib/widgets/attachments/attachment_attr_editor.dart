import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/content/attachment.dart';

class AttachmentAttrEditorDialog extends StatefulWidget {
  final Attachment item;
  final Function(Attachment item) onUpdate;

  const AttachmentAttrEditorDialog({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  @override
  State<AttachmentAttrEditorDialog> createState() =>
      _AttachmentAttrEditorDialogState();
}

class _AttachmentAttrEditorDialogState
    extends State<AttachmentAttrEditorDialog> {
  final _altController = TextEditingController();

  bool _isBusy = false;
  bool _isMature = false;

  Future<Attachment?> _updateAttachment() async {
    final AttachmentProvider provider = Get.find();

    setState(() => _isBusy = true);
    try {
      final resp = await provider.updateAttachment(
        widget.item.id,
        _altController.value.text,
        isMature: _isMature,
      );

      Get.find<AttachmentProvider>().clearCache(id: widget.item.rid);

      setState(() => _isBusy = false);
      return Attachment.fromJson(resp.body);
    } catch (e) {
      context.showErrorDialog(e);
      setState(() => _isBusy = false);
      return null;
    }
  }

  void syncWidget() {
    _isMature = widget.item.isMature;
    _altController.text = widget.item.alt;
  }

  @override
  void initState() {
    syncWidget();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('attachmentSetting'.tr),
      content: Container(
        constraints: const BoxConstraints(minWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isBusy)
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: const LinearProgressIndicator().animate().scaleX(),
              ),
            const SizedBox(height: 18),
            TextField(
              controller: _altController,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.image_not_supported),
                border: const OutlineInputBorder(),
                labelText: 'attachmentAlt'.tr,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: const EdgeInsets.only(left: 4, right: 18),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10))),
              title: Text('matureContent'.tr),
              secondary: const Icon(Icons.visibility_off),
              value: _isMature,
              onChanged: (newValue) {
                setState(() => _isMature = newValue ?? false);
              },
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.onSurfaceVariant),
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr),
            ),
            TextButton(
              child: Text('apply'.tr),
              onPressed: () {
                _updateAttachment().then((value) {
                  if (value != null) {
                    widget.onUpdate(value);
                    Navigator.pop(context);
                  }
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
