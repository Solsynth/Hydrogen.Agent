import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/widgets/attachments/attachment_publish.dart';
import 'package:solian/widgets/posts/editor/post_editor_overview.dart';
import 'package:textfield_tags/textfield_tags.dart';

class PostEditorController extends GetxController {
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

  PostEditorController() {
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

  bool get isEmpty {
    if (contentController.text.isEmpty) return true;

    return false;
  }

  @override
  void dispose() {
    contentController.dispose();
    tagController.dispose();
    super.dispose();
  }
}
