import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/post_editor_controller.dart';
import 'package:solian/widgets/account/account_select.dart';

class PostEditorVisibilityDialog extends StatelessWidget {
  final PostEditorController controller;

  const PostEditorVisibilityDialog({super.key, required this.controller});

  static List<(int, String)> visibilityLevels = [
    (0, 'postVisibilityAll'),
    (1, 'postVisibilityFriends'),
    (2, 'postVisibilitySelected'),
    (3, 'postVisibilityFiltered'),
    (4, 'postVisibilityNone'),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('postVisibility'.tr),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() {
            return DropdownButtonFormField2<int>(
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
              ),
              items: visibilityLevels
                  .map(
                    (entry) => DropdownMenuItem<int>(
                      value: entry.$1,
                      child: Text(
                        entry.$2.tr,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  )
                  .toList(),
              value: controller.visibility.value,
              onChanged: (int? value) {
                if (value != null) {
                  controller.visibility.value = value;
                }
              },
              buttonStyleData: const ButtonStyleData(height: 20),
              menuItemStyleData: const MenuItemStyleData(height: 40),
            );
          }),
          Obx(() {
            if (controller.visibility.value != 2 &&
                controller.visibility.value != 3) {
              return const SizedBox(height: 8);
            }
            return const SizedBox();
          }),
          Obx(() {
            if (controller.visibility.value == 2) {
              return ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.only(left: 16, right: 13),
                trailing: const Icon(Icons.chevron_right),
                title: Text('postVisibleUsers'.tr),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => AccountSelector(
                      title: 'postVisibleUsers'.tr,
                      initialSelection: controller.visibleUsers,
                      onMultipleSelect: (value) {
                        controller.visibleUsers.value =
                            value.map((e) => e.id).toList();
                        controller.visibleUsers.refresh();
                      },
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          }),
          Obx(() {
            if (controller.visibility.value == 3) {
              return ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                contentPadding: const EdgeInsets.only(left: 16, right: 13),
                trailing: const Icon(Icons.chevron_right),
                title: Text('postInvisibleUsers'.tr),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) => AccountSelector(
                      title: 'postInvisibleUsers'.tr,
                      initialSelection: controller.invisibleUsers,
                      onMultipleSelect: (value) {
                        controller.invisibleUsers.value =
                            value.map((e) => e.id).toList();
                        controller.invisibleUsers.refresh();
                      },
                    ),
                  );
                },
              );
            }
            return const SizedBox();
          }),
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
