import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/providers/last_read.dart';
import 'package:solian/widgets/chat/chat_event.dart';
import 'package:solian/widgets/chat/chat_event_action.dart';

class ChatEventList extends StatelessWidget {
  final String scope;
  final Channel channel;
  final ChatEventController chatController;

  final Function(Event) onEdit;
  final Function(Event) onReply;

  const ChatEventList({
    super.key,
    this.scope = 'global',
    required this.channel,
    required this.chatController,
    required this.onEdit,
    required this.onReply,
  });

  bool _checkMessageMergeable(Event? a, Event? b) {
    if (a == null || b == null) return false;
    if (a.sender.account.id != b.sender.account.id) return false;
    return a.createdAt.difference(b.createdAt).inMinutes <= 3;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      reverse: true,
      slivers: [
        Obx(() {
          return SliverList.builder(
            key: Key('chat-history#${channel.id}'),
            itemCount: chatController.currentEvents.length,
            itemBuilder: (context, index) {
              Get.find<LastReadProvider>().messagesLastReadAt =
                  chatController.currentEvents[index].id;

              bool isMerged = false, hasMerged = false;
              if (index > 0) {
                hasMerged = _checkMessageMergeable(
                  chatController.currentEvents[index - 1].data,
                  chatController.currentEvents[index].data,
                );
              }
              if (index + 1 < chatController.currentEvents.length) {
                isMerged = _checkMessageMergeable(
                  chatController.currentEvents[index].data,
                  chatController.currentEvents[index + 1].data,
                );
              }

              final item = chatController.currentEvents[index].data;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                child: ChatEvent(
                  key: Key('m${item!.uuid}'),
                  item: item,
                  isMerged: isMerged,
                  chatController: chatController,
                ).paddingOnly(
                  top: !isMerged ? 8 : 0,
                  bottom: !hasMerged ? 8 : 0,
                ),
                onLongPress: () {
                  showModalBottomSheet(
                    useRootNavigator: true,
                    context: context,
                    builder: (context) => ChatEventAction(
                      channel: channel,
                      realm: channel.realm,
                      item: item,
                      onEdit: () {
                        onEdit(item);
                      },
                      onReply: () {
                        onReply(item);
                      },
                    ),
                  );
                },
              );
            },
          );
        }),
        Obx(() {
          final amount =
              chatController.totalEvents - chatController.currentEvents.length;

          if (amount.value <= 0 || chatController.isLoading.isTrue) {
            return const SliverToBoxAdapter(child: SizedBox.shrink());
          }

          return SliverToBoxAdapter(
            child: ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
              leading: const Icon(Icons.sync_disabled),
              title: Text('messageUnSync'.tr),
              subtitle: Text('messageUnSyncCaption'.trParams({
                'count': amount.string,
              })),
              onTap: () {
                chatController.loadEvents(channel, scope);
              },
            ),
          );
        }),
      ],
    );
  }
}
