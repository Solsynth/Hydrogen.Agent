import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/providers/last_read.dart';
import 'package:solian/widgets/chat/chat_event.dart';
import 'package:solian/widgets/chat/chat_event_action.dart';
import 'package:very_good_infinite_list/very_good_infinite_list.dart';

class ChatEventList extends StatelessWidget {
  final bool noAnimated;
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
    this.noAnimated = false,
  });

  bool _checkMessageMergeable(Event? a, Event? b) {
    if (a == null || b == null) return false;
    if (a.sender.account.id != b.sender.account.id) return false;
    return a.createdAt.difference(b.createdAt).inMinutes <= 3;
  }

  void _openActions(BuildContext context, Event item) {
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
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      cacheExtent: 100,
      reverse: true,
      slivers: [
        Obx(() {
          return SliverInfiniteList(
            key: Key('chat-history#${channel.id}'),
            isLoading: chatController.isLoading.value,
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

              return TapRegion(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  child: Builder(builder: (context) {
                    final widget = ChatEvent(
                      key: Key('m${item!.uuid}'),
                      item: item,
                      isMerged: isMerged,
                      chatController: chatController,
                    ).paddingOnly(
                      top: !isMerged ? 8 : 0,
                      bottom: !hasMerged ? 8 : 0,
                    );

                    if (noAnimated) {
                      return widget;
                    } else {
                      return widget
                          .animate(
                            key: Key('animated-m${item.uuid}'),
                          )
                          .slideY(
                            curve: Curves.fastLinearToSlowEaseIn,
                            duration: 250.ms,
                            begin: 0.5,
                            end: 0,
                          );
                    }
                  }),
                  onLongPress: () {
                    _openActions(context, item!);
                  },
                ),
                onTapInside: (event) {
                  if (event.buttons == kSecondaryMouseButton) {
                    _openActions(context, item!);
                  } else if (event.buttons == kMiddleMouseButton) {
                    onReply(item!);
                  }
                },
              );
            },
            onFetchData: () {
              if (chatController.currentEvents.length <
                  chatController.totalEvents.value) {
                chatController.loadEvents(
                  chatController.channel!,
                  chatController.scope!,
                );
              }
            },
          );
        }),
      ],
    );
  }
}
