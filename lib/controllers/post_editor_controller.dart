import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/get_rx.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/widgets/attachments/attachment_publish.dart';
import 'package:solian/widgets/posts/editor/post_editor_overview.dart';
import 'package:textfield_tags/textfield_tags.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostEditorController extends GetxController {
  late final SharedPreferences _prefs;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final contentController = TextEditingController();
  final tagController = StringTagController();

  RxInt mode = 0.obs;
  RxInt contentLength = 0.obs;

  Rx<Post?> editTo = Rx(null);
  Rx<Post?> replyTo = Rx(null);
  Rx<Post?> repostTo = Rx(null);
  Rx<Realm?> realmZone = Rx(null);
  RxList<int> attachments = RxList<int>.empty(growable: true);

  RxBool isDraft = false.obs;

  RxBool isRestoreFromLocal = false.obs;
  Rx<DateTime?> lastSaveTime = Rx(null);
  Timer? _saveTimer;

  PostEditorController() {
    SharedPreferences.getInstance().then((inst) {
      _prefs = inst;
      localRead();
      _saveTimer = Timer.periodic(
        const Duration(seconds: 3),
        (Timer t) {
          if (isNotEmpty) {
            localSave();
            lastSaveTime.value = DateTime.now();
            lastSaveTime.refresh();
          } else if (_prefs.containsKey('post_editor_local_save')) {
            localClear();
            lastSaveTime.value = null;
          }
        },
      );
    });
    contentController.addListener(() {
      contentLength.value = contentController.text.length;
    });
  }

  Future<void> editOverview(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => PostEditorOverviewDialog(
        controller: this,
      ),
    );
  }

  Future<void> editAttachment(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AttachmentPublishPopup(
        usage: 'i.attachment',
        current: attachments,
        onUpdate: (value) {
          attachments.value = value;
          attachments.refresh();
        },
      ),
    );
  }

  void toggleDraftMode() {
    isDraft.value = !isDraft.value;
  }

  void localSave() {
    _prefs.setString(
      'post_editor_local_save',
      jsonEncode({
        ...payload,
        'reply_to': replyTo.value?.toJson(),
        'repost_to': repostTo.value?.toJson(),
        'edit_to': editTo.value?.toJson(),
        'realm': realmZone.value?.toJson(),
      }),
    );
  }

  void localRead() {
    if (_prefs.containsKey('post_editor_local_save')) {
      isRestoreFromLocal.value = true;
      payload = jsonDecode(_prefs.getString('post_editor_local_save')!);
    }
  }

  void localClear() {
    _prefs.remove('post_editor_local_save');
  }

  void currentClear() {
    titleController.clear();
    descriptionController.clear();
    contentController.clear();
    tagController.clearTags();
    attachments.clear();
    isDraft.value = false;
    isRestoreFromLocal.value = false;
    lastSaveTime.value = null;
    contentLength.value = 0;
    editTo.value = null;
    replyTo.value = null;
    repostTo.value = null;
    realmZone.value = null;
  }

  set editTarget(Post? value) {
    if (value == null) {
      editTo.value = null;
      return;
    }

    editTo.value = value;
    isDraft.value = value.isDraft ?? false;
    titleController.text = value.body['title'] ?? '';
    descriptionController.text = value.body['description'] ?? '';
    contentController.text = value.body['content'] ?? '';
    attachments.value = value.body['attachments']?.cast<int>() ?? List.empty();
    attachments.refresh();

    contentLength.value = contentController.text.length;
  }

  String? get title {
    if (titleController.text.isEmpty) return null;
    return titleController.text;
  }

  String? get description {
    if (descriptionController.text.isEmpty) return null;
    return descriptionController.text;
  }

  Map<String, dynamic> get payload {
    return {
      'title': title,
      'description': description,
      'content': contentController.text,
      'tags': tagController.getTags?.map((x) => {'alias': x}).toList() ??
          List.empty(),
      'attachments': attachments,
      'is_draft': isDraft.value,
      if (replyTo.value != null) 'reply_to': replyTo.value!.id,
      if (repostTo.value != null) 'repost_to': repostTo.value!.id,
      if (realmZone.value != null) 'realm': realmZone.value!.alias,
    };
  }

  set payload(Map<String, dynamic> value) {
    titleController.text = value['title'] ?? '';
    descriptionController.text = value['description'] ?? '';
    contentController.text = value['content'] ?? '';
    attachments.value = value['attachments'].cast<int>() ?? List.empty();
    attachments.refresh();
    isDraft.value = value['is_draft'];
    if (value['reply_to'] != null) {
      replyTo.value = Post.fromJson(value['reply_to']);
    }
    if (value['repost_to'] != null) {
      repostTo.value = Post.fromJson(value['repost_to']);
    }
    if (value['edit_to'] != null) {
      editTo.value = Post.fromJson(value['edit_to']);
    }
    if (value['realm'] != null) {
      realmZone.value = Realm.fromJson(value['realm']);
    }
  }

  bool get isEmpty {
    if (contentController.text.isEmpty) return true;
    return false;
  }

  bool get isNotEmpty {
    return [
      titleController.text.isNotEmpty,
      descriptionController.text.isNotEmpty,
      contentController.text.isNotEmpty,
      attachments.isNotEmpty,
      tagController.getTags?.isNotEmpty ?? false,
    ].any((x) => x);
  }

  @override
  void dispose() {
    _saveTimer?.cancel();

    contentController.dispose();
    tagController.dispose();
    super.dispose();
  }
}
