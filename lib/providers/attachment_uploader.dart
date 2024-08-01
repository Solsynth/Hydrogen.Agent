import 'dart:io';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/content/attachment.dart';

class AttachmentUploadTask {
  File file;
  String usage;
  Map<String, dynamic>? metadata;

  double progress = 0;
  bool isUploading = false;
  bool isCompleted = false;

  AttachmentUploadTask({
    required this.file,
    required this.usage,
    this.metadata,
  });
}

class AttachmentUploaderController extends GetxController {
  RxBool isUploading = false.obs;
  RxDouble progressOfUpload = 0.0.obs;
  RxList<AttachmentUploadTask> queueOfUpload = RxList.empty(growable: true);

  void enqueueTask(AttachmentUploadTask task) {
    if (isUploading.value) throw Exception('uploading blocked');
    queueOfUpload.add(task);
  }

  void dequeueTask(AttachmentUploadTask task) {
    if (isUploading.value) throw Exception('uploading blocked');
    queueOfUpload.remove(task);
  }

  Future<Attachment> performSingleTask(int queueIndex) async {
    isUploading.value = true;
    progressOfUpload.value = 0;

    queueOfUpload[queueIndex].isUploading = true;
    queueOfUpload.refresh();

    final task = queueOfUpload[queueIndex];
    final result = await _rawUploadAttachment(
      await task.file.readAsBytes(),
      task.file.path,
      task.usage,
      null,
      onProgress: (value) {
        queueOfUpload[queueIndex].progress = value;
        queueOfUpload.refresh();
        progressOfUpload.value = value;
      },
    );

    queueOfUpload.removeAt(queueIndex);
    queueOfUpload.refresh();

    isUploading.value = false;

    return result;
  }

  Future<void> performUploadQueue({
    required Function(Attachment item) onData,
  }) async {
    isUploading.value = true;
    progressOfUpload.value = 0;

    for (var idx = 0; idx < queueOfUpload.length; idx++) {
      queueOfUpload[idx].isUploading = true;
      queueOfUpload.refresh();

      final task = queueOfUpload[idx];
      final result = await _rawUploadAttachment(
        await task.file.readAsBytes(),
        task.file.path,
        task.usage,
        null,
        onProgress: (value) {
          queueOfUpload[idx].progress = value;
          queueOfUpload.refresh();
          progressOfUpload.value = (idx + value) / queueOfUpload.length;
        },
      );
      progressOfUpload.value = (idx + 1) / queueOfUpload.length;
      onData(result);

      queueOfUpload[idx].isUploading = false;
      queueOfUpload[idx].isCompleted = false;
      queueOfUpload.refresh();
    }

    queueOfUpload.clear();
    queueOfUpload.refresh();
    isUploading.value = false;
  }

  Future<void> uploadAttachmentWithCallback(
    Uint8List data,
    String path,
    String usage,
    Map<String, dynamic>? metadata,
    Function(Attachment) callback,
  ) async {
    if (isUploading.value) throw Exception('uploading blocked');

    isUploading.value = true;
    final result = await _rawUploadAttachment(
      data,
      path,
      usage,
      metadata,
      onProgress: (progress) {
        progressOfUpload.value = progress;
      },
    );
    isUploading.value = false;
    callback(result);
  }

  Future<Attachment> uploadAttachment(
    Uint8List data,
    String path,
    String usage,
    Map<String, dynamic>? metadata,
  ) async {
    if (isUploading.value) throw Exception('uploading blocked');

    isUploading.value = true;
    final result = await _rawUploadAttachment(
      data,
      path,
      usage,
      metadata,
      onProgress: (progress) {
        progressOfUpload.value = progress;
      },
    );
    isUploading.value = false;
    return result;
  }

  Future<Attachment> _rawUploadAttachment(
      Uint8List data, String path, String usage, Map<String, dynamic>? metadata,
      {Function(double)? onProgress}) async {
    final AttachmentProvider provider = Get.find();
    try {
      final resp = await provider.createAttachment(
        data,
        path,
        usage,
        metadata,
        onProgress: onProgress,
      );
      var result = Attachment.fromJson(resp.body);
      return result;
    } catch (err) {
      rethrow;
    }
  }
}
