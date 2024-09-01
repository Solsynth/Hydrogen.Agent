import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/screens/account/notification.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final WebSocketProvider _ws = Get.find();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return ListView(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('today'.tr, style: Theme.of(context).textTheme.headlineSmall),
            Text(DateFormat('yyyy/MM/dd').format(DateTime.now())),
          ],
        ).paddingOnly(top: 8, left: 18, right: 18),
        const Divider(thickness: 0.3).paddingSymmetric(vertical: 8),
        Obx(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'notification'.tr,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium!
                            .copyWith(fontSize: 18),
                      ),
                      Text(
                        'notificationUnreadCount'.trParams({
                          'count': _ws.notifications.length.toString(),
                        }),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      showModalBottomSheet(
                        useRootNavigator: true,
                        isScrollControlled: true,
                        context: context,
                        builder: (context) => const NotificationScreen(),
                      ).then((_) => _ws.notificationUnread.value = 0);
                    },
                  ),
                ],
              ).paddingOnly(left: 18, right: 18, bottom: 8),
              if (_ws.notifications.isNotEmpty)
                SizedBox(
                  height: 76,
                  width: width,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: min(_ws.notifications.length, 3),
                    itemBuilder: (context, idx) {
                      final x = _ws.notifications[idx];
                      return SizedBox(
                        width: width,
                        child: Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            title: Text(x.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (x.subtitle != null) Text(x.subtitle!),
                                Text(x.body),
                              ],
                            ),
                          ),
                        ).paddingSymmetric(horizontal: 8),
                      );
                    },
                  ),
                )
              else
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    trailing: const Icon(Icons.inbox_outlined),
                    title: Text('notifyEmpty'.tr),
                    subtitle: Text('notifyEmptyCaption'.tr),
                  ),
                ).paddingSymmetric(horizontal: 8),
            ],
          ),
        ),
      ],
    );
  }
}
