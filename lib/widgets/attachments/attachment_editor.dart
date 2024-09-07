import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:path/path.dart' show basename, extension;
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/attachment_uploader.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/widgets/attachments/attachment_attr_editor.dart';
import 'package:solian/widgets/attachments/attachment_fullscreen.dart';

class AttachmentEditorPopup extends StatefulWidget {
  final String pool;
  final bool singleMode;
  final bool imageOnly;
  final bool autoUpload;
  final double? imageMaxWidth;
  final double? imageMaxHeight;
  final List<String>? initialAttachments;
  final void Function(String) onAdd;
  final void Function(String) onRemove;

  const AttachmentEditorPopup({
    super.key,
    required this.pool,
    required this.onAdd,
    required this.onRemove,
    this.singleMode = false,
    this.imageOnly = false,
    this.autoUpload = false,
    this.imageMaxWidth,
    this.imageMaxHeight,
    this.initialAttachments,
  });

  @override
  State<AttachmentEditorPopup> createState() => _AttachmentEditorPopupState();
}

class _AttachmentEditorPopupState extends State<AttachmentEditorPopup> {
  final _imagePicker = ImagePicker();
  final AttachmentUploaderController _uploadController = Get.find();

  late bool _isAutoUpload = widget.autoUpload;

  bool _isBusy = false;
  bool _isFirstTimeBusy = true;

  List<Attachment?> _attachments = List.empty(growable: true);

  Future<void> _pickPhotoToUpload() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    if (!widget.singleMode) {
      final medias = await _imagePicker.pickMultiImage(
        maxWidth: widget.imageMaxWidth,
        maxHeight: widget.imageMaxHeight,
      );
      if (medias.isEmpty) return;

      _enqueueTaskBatch(medias.map((x) {
        final file = XFile(x.path);
        return AttachmentUploadTask(file: file, pool: widget.pool);
      }));
    } else {
      final media = await _imagePicker.pickMedia(
        maxWidth: widget.imageMaxWidth,
        maxHeight: widget.imageMaxHeight,
      );
      if (media == null) return;

      _enqueueTask(
        AttachmentUploadTask(file: XFile(media.path), pool: widget.pool),
      );
    }
  }

  Future<void> _pickVideoToUpload() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final media = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (media == null) return;

    _enqueueTask(
      AttachmentUploadTask(file: XFile(media.path), pool: widget.pool),
    );
  }

  Future<void> _pickFileToUpload() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );
    if (result == null) return;

    List<File> files = result.paths.map((path) => File(path!)).toList();

    _enqueueTaskBatch(files.map((x) {
      return AttachmentUploadTask(file: XFile(x.path), pool: widget.pool);
    }));
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

    _enqueueTask(
      AttachmentUploadTask(file: XFile(media.path), pool: widget.pool),
    );
  }

  Future<void> _linkAttachments() async {
    final controller = TextEditingController();
    final input = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('attachmentAddLink'.tr),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('attachmentAddLinkHint'.tr, textAlign: TextAlign.left),
              const Gap(18),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'attachmentAddLinkInput'.tr,
                ),
                onTapOutside: (_) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('cancel'.tr),
            ),
            TextButton(
              child: Text('next'.tr),
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
            ),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => controller.dispose());

    if (input == null || input.isEmpty) return;

    final AttachmentProvider attach = Get.find();
    final result = await attach.getMetadata(input);
    if (result != null) {
      widget.onAdd(result.rid);
      setState(() => _attachments.add(result));
      if (widget.singleMode) Navigator.pop(context);
    }
  }

  void _pasteFileToUpload() async {
    final data = await Pasteboard.image;
    if (data == null) return;

    if (_uploadController.isUploading.value) return;

    _uploadController
        .uploadAttachmentFromData(data, 'Pasted Image', widget.pool, null)
        .then((item) {
      if (item == null) return;
      widget.onAdd(item.rid);
      if (mounted) {
        setState(() => _attachments.add(item));
        if (widget.singleMode) Navigator.pop(context);
      }
    });
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
    final AttachmentProvider attach = Get.find();

    if (widget.initialAttachments?.isEmpty ?? true) {
      _isFirstTimeBusy = false;
      return;
    } else {
      _attachments = List.filled(
        widget.initialAttachments!.length,
        null,
        growable: true,
      );
    }

    setState(() => _isBusy = true);

    attach
        .listMetadata(widget.initialAttachments ?? List.empty())
        .then((result) {
      setState(() {
        _attachments = List.from(result, growable: true);
        _isBusy = false;
        _isFirstTimeBusy = false;
      });
    });
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
        return AttachmentAttrEditorDialog(
          item: element,
          onUpdate: (item) {
            setState(() => _attachments[index] = item);
          },
        );
      },
    );
  }

  Future<void> _cropAttachment(int queueIndex) async {
    final task = _uploadController.queueOfUpload[queueIndex];
    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: task.file.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'cropImage'.tr,
          toolbarColor: Theme.of(context).colorScheme.primary,
          toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
          aspectRatioPresets: CropAspectRatioPreset.values,
        ),
        IOSUiSettings(
          title: 'cropImage'.tr,
          aspectRatioPresets: CropAspectRatioPreset.values,
        ),
        WebUiSettings(
          context: context,
        ),
      ],
    );
    if (croppedFile == null) return;
    _uploadController.queueOfUpload[queueIndex].file = XFile(croppedFile.path);
    _uploadController.queueOfUpload.refresh();
  }

  Future<void> _deleteAttachment(Attachment element) async {
    setState(() => _isBusy = true);
    try {
      final AttachmentProvider provider = Get.find();
      await provider.deleteAttachment(element.id);
    } catch (e) {
      context.showErrorDialog(e);
    } finally {
      setState(() => _isBusy = false);
    }
  }

  Widget _buildQueueEntry(AttachmentUploadTask element, int index) {
    final extName = extension(element.file.path).substring(1);
    final canBeCrop = ['png', 'jpg', 'jpeg', 'gif'].contains(extName);

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
                          basename(element.file.path),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Row(
                          children: [
                            FutureBuilder(
                              future: element.file.length(),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return const SizedBox();
                                return Text(
                                  _formatBytes(snapshot.data!),
                                  style: Theme.of(context).textTheme.bodySmall,
                                );
                              },
                            ),
                            const Gap(6),
                            if (element.progress != null)
                              Text(
                                '${(element.progress! * 100).toStringAsFixed(2)}%',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (element.isUploading)
                    SizedBox(
                      width: 40,
                      height: 38,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            value: element.progress,
                          ),
                        ),
                      ),
                    ),
                  if (element.isCompleted)
                    const SizedBox(
                      width: 40,
                      height: 38,
                      child: Center(
                        child: Icon(Icons.check),
                      ),
                    ),
                  if (element.error != null)
                    IconButton(
                      tooltip: element.error!.toString(),
                      icon: const Icon(Icons.warning),
                      onPressed: () {},
                    ),
                  if (!element.isCompleted &&
                      element.error == null &&
                      canBeCrop)
                    Obx(
                      () => IconButton(
                        color: Colors.teal,
                        icon: const Icon(Icons.crop),
                        visualDensity: const VisualDensity(horizontal: -4),
                        onPressed: _uploadController.isUploading.value
                            ? null
                            : () {
                                _cropAttachment(index);
                              },
                      ),
                    ),
                  if (!element.isCompleted &&
                      !element.isUploading &&
                      element.error == null)
                    Obx(
                      () => IconButton(
                        color: Colors.green,
                        icon: const Icon(Icons.play_arrow),
                        visualDensity: const VisualDensity(horizontal: -4),
                        onPressed: _uploadController.isUploading.value
                            ? null
                            : () {
                                _uploadController
                                    .performSingleTask(index)
                                    .then((out) {
                                  if (out == null) return;
                                  widget.onAdd(out.rid);
                                  if (mounted) {
                                    setState(() => _attachments.add(out));
                                    if (widget.singleMode) {
                                      Navigator.pop(context);
                                    }
                                  }
                                });
                              },
                      ),
                    ),
                  if (!element.isCompleted && !element.isUploading)
                    IconButton(
                      color: Colors.red,
                      icon: const Icon(Icons.remove_circle),
                      visualDensity: const VisualDensity(horizontal: -4),
                      onPressed: () {
                        _uploadController.dequeueTask(element);
                      },
                    ),
                ],
              ).paddingSymmetric(vertical: 8, horizontal: 16),
            ),
          ],
        ),
      ),
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
                            fontFamily: 'monospace',
                          ),
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
                  PopupMenuButton(
                    icon: const Icon(Icons.more_horiz),
                    iconColor: Theme.of(context).colorScheme.primary,
                    style: const ButtonStyle(
                      visualDensity: VisualDensity(horizontal: -4),
                    ),
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        child: ListTile(
                          title: Text('edit'.tr),
                          leading: const Icon(Icons.edit),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                        onTap: () => _showEdit(element, index),
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          title: Text('delete'.tr),
                          leading: const Icon(Icons.delete),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                        onTap: () {
                          _deleteAttachment(element).then((_) {
                            widget.onRemove(element.rid);
                            setState(() => _attachments.removeAt(index));
                          });
                        },
                      ),
                      PopupMenuItem(
                        child: ListTile(
                          title: Text('unlink'.tr),
                          leading: const Icon(Icons.link_off),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                        ),
                        onTap: () {
                          widget.onRemove(element.rid);
                          setState(() => _attachments.removeAt(index));
                        },
                      ),
                    ],
                  ),
                ],
              ).paddingSymmetric(vertical: 8, horizontal: 16),
            ),
          ],
        ),
      ),
    );
  }

  void _enqueueTask(AttachmentUploadTask task) {
    _uploadController.enqueueTask(task);
    if (_isAutoUpload) {
      _startUploading();
    }
  }

  void _enqueueTaskBatch(Iterable<AttachmentUploadTask> tasks) {
    _uploadController.enqueueTaskBatch(tasks);
    if (_isAutoUpload) {
      _startUploading();
    }
  }

  void _startUploading() {
    _uploadController.performUploadQueue(onData: (r) {
      widget.onAdd(r.rid);
      if (mounted) {
        setState(() => _attachments.add(r));
        if (widget.singleMode) Navigator.pop(context);
      }
    });
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
          if (_uploadController.isUploading.value) return;
          _enqueueTaskBatch(detail.files.map((x) {
            final file = XFile(x.path);
            return AttachmentUploadTask(file: file, pool: widget.pool);
          }));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'attachmentAdd'.tr,
                              style: Theme.of(context).textTheme.headlineSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const Gap(10),
                            Obx(() {
                              if (_uploadController.isUploading.value) {
                                return SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    value: _uploadController
                                        .progressOfUpload.value,
                                  ),
                                );
                              }
                              return const SizedBox();
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(20),
                Text('attachmentAutoUpload'.tr),
                const Gap(8),
                Switch(
                  value: _isAutoUpload,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() => _isAutoUpload = value);
                    }
                  },
                ),
              ],
            ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
            if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  Obx(() {
                    if (_uploadController.queueOfUpload.isNotEmpty) {
                      return SliverPadding(
                        padding: const EdgeInsets.only(bottom: 8),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'attachmentUploadQueue'.tr,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Obx(() {
                                if (_uploadController.isUploading.value) {
                                  return const SizedBox();
                                }
                                return TextButton(
                                  child: Text('attachmentUploadQueueStart'.tr),
                                  onPressed: () {
                                    _startUploading();
                                  },
                                );
                              }),
                            ],
                          ).paddingOnly(left: 24, right: 24),
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox());
                  }),
                  Obx(() {
                    if (_uploadController.queueOfUpload.isNotEmpty) {
                      return SliverPadding(
                        padding: const EdgeInsets.only(bottom: 8),
                        sliver: SliverList.builder(
                          itemCount: _uploadController.queueOfUpload.length,
                          itemBuilder: (context, index) {
                            final element =
                                _uploadController.queueOfUpload[index];
                            return _buildQueueEntry(element, index);
                          },
                        ),
                      );
                    }
                    return const SliverToBoxAdapter(child: SizedBox());
                  }),
                  if (_attachments.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 8),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          'attachmentAttached'.tr,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ).paddingOnly(left: 24, right: 24),
                      ),
                    ),
                  if (_attachments.isNotEmpty)
                    Builder(builder: (context) {
                      if (_isFirstTimeBusy && _isBusy) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      return SliverList.builder(
                        itemCount: _attachments.length,
                        itemBuilder: (context, index) {
                          final element = _attachments[index];
                          return _buildListEntry(element!, index);
                        },
                      );
                    }),
                ],
              ),
            ),
            Obx(() {
              return IgnorePointer(
                ignoring: _uploadController.isUploading.value,
                child: Container(
                  height: 64,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 0.3,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 0,
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      children: [
                        if ((PlatformInfo.isDesktop ||
                                PlatformInfo.isIOS ||
                                PlatformInfo.isWeb) &&
                            !widget.imageOnly)
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
                        if (!widget.imageOnly)
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
                        if (!widget.imageOnly)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.video_camera_back_outlined),
                            label: Text('attachmentAddCameraVideo'.tr),
                            style: const ButtonStyle(visualDensity: density),
                            onPressed: () => _takeMediaToUpload(true),
                          ),
                        if (!widget.imageOnly)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.file_present_rounded),
                            label: Text('attachmentAddFile'.tr),
                            style: const ButtonStyle(visualDensity: density),
                            onPressed: () => _pickFileToUpload(),
                          ),
                        if (!widget.imageOnly)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.link),
                            label: Text('attachmentAddFile'.tr),
                            style: const ButtonStyle(visualDensity: density),
                            onPressed: () => _linkAttachments(),
                          ),
                      ],
                    ).paddingSymmetric(horizontal: 12),
                  ),
                )
                    .animate(
                      target: _uploadController.isUploading.value ? 0 : 1,
                    )
                    .fade(duration: 100.ms),
              );
            }),
          ],
        ),
      ),
    );
  }
}
