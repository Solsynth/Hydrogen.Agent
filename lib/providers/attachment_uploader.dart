import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' show basename;
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/content/attachment.dart';

class AttachmentUploadTask {
  XFile file;
  String pool;
  Map<String, dynamic>? metadata;
  Map<String, int>? chunkFiles;

  double? progress;
  bool isUploading = false;
  bool isCompleted = false;
  dynamic error;

  AttachmentUploadTask({
    required this.file,
    required this.pool,
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
    queueOfUpload[queueIndex].progress = 0;

    final task = queueOfUpload[queueIndex];
    try {
      final result = await _chunkedUploadAttachment(
        task.file,
        task.pool,
        null,
        onData: (_) {},
        onProgress: (progress) {
          queueOfUpload[queueIndex].progress = progress;
          _progressOfUpload = progress;
        },
      );
      return result;
    } catch (err) {
      queueOfUpload[queueIndex].error = err;
      queueOfUpload[queueIndex].isUploading = false;
    } finally {
      _progressOfUpload = 1;
      if (queueOfUpload[queueIndex].error == null) {
        queueOfUpload.removeAt(queueIndex);
      }
      _stopProgressSyncTimer();
      _syncProgress();

      isUploading.value = false;
    }

    return null;
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
      queueOfUpload[idx].progress = 0;

      final task = queueOfUpload[idx];
      try {
        final result = await _chunkedUploadAttachment(
          task.file,
          task.pool,
          null,
          onData: (_) {},
          onProgress: (progress) {
            queueOfUpload[idx].progress = progress;
          },
        );
        if (result != null) onData(result);
      } catch (err) {
        queueOfUpload[idx].error = err;
        queueOfUpload[idx].isUploading = false;
      } finally {
        _progressOfUpload = (idx + 1) / queueOfUpload.length;
      }

      queueOfUpload[idx].isUploading = false;
      queueOfUpload[idx].isCompleted = true;
    }

    queueOfUpload.removeWhere((x) => x.error == null);
    _stopProgressSyncTimer();
    _syncProgress();

    isUploading.value = false;
  }

  Future<Attachment?> uploadAttachmentFromData(
    Uint8List data,
    String path,
    String pool,
    Map<String, dynamic>? metadata,
  ) async {
    if (isUploading.value) throw Exception('uploading blocked');
    isUploading.value = true;

    final AttachmentProvider attach = Get.find();

    try {
      final result = await attach.createAttachmentDirectly(
        data,
        path,
        pool,
        metadata,
      );
      return result;
    } catch (_) {
      return null;
    } finally {
      isUploading.value = false;
    }
  }

  Future<Attachment?> _chunkedUploadAttachment(
    XFile file,
    String pool,
    Map<String, dynamic>? metadata, {
    required Function(AttachmentPlaceholder) onData,
    required Function(double) onProgress,
  }) async {
    final AttachmentProvider attach = Get.find();

    final holder = await attach.createAttachmentMultipartPlaceholder(
      await file.length(),
      file.path,
      pool,
      metadata,
    );
    onData(holder);

    onProgress(0);

    final filename = basename(file.path);
    final chunks = holder.meta.fileChunks ?? {};
    var currentTask = 0;

    final queue = Queue<Future<void>>();
    final activeTasks = <Future<void>>[];

    for (final entry in chunks.entries) {
      queue.add(() async {
        final beginCursor = entry.value * holder.chunkSize;
        final endCursor = (entry.value + 1) * holder.chunkSize;
        final data = Uint8List.fromList(await file
            .openRead(beginCursor, endCursor)
            .expand((chunk) => chunk)
            .toList());

        final out = await attach.uploadAttachmentMultipartChunk(
          data,
          filename,
          holder.meta.rid,
          entry.key,
        );
        holder.meta = out;

        currentTask++;
        onProgress(currentTask / chunks.length);
        onData(holder);
      }());
    }

    while (queue.isNotEmpty || activeTasks.isNotEmpty) {
      while (activeTasks.length < 3 && queue.isNotEmpty) {
        final task = queue.removeFirst();
        activeTasks.add(task);

        task.then((_) => activeTasks.remove(task));
      }

      if (activeTasks.isNotEmpty) {
        await Future.any(activeTasks);
      }
    }

    return holder.meta;
  }
}
