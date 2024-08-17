import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/post_editor_controller.dart';
import 'package:solian/widgets/posts/editor/post_tags_field.dart';

class PostEditorCategoriesDialog extends StatelessWidget {
  final PostEditorController controller;

  const PostEditorCategoriesDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('postCategoriesAndTags'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TagsField(
            initialTags: controller.tags,
            hintText: 'postTagsPlaceholder'.tr,
            onUpdate: (value) {
              controller.tags.value = List.from(value, growable: true);
              controller.tags.refresh();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
