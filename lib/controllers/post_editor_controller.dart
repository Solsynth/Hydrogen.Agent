import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/widgets/attachments/attachment_editor.dart';
import 'package:solian/widgets/posts/editor/post_editor_categories_tags.dart';
import 'package:solian/widgets/posts/editor/post_editor_date.dart';
import 'package:solian/widgets/posts/editor/post_editor_overview.dart';
import 'package:solian/widgets/posts/editor/post_editor_publish_zone.dart';
import 'package:solian/widgets/posts/editor/post_editor_thumbnail.dart';
import 'package:solian/widgets/posts/editor/post_editor_visibility.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostEditorController extends GetxController {
  late final SharedPreferences _prefs;

  final aliasController = TextEditingController();
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final contentController = TextEditingController();

  RxInt mode = 0.obs;
  RxInt contentLength = 0.obs;

  Rx<Post?> editTo = Rx(null);
  Rx<Post?> replyTo = Rx(null);
  Rx<Post?> repostTo = Rx(null);
  Rx<Realm?> realmZone = Rx(null);
  Rx<DateTime?> publishedAt = Rx(null);
  Rx<DateTime?> publishedUntil = Rx(null);
  RxList<String> attachments = RxList<String>.empty(growable: true);
  RxList<String> tags = RxList<String>.empty(growable: true);
  Rx<String?> thumbnail = Rx(null);

  RxList<int> visibleUsers = RxList.empty(growable: true);
  RxList<int> invisibleUsers = RxList.empty(growable: true);

  RxInt visibility = 0.obs;
  RxBool isDraft = false.obs;

  RxBool isRestoreFromLocal = false.obs;
  Rx<DateTime?> lastSaveTime = Rx(null);
  Future? _saveFuture;

  PostEditorController() {
    SharedPreferences.getInstance().then((inst) {
      _prefs = inst;
    });
    contentController.addListener(() {
      contentLength.value = contentController.text.length;
      _saveFuture ??= Future.delayed(
        const Duration(seconds: 1),
        () {
          if (isNotEmpty) {
            localSave();
            lastSaveTime.value = DateTime.now();
            lastSaveTime.refresh();
          } else if (_prefs.containsKey('post_editor_local_save')) {
            localClear();
            lastSaveTime.value = null;
          }
          _saveFuture = null;
        },
      );
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

  Future<void> editVisibility(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => PostEditorVisibilityDialog(
        controller: this,
      ),
    );
  }

  Future<void> editCategoriesAndTags(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => PostEditorCategoriesDialog(
        controller: this,
      ),
    );
  }

  Future<void> editPublishZone(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => PostEditorPublishZoneDialog(
        controller: this,
      ),
    );
  }

  Future<void> editPublishDate(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => PostEditorDateDialog(
        controller: this,
      ),
    );
  }

  Future<void> editAttachment(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => AttachmentEditorPopup(
        pool: 'interactive',
        initialAttachments: attachments,
        onAdd: (String value) {
          attachments.add(value);
        },
        onRemove: (String value) {
          attachments.remove(value);
        },
        onInsert: (String str) {
          final text = contentController.text;
          final selection = contentController.selection;
          final newText = text.replaceRange(
            selection.start,
            selection.end,
            str,
          );
          contentController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
              offset: selection.baseOffset + str.length,
            ),
          );
        },
      ),
    );
  }

  Future<void> editThumbnail(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => PostEditorThumbnailDialog(
        controller: this,
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
        'type': type,
      }),
    );
  }

  Future<bool> localRead() async {
    final inst = await SharedPreferences.getInstance();
    if (inst.containsKey('post_editor_local_save')) {
      isRestoreFromLocal.value = true;
      payload = jsonDecode(inst.getString('post_editor_local_save')!);
      return true;
    }
    return false;
  }

  void localClear() {
    _prefs.remove('post_editor_local_save');
  }

  void currentClear() {
    aliasController.clear();
    titleController.clear();
    descriptionController.clear();
    contentController.clear();
    attachments.clear();
    tags.clear();
    visibleUsers.clear();
    invisibleUsers.clear();
    visibility.value = 0;
    thumbnail.value = null;
    publishedAt.value = null;
    publishedUntil.value = null;
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

    type = value.type;
    editTo.value = value;
    realmZone.value = value.realm;
    isDraft.value = value.isDraft ?? false;
    aliasController.text = value.alias ?? '';
    titleController.text = value.body['title'] ?? '';
    descriptionController.text = value.body['description'] ?? '';
    contentController.text = value.body['content'] ?? '';
    publishedAt.value = value.publishedAt;
    publishedUntil.value = value.publishedUntil;
    tags.value = List.from(
      value.body['tags']?.map((x) => x['alias']).toList() ?? List.empty(),
      growable: true,
    );
    tags.refresh();
    attachments.value = List.from(
      value.body['attachments'] ?? List.empty(),
      growable: true,
    );
    attachments.refresh();
    thumbnail.value = value.body['thumbnail'];

    contentLength.value = contentController.text.length;
  }

  String get typeEndpoint {
    switch (mode.value) {
      case 0:
        return 'stories';
      case 1:
        return 'articles';
      default:
        return 'stories';
    }
  }

  String get type {
    switch (mode.value) {
      case 0:
        return 'story';
      case 1:
        return 'article';
      default:
        return 'story';
    }
  }

  set type(String value) {
    switch (value) {
      case 'story':
        mode.value = 0;
      case 'article':
        mode.value = 1;
    }
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
      'alias': aliasController.text,
      'title': title,
      'description': description,
      'content': contentController.text,
      'thumbnail': thumbnail.value,
      'tags': tags.map((x) => {'alias': x}).toList(),
      'attachments': attachments,
      'visible_users': visibleUsers,
      'invisible_users': invisibleUsers,
      'visibility': visibility.value,
      'published_at': publishedAt.value?.toUtc().toIso8601String() ??
          DateTime.now().toUtc().toIso8601String(),
      'published_until': publishedUntil.value?.toUtc().toIso8601String(),
      'is_draft': isDraft.value,
      if (replyTo.value != null) 'reply_to': replyTo.value!.id,
      if (repostTo.value != null) 'repost_to': repostTo.value!.id,
      if (realmZone.value != null) 'realm': realmZone.value!.alias,
    };
  }

  set payload(Map<String, dynamic> value) {
    type = value['type'];
    tags.value = List.from(
      value['tags'].map((x) => x['alias']).toList(),
      growable: true,
    );
    aliasController.text = value['alias'] ?? '';
    titleController.text = value['title'] ?? '';
    descriptionController.text = value['description'] ?? '';
    contentController.text = value['content'] ?? '';
    attachments.value = List.from(
      value['attachments'] ?? List.empty(),
      growable: true,
    );
    attachments.refresh();
    thumbnail.value = value['thumbnail'];
    visibility.value = value['visibility'];
    isDraft.value = value['is_draft'];
    if (value['visible_users'] != null) {
      visibleUsers.value = List.from(
        value['visible_users'],
        growable: true,
      );
    }
    if (value['invisible_users'] != null) {
      invisibleUsers.value = List.from(
        value['invisible_users'],
        growable: true,
      );
    }
    if (value['published_at'] != null) {
      publishedAt.value = DateTime.parse(value['published_at']).toLocal();
    }
    if (value['published_until'] != null) {
      publishedAt.value = DateTime.parse(value['published_until']).toLocal();
    }
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
      aliasController.text.isNotEmpty,
      titleController.text.isNotEmpty,
      descriptionController.text.isNotEmpty,
      contentController.text.isNotEmpty,
      attachments.isNotEmpty,
      tags.isNotEmpty,
      thumbnail.value != null,
    ].any((x) => x);
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    contentController.dispose();
    super.dispose();
  }
}
