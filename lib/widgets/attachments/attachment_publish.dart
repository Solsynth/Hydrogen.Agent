import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

class AttachmentPublishPopup extends StatefulWidget {
  final String usage;
  final List<int> current;
  final void Function(List<int> data) onUpdate;

  const AttachmentPublishPopup({
    super.key,
    required this.usage,
    required this.current,
    required this.onUpdate,
  });

  @override
  State<AttachmentPublishPopup> createState() => _AttachmentPublishPopupState();
}

class _AttachmentPublishPopupState extends State<AttachmentPublishPopup> {
  final _imagePicker = ImagePicker();

  bool _isBusy = false;
  bool _isFirstTimeBusy = true;

  List<Attachment?> _attachments = List.empty(growable: true);

  Future<void> pickPhotoToUpload() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final medias = await _imagePicker.pickMultiImage();
    if (medias.isEmpty) return;

    setState(() => _isBusy = true);

    for (final media in medias) {
      final file = File(media.path);
      final hash = await calculateFileSha256(file);

      try {
        await uploadAttachment(
          await file.readAsBytes(),
          file.path,
          hash,
          ratio: await calculateFileAspectRatio(file),
        );
      } catch (err) {
        context.showErrorDialog(err);
      }
    }

    setState(() => _isBusy = false);
  }

  Future<void> pickVideoToUpload() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final media = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (media == null) return;

    setState(() => _isBusy = true);

    final file = File(media.path);
    final hash = await calculateFileSha256(file);
    const ratio = 16 / 9;

    try {
      await uploadAttachment(await file.readAsBytes(), file.path, hash,
          ratio: ratio);
    } catch (err) {
      context.showErrorDialog(err);
    }

    setState(() => _isBusy = false);
  }

  Future<void> pickFileToUpload() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    FilePickerResult? result =
        await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    setState(() => _isBusy = true);

    List<File> files = result.paths.map((path) => File(path!)).toList();

    for (final file in files) {
      final hash = await calculateFileSha256(file);
      try {
        await uploadAttachment(await file.readAsBytes(), file.path, hash);
      } catch (err) {
        context.showErrorDialog(err);
      }
    }

    setState(() => _isBusy = false);
  }

  Future<void> takeMediaToUpload(bool isVideo) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    XFile? media;
    if (isVideo) {
      media = await _imagePicker.pickVideo(source: ImageSource.camera);
    } else {
      media = await _imagePicker.pickImage(source: ImageSource.camera);
    }
    if (media == null) return;

    setState(() => _isBusy = true);

    double? ratio;
    final file = File(media.path);
    final hash = await calculateFileSha256(file);

    if (isVideo) {
      ratio = 16 / 9;
    } else {
      ratio = await calculateFileAspectRatio(file);
    }

    try {
      await uploadAttachment(
        await file.readAsBytes(),
        file.path,
        hash,
        ratio: ratio,
      );
    } catch (err) {
      context.showErrorDialog(err);
    }

    setState(() => _isBusy = false);
  }

  Future<void> uploadAttachment(Uint8List data, String path, String hash,
      {double? ratio}) async {
    final AttachmentProvider provider = Get.find();
    try {
      final resp = await provider.createAttachment(
        data,
        path,
        hash,
        widget.usage,
        ratio: ratio,
      );
      var result = Attachment.fromJson(resp.body);
      setState(() => _attachments.add(result));
      widget.onUpdate(_attachments.map((e) => e!.id).toList());
    } catch (err) {
      rethrow;
    }
  }

  String formatBytes(int bytes, {int decimals = 2}) {
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

  void revertMetadataList() {
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
        _attachments[idx] = Attachment.fromJson(resp.body);
        if (progress == widget.current.length) {
          setState(() {
            _isBusy = false;
            _isFirstTimeBusy = false;
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    revertMetadataList();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const density = VisualDensity(horizontal: 0, vertical: 0);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: DropRegion(
          formats: Formats.standardFormats,
          hitTestBehavior: HitTestBehavior.opaque,
          onDropOver: (event) {
            if (event.session.allowedOperations.contains(DropOperation.copy)) {
              return DropOperation.copy;
            } else {
              return DropOperation.none;
            }
          },
          onPerformDrop: (event) async {
            for (final item in event.session.items) {
              final reader = item.dataReader!;
              for (final format
                  in Formats.standardFormats.whereType<FileFormat>()) {
                if (reader.canProvide(format)) {
                  reader.getFile(format, (file) async {
                    final data = await file.readAll();
                    await uploadAttachment(
                      data,
                      file.fileName ?? 'attachment',
                      await calculateBytesSha256(data),
                    );
                  }, onError: (error) {
                    print('Error reading value $error');
                  });
                }
              }
            }
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
                      var fileType = element!.mimetype.split('/').firstOrNull;
                      fileType ??= 'unknown';
                      return Container(
                        padding: const EdgeInsets.only(
                            left: 16, right: 8, bottom: 16),
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
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${fileType[0].toUpperCase()}${fileType.substring(1)} · ${formatBytes(element.size)}',
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              style: TextButton.styleFrom(
                                shape: const CircleBorder(),
                                foregroundColor: Theme.of(context).primaryColor,
                              ),
                              icon: const Icon(Icons.more_horiz),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AttachmentEditorDialog(
                                      item: element,
                                      onDelete: () {
                                        setState(
                                            () => _attachments.removeAt(index));
                                        widget.onUpdate(_attachments
                                            .map((e) => e!.id)
                                            .toList());
                                      },
                                      onUpdate: (item) {
                                        setState(
                                            () => _attachments[index] = item);
                                        widget.onUpdate(_attachments
                                            .map((e) => e!.id)
                                            .toList());
                                      },
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      );
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
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_photo_alternate),
                        label: Text('attachmentAddGalleryPhoto'.tr),
                        style: const ButtonStyle(visualDensity: density),
                        onPressed: () => pickPhotoToUpload(),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_road),
                        label: Text('attachmentAddGalleryVideo'.tr),
                        style: const ButtonStyle(visualDensity: density),
                        onPressed: () => pickVideoToUpload(),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_camera_back),
                        label: Text('attachmentAddCameraPhoto'.tr),
                        style: const ButtonStyle(visualDensity: density),
                        onPressed: () => takeMediaToUpload(false),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.video_camera_back_outlined),
                        label: Text('attachmentAddCameraVideo'.tr),
                        style: const ButtonStyle(visualDensity: density),
                        onPressed: () => takeMediaToUpload(true),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.file_present_rounded),
                        label: Text('attachmentAddFile'.tr),
                        style: const ButtonStyle(visualDensity: density),
                        onPressed: () => pickFileToUpload(),
                      ),
                    ],
                  ).paddingSymmetric(horizontal: 12),
                ),
              )
            ],
          ),
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
  final _ratioController = TextEditingController();
  final _altController = TextEditingController();

  bool _isBusy = false;
  bool _isMature = false;
  bool _hasAspectRatio = false;

  Future<Attachment?> updateAttachment() async {
    final AttachmentProvider provider = Get.find();

    setState(() => _isBusy = true);
    try {
      final resp = await provider.updateAttachment(
        widget.item.id,
        _altController.value.text,
        widget.item.usage,
        ratio: _hasAspectRatio
            ? (double.tryParse(_ratioController.value.text) ?? 1)
            : null,
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

    if (['image', 'video'].contains(widget.item.mimetype.split('/').first)) {
      _ratioController.text =
          widget.item.metadata?['ratio']?.toString() ?? 1.toString();
      _hasAspectRatio = true;
    }
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
            const SizedBox(height: 16),
            TextField(
              readOnly: !_hasAspectRatio,
              controller: _ratioController,
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.aspect_ratio),
                border: const OutlineInputBorder(),
                labelText: 'aspectRatio'.tr,
              ),
              onTapOutside: (_) =>
                  FocusManager.instance.primaryFocus?.unfocus(),
            ),
            const SizedBox(height: 5),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 6,
                runSpacing: 0,
                children: [
                  ActionChip(
                    avatar: Icon(Icons.square_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    label: Text('aspectRatioSquare'.tr),
                    onPressed: () {
                      if (_hasAspectRatio) {
                        setState(() => _ratioController.text = '1');
                      }
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.portrait,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    label: Text('aspectRatioPortrait'.tr),
                    onPressed: () {
                      if (_hasAspectRatio) {
                        setState(
                            () => _ratioController.text = (9 / 16).toString());
                      }
                    },
                  ),
                  ActionChip(
                    avatar: Icon(Icons.landscape,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                    label: Text('aspectRatioLandscape'.tr),
                    onPressed: () {
                      if (_hasAspectRatio) {
                        setState(
                            () => _ratioController.text = (16 / 9).toString());
                      }
                    },
                  ),
                ],
              ),
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
