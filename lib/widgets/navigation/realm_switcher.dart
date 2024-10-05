import 'dart:math';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/providers/navigation.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class RealmSwitcher extends StatelessWidget {
  const RealmSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final realms = Get.find<RealmProvider>();
    final navState = Get.find<NavigationStateProvider>();

    return Obx(() {
      return DropdownButtonHideUnderline(
        child: DropdownButton2<Realm?>(
          iconStyleData: const IconStyleData(iconSize: 0),
          isExpanded: true,
          hint: Text(
            'Realm Region',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).hintColor,
            ),
          ),
          items: [null, ...realms.availableRealms]
              .map((Realm? item) => DropdownMenuItem<Realm?>(
                    value: item,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (item != null)
                          AccountAvatar(
                            content: item.avatar,
                            radius: 14,
                            fallbackWidget: const Icon(
                              Icons.workspaces,
                              size: 16,
                            ),
                          )
                        else
                          CircleAvatar(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            radius: 14,
                            child: const Icon(
                              Icons.public,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            item?.name ?? 'global'.tr,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ))
              .toList(),
          value: navState.focusedRealm.value,
          onChanged: (Realm? value) {
            navState.focusedRealm.value = value;
          },
          buttonStyleData: ButtonStyleData(
            height: 48,
            width: max(200, MediaQuery.of(context).size.width * 0.4),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          menuItemStyleData: const MenuItemStyleData(
            height: 48,
          ),
        ),
      );
    });
  }
}
