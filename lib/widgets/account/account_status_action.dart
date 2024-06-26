import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/account_status.dart';

class AccountStatusAction extends StatefulWidget {
  final bool hasStatus;

  const AccountStatusAction({super.key, this.hasStatus = false});

  @override
  State<AccountStatusAction> createState() => _AccountStatusActionState();
}

class _AccountStatusActionState extends State<AccountStatusAction> {
  bool _isBusy = false;

  @override
  Widget build(BuildContext context) {
    final StatusProvider controller = Get.find();

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'accountChangeStatus'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          if (_isBusy)
            const LinearProgressIndicator()
                .paddingOnly(bottom: 14)
                .animate()
                .slideY(curve: Curves.fastEaseInToSlowEaseOut),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: StatusProvider.presetStatuses.entries
                  .map(
                    (x) => ActionChip(
                      avatar: x.value.$1,
                      label: Text(x.value.$2),
                      tooltip: x.value.$3,
                      onPressed: _isBusy
                          ? null
                          : () async {
                              setState(() => _isBusy = true);
                              try {
                                await controller.setStatus(
                                  x.key,
                                  x.value.$2,
                                  0,
                                  isInvisible: x.key == 'invisible',
                                  isSilent: x.key == 'silent',
                                );
                                Navigator.of(context).pop(true);
                              } catch (e) {
                                context.showErrorDialog(e);
                              }
                              setState(() => _isBusy = false);
                            },
                    ).paddingOnly(right: 6),
                  )
                  .toList(),
            ).paddingSymmetric(horizontal: 18),
          ),
          const Divider(thickness: 0.3, height: 0.3)
              .paddingSymmetric(vertical: 16),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: widget.hasStatus
                ? const Icon(Icons.edit)
                : const Icon(Icons.add),
            title: Text('accountCustomStatus'.tr),
            onTap: _isBusy ? null : () {},
          ),
          if (widget.hasStatus)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              leading: const Icon(Icons.clear),
              title: Text('accountClearStatus'.tr),
              onTap: _isBusy
                  ? null
                  : () async {
                      setState(() => _isBusy = true);
                      try {
                        await controller.clearStatus();
                        Navigator.of(context).pop(true);
                      } catch (e) {
                        context.showErrorDialog(e);
                      }
                      setState(() => _isBusy = false);
                    },
            ),
        ],
      ),
    );
  }
}
