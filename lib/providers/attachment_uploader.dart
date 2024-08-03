import 'dart:async';
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
  dynamic error;

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

  Timer? _progressSyncTimer;
  double _progressOfUpload = 0.0;

  void _syncProgress() {
    progressOfUpload.value = _progressOfUpload;
    queueOfUpload.refresh();
  }

  void _startProgressSyncTimer() {
    if (_progressSyncTimer != null) {
      _progressSyncTimer!.cancel();
    }
    _progressSyncTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) => _syncProgress(),
    );
  }

  void _stopProgressSyncTimer() {
    if (_progressSyncTimer == null) return;
    _progressSyncTimer!.cancel();
    _progressSyncTimer = null;
  }

  void enqueueTask(AttachmentUploadTask task) {
    if (isUploading.value) throw Exception('uploading blocked');
    queueOfUpload.add(task);
  }

  void enqueueTaskBatch(Iterable<AttachmentUploadTask> tasks) {
    if (isUploading.value) throw Exception('uploading blocked');
    queueOfUpload.addAll(tasks);
  }

  void dequeueTask(AttachmentUploadTask task) {
    if (isUploading.value) throw Exception('uploading blocked');
    queueOfUpload.remove(task);
  }

  Future<Attachment?> performSingleTask(int queueIndex) async {
    isUploading.value = true;
    progressOfUpload.value = 0;

    _startProgressSyncTimer();
    queueOfUpload[queueIndex].isUploading = true;

    final task = queueOfUpload[queueIndex];
    final result = await _rawUploadAttachment(
      await task.file.readAsBytes(),
      task.file.path,
      task.usage,
      null,
      onProgress: (value) {
        queueOfUpload[queueIndex].progress = value;
        _progressOfUpload = value;
      },
      onError: (err) {
        queueOfUpload[queueIndex].error = err;
        queueOfUpload[queueIndex].isUploading = false;
      },
    );

    if (queueOfUpload[queueIndex].error == null) {
      queueOfUpload.removeAt(queueIndex);
    }
    _stopProgressSyncTimer();
    _syncProgress();

    isUploading.value = false;

    return result;
  }

  Future<void> performUploadQueue({
    required Function(Attachment item) onData,
  }) async {
    isUploading.value = true;
    progressOfUpload.value = 0;

    _startProgressSyncTimer();

    for (var idx = 0; idx < queueOfUpload.length; idx++) {
      if (queueOfUpload[idx].isUploading || queueOfUpload[idx].error != null) {
        continue;
      }

      queueOfUpload[idx].isUploading = true;

      final task = queueOfUpload[idx];
      final result = await _rawUploadAttachment(
        await task.file.readAsBytes(),
        task.file.path,
        task.usage,
        null,
        onProgress: (value) {
          queueOfUpload[idx].progress = value;
          _progressOfUpload = (idx + value) / queueOfUpload.length;
        },
        onError: (err) {
          queueOfUpload[idx].error = err;
          queueOfUpload[idx].isUploading = false;
        },
      );
      _progressOfUpload = (idx + 1) / queueOfUpload.length;
      if (result != null) onData(result);

      queueOfUpload[idx].isUploading = false;
      queueOfUpload[idx].isCompleted = true;
    }

    queueOfUpload.value =
        queueOfUpload.where((x) => x.error == null).toList(growable: true);
    _stopProgressSyncTimer();
    _syncProgress();

    isUploading.value = false;
  }

  Future<void> uploadAttachmentWithCallback(
    Uint8List data,
    String path,
    String usage,
    Map<String, dynamic>? metadata,
    Function(Attachment?) callback,
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

  Future<Attachment?> uploadAttachment(
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

  Future<Attachment?> _rawUploadAttachment(
      Uint8List data, String path, String usage, Map<String, dynamic>? metadata,
      {Function(double)? onProgress, Function(dynamic err)? onError}) async {
    final AttachmentProvider provider = Get.find();
    try {
      final result = await provider.createAttachment(
        data,
        path,
        usage,
        metadata,
        onProgress: onProgress,
      );
      return result;
    } catch (err) {
      if (onError != null) {
        onError(err);
      }
      return null;
    }
  }
}
