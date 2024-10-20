import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/models/notification.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/notifications.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/loading_indicator.dart';
import 'package:solian/widgets/markdown_text_content.dart';
import 'package:solian/widgets/posts/post_item.dart';
import 'package:solian/widgets/relative_date.dart';
import 'package:uuid/uuid.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  @override
  Widget build(BuildContext context) {
    final NotificationProvider nty = Get.find();

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
              return RefreshIndicator(
                onRefresh: () => nty.fetchNotification(),
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: LoadingIndicator(
                        isActive: nty.isBusy.value,
                      ),
                    ),
                    if (nty.notifications
                        .where((x) => x.readAt == null)
                        .isEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          child: ListTile(
                            leading: const Icon(Icons.check),
                            title: Text('notifyEmpty'.tr),
                            subtitle: Text('notifyEmptyCaption'.tr),
                          ),
                        ),
                      ),
                    if (nty.notifications
                        .where((x) => x.readAt == null)
                        .isNotEmpty)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          color:
                              Theme.of(context).colorScheme.secondaryContainer,
                          child: ListTile(
                            leading: const Icon(Icons.checklist),
                            title: Text('notifyAllRead'.tr),
                            onTap: nty.isBusy.value
                                ? null
                                : () => nty.markAllRead(),
                          ),
                        ),
                      ),
                    SliverList.separated(
                      itemCount: nty.notifications.length,
                      itemBuilder: (BuildContext context, int index) {
                        var element = nty.notifications[index];
                        return ClipRect(
                          child: Dismissible(
                            direction: element.readAt == null
                                ? DismissDirection.horizontal
                                : DismissDirection.none,
                            key: Key(const Uuid().v4()),
                            background: Container(
                              color: Colors.lightBlue,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerLeft,
                              child:
                                  const Icon(Icons.check, color: Colors.white),
                            ),
                            secondaryBackground: Container(
                              color: Colors.lightBlue,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              alignment: Alignment.centerRight,
                              child:
                                  const Icon(Icons.check, color: Colors.white),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(NotificationTopicIcons[element.topic]),
                                  const Gap(16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (element.readAt == null)
                                          Badge(
                                            label: Row(
                                              children: [
                                                Icon(
                                                  Icons.new_releases_outlined,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  size: 12,
                                                ),
                                                const Gap(4),
                                                Text('unread'.tr),
                                              ],
                                            ),
                                          ).paddingOnly(bottom: 4),
                                        Text(
                                          element.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        if (element.subtitle != null)
                                          Text(
                                            element.subtitle!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall,
                                          ),
                                        if (element.subtitle != null)
                                          const Gap(4),
                                        MarkdownTextContent(
                                          content: element.body,
                                          isAutoWarp: true,
                                          isSelectable: true,
                                          parentId:
                                              'notification-${element.id}',
                                        ),
                                        if ([
                                              'interactive.feedback',
                                              'interactive.subscription'
                                            ].contains(element.topic) &&
                                            element.metadata?['related_post'] !=
                                                null)
                                          _PostRelatedNotificationWidget(
                                            metadata: element.metadata!,
                                          ),
                                        const Gap(8),
                                        Opacity(
                                          opacity: 0.75,
                                          child: Row(
                                            children: [
                                              RelativeDate(
                                                element.createdAt,
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              const Gap(4),
                                              Text(
                                                '·',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              const Gap(4),
                                              RelativeDate(
                                                element.createdAt,
                                                style: TextStyle(fontSize: 12),
                                                isFull: true,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            onDismissed: (_) => nty.markOneRead(element, index),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) =>
                          const Divider(thickness: 0.3, height: 0.3),
                    ),
                  ],
                ),
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
    final NotificationProvider nty = Get.find();

    final button = IconButton(
      icon: const Icon(Icons.notifications),
      onPressed: () {
        showModalBottomSheet(
          useRootNavigator: true,
          isScrollControlled: true,
          context: context,
          builder: (context) => const NotificationScreen(),
        ).then((_) => nty.notificationUnread.value = 0);
      },
    );

    return Obx(() {
      if (nty.notificationUnread.value > 0) {
        return Badge(
          isLabelVisible: true,
          offset: const Offset(-8, 2),
          label: Text(nty.notificationUnread.value.toString()),
          child: button,
        );
      } else {
        return button;
      }
    });
  }
}

class _PostRelatedNotificationWidget extends StatelessWidget {
  final Map<String, dynamic> metadata;

  const _PostRelatedNotificationWidget({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: PostItem(
          item: Post.fromJson(metadata['related_post']),
          isCompact: true,
        ).paddingAll(8),
      ),
      onTap: () {
        final data = Post.fromJson(metadata['related_post']);
        Navigator.pop(context);
        AppRouter.instance.pushNamed(
          'postDetail',
          pathParameters: {'id': data.id.toString()},
          extra: data,
        );
      },
    );
  }
}
