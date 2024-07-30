import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/post_editor_controller.dart';

class PostEditorOverviewDialog extends StatelessWidget {
  final PostEditorController controller;

  const PostEditorOverviewDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('postOverview'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            autofocus: true,
            autocorrect: true,
            controller: controller.titleController,
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              hintText: 'title'.tr,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          const SizedBox(height: 16),
          TextField(
            enabled: controller.mode.value == 1,
            maxLines: null,
            autofocus: true,
            autocorrect: true,
            keyboardType: TextInputType.multiline,
            controller: controller.descriptionController,
            decoration: InputDecoration(
              border: const UnderlineInputBorder(),
              hintText: 'description'.tr,
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
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
