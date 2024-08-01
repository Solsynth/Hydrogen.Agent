import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' show basename;
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/widgets/attachments/attachment_fullscreen.dart';
import 'package:solian/widgets/attachments/attachment_item.dart';

class AttachmentEditorPopup extends StatefulWidget {
  final String usage;
  final List<int> current;
  final void Function(List<int> data) onUpdate;

  const AttachmentEditorPopup({
    super.key,
    required this.usage,
    required this.current,
    required this.onUpdate,
  });

  @override
  State<AttachmentEditorPopup> createState() => _AttachmentEditorPopupState();
}

class _AttachmentEditorPopupState extends State<AttachmentEditorPopup> {
  final _imagePicker = ImagePicker();

  bool _isBusy = false;
  bool _isFirstTimeBusy = true;

  List<Attachment?> _attachments = List.empty(growable: true);

  Future<void> _pickPhotoToUpload() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final medias = await _imagePicker.pickMultiImage();
    if (medias.isEmpty) return;

    setState(() => _isBusy = true);

    for (final media in medias) {
      final file = File(media.path);
      try {
        await _uploadAttachment(
          await file.readAsBytes(),
          file.path,
          null,
        );
      } catch (err) {
        context.showErrorDialog(err);
      }
    }

    setState(() => _isBusy = false);
  }

  Future<void> _pickVideoToUpload() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final media = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (media == null) return;

    setState(() => _isBusy = true);

    final file = File(media.path);

    try {
      await _uploadAttachment(await file.readAsBytes(), file.path, null);
    } catch (err) {
      context.showErrorDialog(err);
    }

    setState(() => _isBusy = false);
  }

  Future<void> _pickFileToUpload() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result == null) return;

    setState(() => _isBusy = true);

    List<File> files = result.paths.map((path) => File(path!)).toList();

    for (final file in files) {
      try {
        await _uploadAttachment(await file.readAsBytes(), file.path, null);
      } catch (err) {
        context.showErrorDialog(err);
      }
    }

    setState(() => _isBusy = false);
  }

  Future<void> _takeMediaToUpload(bool isVideo) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    XFile? media;
    if (isVideo) {
      media = await _imagePicker.pickVideo(source: ImageSource.camera);
    } else {
      media = await _imagePicker.pickImage(source: ImageSource.camera);
    }
    if (media == null) return;

    setState(() => _isBusy = true);

    final file = File(media.path);
    try {
      await _uploadAttachment(await file.readAsBytes(), file.path, null);
    } catch (err) {
      context.showErrorDialog(err);
    }

    setState(() => _isBusy = false);
  }

  void _pasteFileToUpload() async {
    final data = await Pasteboard.image;
    if (data == null) return;

    setState(() => _isBusy = true);

    _uploadAttachment(data, 'Pasted Image', null);

    setState(() => _isBusy = false);
  }

  Future<void> _uploadAttachment(
      Uint8List data, String path, Map<String, dynamic>? metadata) async {
    final AttachmentProvider provider = Get.find();
    try {
      context.showSnackbar((PlatformInfo.isWeb
              ? 'attachmentUploadingWebMode'
              : 'attachmentUploading')
          .trParams({'name': basename(path)}));
      final resp = await provider.createAttachment(
        data,
        path,
        widget.usage,
        metadata,
      );
      var result = Attachment.fromJson(resp.body);
      setState(() => _attachments.add(result));
      widget.onUpdate(_attachments.map((e) => e!.id).toList());
      context.clearSnackbar();
    } catch (err) {
      rethrow;
    }
  }

  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    final dm = decimals < 0 ? 0 : decimals;
    final sizes = [
      'Bytes',
      'KiB',
      'MiB',
      'GiB',
      'TiB',
      'PiB',
      'EiB',
      'ZiB',
      'YiB'
    ];
    final i = (math.log(bytes) / math.log(k)).floor().toInt();
    return '${(bytes / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
  }

  void _revertMetadataList() {
    final AttachmentProvider provider = Get.find();

    if (widget.current.isEmpty) {
      _isFirstTimeBusy = false;
      return;
    } else {
      _attachments = List.filled(widget.current.length, null);
    }

    setState(() => _isBusy = true);

    int progress = 0;
    for (var idx = 0; idx < widget.current.length; idx++) {
      provider.getMetadata(widget.current[idx]).then((resp) {
        progress++;
        _attachments[idx] = resp;
        if (progress == widget.current.length) {
          setState(() {
            _isBusy = false;
            _isFirstTimeBusy = false;
          });
        }
      });
    }
  }

  void _showAttachmentPreview(Attachment element) {
    context.pushTransparentRoute(
      AttachmentFullScreen(
        parentId: 'attachment-editor-preview',
        item: element,
      ),
      rootNavigator: true,
    );
  }

  void _showEdit(Attachment element, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AttachmentEditorDialog(
          item: element,
          onDelete: () {
            setState(() => _attachments.removeAt(index));
            widget.onUpdate(_attachments.map((e) => e!.id).toList());
          },
          onUpdate: (item) {
            setState(() => _attachments[index] = item);
            widget.onUpdate(_attachments.map((e) => e!.id).toList());
          },
        );
      },
    );
  }

  Widget _buildListEntry(Attachment element, int index) {
    var fileType = element.mimetype.split('/').firstOrNull;
    fileType ??= 'unknown';

    final canBePreview = fileType.toLowerCase() == 'image';

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 8, bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          children: [
            SizedBox(
              height: 54,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          element.alt,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace'),
                        ),
                        Text(
                          '${fileType[0].toUpperCase()}${fileType.substring(1)} · ${_formatBytes(element.size)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    color: Colors.teal,
                    icon: const Icon(Icons.preview),
                    visualDensity: const VisualDensity(horizontal: -4),
                    onPressed: canBePreview
                        ? () => _showAttachmentPreview(element)
                        : null,
                  ),
                  IconButton(
                    color: Theme.of(context).colorScheme.primary,
                    visualDensity: const VisualDensity(horizontal: -4),
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () => _showEdit(element, index),
                  ),
                ],
              ).paddingSymmetric(vertical: 8, horizontal: 16),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _revertMetadataList();
  }

  @override
  Widget build(BuildContext context) {
    const density = VisualDensity(horizontal: 0, vertical: 0);

    return SafeArea(
      child: DropTarget(
        onDragDone: (detail) async {
          setState(() => _isBusy = true);
          for (final file in detail.files) {
            final data = await file.readAsBytes();
            _uploadAttachment(data, file.path, null);
          }
          setState(() => _isBusy = false);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'attachmentAdd'.tr,
              style: Theme.of(context).textTheme.headlineSmall,
            ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
            if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
            Expanded(
              child: Builder(builder: (context) {
                if (_isFirstTimeBusy && _isBusy) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return ListView.builder(
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final element = _attachments[index];
                    return _buildListEntry(element!, index);
                  },
                );
              }),
            ),
            const Divider(thickness: 0.3, height: 0.3),
            SizedBox(
              height: 64,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  alignment: WrapAlignment.center,
                  runAlignment: WrapAlignment.center,
                  children: [
                    if (PlatformInfo.isDesktop ||
                        PlatformInfo.isIOS ||
                        PlatformInfo.isWeb)
                      ElevatedButton.icon(
                        icon: const Icon(Icons.paste),
                        label: Text('attachmentAddClipboard'.tr),
                        style: const ButtonStyle(visualDensity: density),
                        onPressed: () => _pasteFileToUpload(),
                      ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text('attachmentAddGalleryPhoto'.tr),
                      style: const ButtonStyle(visualDensity: density),
                      onPressed: () => _pickPhotoToUpload(),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_road),
                      label: Text('attachmentAddGalleryVideo'.tr),
                      style: const ButtonStyle(visualDensity: density),
                      onPressed: () => _pickVideoToUpload(),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.photo_camera_back),
                      label: Text('attachmentAddCameraPhoto'.tr),
                      style: const ButtonStyle(visualDensity: density),
                      onPressed: () => _takeMediaToUpload(false),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.video_camera_back_outlined),
                      label: Text('attachmentAddCameraVideo'.tr),
                      style: const ButtonStyle(visualDensity: density),
                      onPressed: () => _takeMediaToUpload(true),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.file_present_rounded),
                      label: Text('attachmentAddFile'.tr),
                      style: const ButtonStyle(visualDensity: density),
                      onPressed: () => _pickFileToUpload(),
                    ),
                  ],
                ).paddingSymmetric(horizontal: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class AttachmentEditorDialog extends StatefulWidget {
  final Attachment item;
  final Function onDelete;
  final Function(Attachment item) onUpdate;

  const AttachmentEditorDialog(
      {super.key,
      required this.item,
      required this.onDelete,
      required this.onUpdate});

  @override
  State<AttachmentEditorDialog> createState() => _AttachmentEditorDialogState();
}

class _AttachmentEditorDialogState extends State<AttachmentEditorDialog> {
  final _altController = TextEditingController();

  bool _isBusy = false;
  bool _isMature = false;

  Future<Attachment?> updateAttachment() async {
    final AttachmentProvider provider = Get.find();

    setState(() => _isBusy = true);
    try {
      final resp = await provider.updateAttachment(
        widget.item.id,
        _altController.value.text,
        widget.item.usage,
        isMature: _isMature,
      );

      Get.find<AttachmentProvider>().clearCache(id: widget.item.id);

      setState(() => _isBusy = false);
      return Attachment.fromJson(resp.body);
    } catch (e) {
      context.showErrorDialog(e);

      setState(() => _isBusy = false);
      return null;
    }
  }

  Future<void> deleteAttachment() async {
    setState(() => _isBusy = true);
    try {
      final AttachmentProvider provider = Get.find();
      await provider.deleteAttachment(widget.item.id);
      widget.onDelete();
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      setState(() => _isBusy = false);
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
            Card(
              child: CheckboxListTile(
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
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: <Widget>[
        TextButton(
          style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error),
          onPressed: () {
            deleteAttachment().then((_) {
              Navigator.pop(context);
            });
          },
          child: Text('delete'.tr),
        ),
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
                updateAttachment().then((value) {
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
