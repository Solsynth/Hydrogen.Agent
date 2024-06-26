import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/providers/status.dart';

class AccountStatusAction extends StatelessWidget {
  final bool hasStatus;

  const AccountStatusAction({super.key, this.hasStatus = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'accountChangeStatus'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          Expanded(
            child: ListView(
              children: [
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: StatusController.presetStatuses.entries
                        .map(
                          (x) => ActionChip(
                            avatar: x.value.$1,
                            label: Text(x.value.$2),
                            tooltip: x.value.$3,
                            onPressed: () {},
                          ).paddingOnly(right: 6),
                        )
                        .toList(),
                  ).paddingSymmetric(horizontal: 18),
                ),
                const Divider(thickness: 0.3, height: 0.3)
                    .paddingSymmetric(vertical: 16),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: hasStatus
                      ? const Icon(Icons.edit)
                      : const Icon(Icons.add),
                  title: Text('accountCustomStatus'.tr),
                  onTap: () {},
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.clear),
                  title: Text('accountClearStatus'.tr),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
