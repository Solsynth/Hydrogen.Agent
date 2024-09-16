import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/widgets/attachments/attachment_editor.dart';

class AttachmentEditorThumbnailDialog extends StatefulWidget {
  final Attachment item;
  final String pool;
  final String? initialItem;
  final Function(String? id) onUpdate;

  const AttachmentEditorThumbnailDialog({
    super.key,
    required this.item,
    required this.pool,
    required this.initialItem,
    required this.onUpdate,
  });

  @override
  State<AttachmentEditorThumbnailDialog> createState() =>
      _AttachmentEditorThumbnailDialogState();
}

class _AttachmentEditorThumbnailDialogState
    extends State<AttachmentEditorThumbnailDialog> {
  bool _isLoading = false;

  final TextEditingController _attachmentController = TextEditingController();

  void _promptUploadNewAttachment() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentEditorPopup(
        pool: widget.pool,
        singleMode: true,
        imageOnly: true,
        autoUpload: true,
        onAdd: (value) {
          widget.onUpdate(value);
          _attachmentController.text = value;
        },
        initialAttachments: const [],
        onRemove: (_) {},
      ),
    );
  }

  Future<void> _updateAttachment() async {
    setState(() => _isLoading = true);

    final AttachmentProvider attach = Get.find();

    widget.item.metadata ??= {};
    if (_attachmentController.text.isNotEmpty) {
      widget.item.metadata!['thumbnail'] = _attachmentController.text;
    } else {
      widget.item.metadata!['thumbnail'] = null;
    }

    try {
      await attach.updateAttachment(
        widget.item.id,
        widget.item.alt,
        isMature: widget.item.isMature,
        metadata: widget.item.metadata!,
      );

      Get.find<AttachmentProvider>().clearCache(id: widget.item.rid);
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    if (widget.initialItem != null) {
      _attachmentController.text = widget.initialItem!;
    }
    super.initState();
  }

  @override
  void dispose() {
    _attachmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('attachmentThumbnail'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              title: Text('attachmentThumbnailAttachmentNew'.tr),
              contentPadding: const EdgeInsets.only(left: 12, right: 9),
              trailing: const Icon(Icons.chevron_right),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              onTap: () {
                _promptUploadNewAttachment();
              },
            ),
          ),
          const Row(children: <Widget>[
            Expanded(child: Divider()),
            Text('OR'),
            Expanded(child: Divider()),
          ]).paddingOnly(top: 12, bottom: 16, left: 16, right: 16),
          TextField(
            controller: _attachmentController,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              prefixText: '#',
              labelText: 'attachmentThumbnailAttachment'.tr,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  _updateAttachment().then((_) {
                    widget.onUpdate(_attachmentController.text);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  });
                },
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
