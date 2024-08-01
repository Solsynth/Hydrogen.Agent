import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/post_editor_controller.dart';
import 'package:solian/providers/content/realm.dart';

class PostEditorPublishZoneDialog extends StatelessWidget {
  final PostEditorController controller;

  const PostEditorPublishZoneDialog({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final RealmProvider realms = Get.find();

    return AlertDialog(
      title: Text('postPublishZone'.tr),
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
              items: [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text(
                    'postPublishZoneNone'.tr,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                ...realms.availableRealms.map(
                  (x) => DropdownMenuItem<int>(
                    value: x.id,
                    child: Text(
                      '${x.name} (${x.alias})',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
              value: controller.realmZone.value?.id,
              onChanged: (int? value) {
                if (value == null) {
                  controller.realmZone.value = null;
                } else {
                  controller.realmZone.value =
                      realms.availableRealms.firstWhere((x) => x.id == value);
                }
              },
              buttonStyleData: const ButtonStyleData(height: 20),
              menuItemStyleData: const MenuItemStyleData(height: 40),
            );
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
