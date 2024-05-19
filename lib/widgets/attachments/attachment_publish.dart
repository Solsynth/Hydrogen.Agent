import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/auth.dart';
import 'package:crypto/crypto.dart';
import 'package:solian/services.dart';

Future<String> calculateFileSha256(File file) async {
  final bytes = await file.readAsBytes();
  final digest = sha256.convert(bytes);
  return digest.toString();
}

class AttachmentPublishingPopup extends StatefulWidget {
  final String usage;
  final List<String> current;
  final void Function(List<String> data) onUpdate;

  const AttachmentPublishingPopup({
    super.key,
    required this.usage,
    required this.current,
    required this.onUpdate,
  });

  @override
  State<AttachmentPublishingPopup> createState() => _AttachmentPublishingPopupState();
}

class _AttachmentPublishingPopupState extends State<AttachmentPublishingPopup> {
  final _imagePicker = ImagePicker();

  bool _isSubmitting = false;

  final List<Attachment> _attachments = List.empty(growable: true);

  Future<void> pickPhotoToUpload() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final medias = await _imagePicker.pickMultiImage();
    if (medias.isEmpty) return;

    setState(() => _isSubmitting = true);

    for (final media in medias) {
      final file = File(media.path);
      final hash = await calculateFileSha256(file);
      final image = await decodeImageFromList(await file.readAsBytes());
      final ratio = image.width / image.height;

      try {
        await uploadAttachment(file, hash, ratio: ratio);
      } catch (err) {
        this.context.showErrorDialog(err);
      }
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> pickVideoToUpload() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final media = await _imagePicker.pickVideo(source: ImageSource.gallery);
    if (media == null) return;

    setState(() => _isSubmitting = true);

    final file = File(media.path);
    final hash = await calculateFileSha256(file);
    const ratio = 16 / 9; // TODO Calculate ratio of video

    try {
      await uploadAttachment(file, hash, ratio: ratio);
    } catch (err) {
      this.context.showErrorDialog(err);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> pickFileToUpload() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result == null) return;

    List<File> files = result.paths.map((path) => File(path!)).toList();

    setState(() => _isSubmitting = true);

    for (final file in files) {
      final hash = await calculateFileSha256(file);
      try {
        await uploadAttachment(file, hash);
      } catch (err) {
        this.context.showErrorDialog(err);
      }
    }

    setState(() => _isSubmitting = false);
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

    setState(() => _isSubmitting = true);

    double? ratio;
    final file = File(media.path);
    final hash = await calculateFileSha256(file);

    if (isVideo) {
      // TODO Calculate ratio of video
      ratio = 16 / 9;
    } else {
      final image = await decodeImageFromList(await file.readAsBytes());
      ratio = image.width / image.height;
    }

    try {
      await uploadAttachment(file, hash, ratio: ratio);
    } catch (err) {
      this.context.showErrorDialog(err);
    }

    setState(() => _isSubmitting = false);
  }

  Future<void> uploadAttachment(File file, String hash, {double? ratio}) async {
    final AuthProvider auth = Get.find();

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['paperclip'];
    client.httpClient.addAuthenticator(auth.reqAuthenticator);

    final filePayload = MultipartFile(await file.readAsBytes(), filename: basename(file.path));
    final fileAlt = basename(file.path).contains('.')
        ? basename(file.path).substring(0, basename(file.path).lastIndexOf('.'))
        : basename(file.path);

    final resp = await client.post(
      '/api/attachments',
      FormData({
        'alt': fileAlt,
        'file': filePayload,
        'hash': hash,
        'usage': widget.usage,
        'metadata': {
          if (ratio != null) 'ratio': ratio,
        },
      }),
    );
    if (resp.statusCode == 200) {
      var result = Attachment.fromJson(resp.body);
      setState(() => _attachments.add(result));
      widget.onUpdate(_attachments.map((e) => e.uuid).toList());
    } else {
      throw Exception(resp.bodyString);
    }
  }

  Future<void> disposeAttachment(Attachment item, int index) async {
    final AuthProvider auth = Get.find();

    final client = GetConnect();
    client.httpClient.baseUrl = ServiceFinder.services['paperclip'];
    client.httpClient.addAuthenticator(auth.reqAuthenticator);

    setState(() => _isSubmitting = true);
    var resp = await client.delete('/api/attachments/${item.id}');
    if (resp.statusCode == 200) {
      setState(() => _attachments.removeAt(index));
      widget.onUpdate(_attachments.map((e) => e.uuid).toList());
    } else {
      this.context.showErrorDialog(resp.bodyString);
    }
    setState(() => _isSubmitting = false);
  }

  String formatBytes(int bytes, {int decimals = 2}) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    final dm = decimals < 0 ? 0 : decimals;
    final sizes = ['Bytes', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB', 'ZiB', 'YiB'];
    final i = (math.log(bytes) / math.log(k)).floor().toInt();
    return '${(bytes / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    const density = VisualDensity(horizontal: 0, vertical: 0);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'attachmentAdd'.tr,
              style: Theme.of(context).textTheme.headlineSmall,
            ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
            _isSubmitting ? const LinearProgressIndicator().animate().scaleX() : Container(),
            Expanded(
              child: ListView.builder(
                itemCount: _attachments.length,
                itemBuilder: (context, index) {
                  final element = _attachments[index];
                  final fileType = element.mimetype.split('/').first;
                  return Container(
                    padding: const EdgeInsets.only(left: 16, right: 8, bottom: 16),
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
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${fileType[0].toUpperCase()}${fileType.substring(1)} · ${formatBytes(element.size)}',
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            shape: const CircleBorder(),
                            foregroundColor: Colors.red,
                          ),
                          child: const Icon(Icons.delete),
                          onPressed: () => disposeAttachment(element, index),
                        ),
                      ],
                    ),
                  );
                },
              ),
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
    );
  }
}
