import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/post_editor_controller.dart';
import 'package:solian/widgets/attachments/attachment_editor.dart';

class PostEditorThumbnailDialog extends StatefulWidget {
  final PostEditorController controller;

  const PostEditorThumbnailDialog({super.key, required this.controller});

  @override
  State<PostEditorThumbnailDialog> createState() =>
      _PostEditorThumbnailDialogState();
}

class _PostEditorThumbnailDialogState extends State<PostEditorThumbnailDialog> {
  final TextEditingController _attachmentController = TextEditingController();

  void _promptUploadNewAttachment() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentEditorPopup(
        pool: 'interactive',
        singleMode: true,
        imageOnly: true,
        autoUpload: true,
        onAdd: (value) {
          setState(() {
            _attachmentController.text = value.toString();
          });

          widget.controller.thumbnail.value = value;
        },
        initialAttachments: const [],
        onRemove: (_) {},
      ),
    );
  }

  @override
  void initState() {
    _attachmentController.text =
        widget.controller.thumbnail.value?.toString() ?? '';
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
      title: Text('postThumbnail'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('postThumbnailAttachmentNew'.tr),
            contentPadding: const EdgeInsets.only(left: 16, right: 13),
            trailing: const Icon(Icons.chevron_right),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8)),
            ),
            onTap: () {
              _promptUploadNewAttachment();
            },
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _attachmentController,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              prefixText: '#',
              labelText: 'postThumbnailAttachment'.tr,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.controller.thumbnail.value = _attachmentController.text;
            Navigator.pop(context);
          },
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
