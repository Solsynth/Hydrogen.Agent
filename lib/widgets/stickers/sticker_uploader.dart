import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/attachments/attachment_editor.dart';

class StickerUploadDialog extends StatefulWidget {
  const StickerUploadDialog({super.key});

  @override
  State<StickerUploadDialog> createState() => _StickerUploadDialogState();
}

class _StickerUploadDialogState extends State<StickerUploadDialog> {
  final TextEditingController _attachmentController = TextEditingController();
  final TextEditingController _packController = TextEditingController();
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  bool _isBusy = false;

  void _promptUploadNewAttachment() {
    showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentEditorPopup(
        usage: 'sticker',
        singleMode: true,
        imageOnly: true,
        autoUpload: true,
        imageMaxHeight: 28,
        imageMaxWidth: 28,
        onAdd: (value) {
          setState(() {
            _attachmentController.text = value.toString();
          });
        },
        initialAttachments: const [],
        onRemove: (_) {},
      ),
    );
  }

  Future<void> _applySticker() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    if ([
      _nameController.text.isEmpty,
      _aliasController.text.isEmpty,
      _packController.text.isEmpty,
      _attachmentController.text.isEmpty,
    ].any((x) => x)) {
      return;
    }

    final client = auth.configureClient('files');
    final resp = await client.post('/stickers', {
      'name': _nameController.text,
      'alias': _aliasController.text,
      'pack_id': int.tryParse(_packController.text),
      'attachment_id': int.tryParse(_attachmentController.text),
    });

    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _attachmentController.dispose();
    _packController.dispose();
    _aliasController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('stickerUploader'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text('stickerUploaderAttachmentNew'.tr),
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
              labelText: 'stickerUploaderAttachment'.tr,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _packController,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              prefixText: '#',
              labelText: 'stickerUploaderPack'.tr,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          Container(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 6),
            child: Text(
              'stickerUploaderPackHint'.tr,
              style: TextStyle(color: _unFocusColor),
            ),
          ),
          TextField(
            controller: _aliasController,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              labelText: 'stickerUploaderAlias'.tr,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          Container(
            padding:
                const EdgeInsets.only(left: 8, right: 8, top: 4, bottom: 6),
            child: Text(
              'stickerUploaderAliasHint'.tr,
              style: TextStyle(color: _unFocusColor),
            ),
          ),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              labelText: 'stickerUploaderName'.tr,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          Container(
            padding: const EdgeInsets.only(left: 8, right: 8, top: 4),
            child: Text(
              'stickerUploaderNameHint'.tr,
              style: TextStyle(color: _unFocusColor),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
            foregroundColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: _isBusy ? null : () => _applySticker(),
          child: Text('apply'.tr),
        ),
      ],
    );
  }
}
