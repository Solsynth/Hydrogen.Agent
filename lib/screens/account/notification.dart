import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/providers/account.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/models/notification.dart' as notify;
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool _isBusy = false;

  Future<void> markAllRead() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    setState(() => _isBusy = true);

    final AccountProvider provider = Get.find();

    List<int> markList = List.empty(growable: true);
    for (final element in provider.notifications) {
      if (element.isRealtime) continue;
      markList.add(element.id);
    }

    if (markList.isNotEmpty) {
      final client = auth.configureClient(service: 'passport');

      await client.put('/api/notifications/batch/read', {'messages': markList});
    }

    provider.notifications.clear();

    setState(() => _isBusy = false);
  }

  Future<void> markOneRead(notify.Notification element, int index) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final AccountProvider provider = Get.find();

    if (element.isRealtime) {
      provider.notifications.removeAt(index);
      return;
    }

    setState(() => _isBusy = true);

    final client = auth.configureClient(service: 'passport');

    await client.put('/api/notifications/${element.id}/read', {});

    provider.notifications.removeAt(index);

    setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    final AccountProvider provider = Get.find();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'notification'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          Expanded(
            child: Obx(() {
              return CustomScrollView(
                slivers: [
                  if (_isBusy)
                    SliverToBoxAdapter(
                      child: const LinearProgressIndicator().animate().scaleX(),
                    ),
                  if (provider.notifications.isEmpty)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        color:
                            Theme.of(context).colorScheme.surfaceContainerHigh,
                        child: ListTile(
                          leading: const Icon(Icons.check),
                          title: Text('notifyEmpty'.tr),
                          subtitle: Text('notifyEmptyCaption'.tr),
                        ),
                      ),
                    ),
                  if (provider.notifications.isNotEmpty)
                    SliverToBoxAdapter(
                      child: ListTile(
                        tileColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        leading: const Icon(Icons.checklist),
                        title: Text('notifyAllRead'.tr),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 28),
                        onTap: _isBusy ? null : () => markAllRead(),
                      ),
                    ),
                  SliverList.separated(
                    itemCount: provider.notifications.length,
                    itemBuilder: (BuildContext context, int index) {
                      var element = provider.notifications[index];
                      return Dismissible(
                        key: Key(const Uuid().v4()),
                        background: Container(
                          color: Colors.lightBlue,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          title: Text(element.subject),
                          subtitle: Column(
                            children: [
                              Text(element.content),
                              if (element.links != null)
                                Row(
                                  children: element.links!
                                      .map((e) => InkWell(
                                            child: Text(
                                              e.label,
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSecondaryContainer,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                            ),
                                            onTap: () {
                                              launchUrlString(e.url);
                                            },
                                          ).paddingOnly(right: 5))
                                      .toList(),
                                ),
                            ],
                          ),
                        ),
                        onDismissed: (_) => markOneRead(element, index),
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const Divider(thickness: 0.3, height: 0.3),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AccountProvider provider = Get.find();

    final button = IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        showModalBottomSheet(
          useRootNavigator: true,
          isScrollControlled: true,
          context: context,
          builder: (context) => const NotificationScreen(),
        ).then((_) => provider.notificationUnread.value = 0);
      },
    );

    return Obx(() {
      if (provider.notificationUnread.value > 0) {
        return Badge(
          isLabelVisible: true,
          offset: const Offset(-8, 2),
          label: Text(provider.notificationUnread.value.toString()),
          child: button,
        );
      } else {
        return button;
      }
    });
  }
}
