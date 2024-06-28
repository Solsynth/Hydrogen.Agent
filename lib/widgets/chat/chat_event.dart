import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/models/event.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';
import 'package:solian/widgets/chat/chat_event_action_log.dart';
import 'package:solian/widgets/chat/chat_event_message.dart';
import 'package:timeago/timeago.dart' show format;

class ChatEvent extends StatelessWidget {
  final Event item;
  final bool isContentPreviewing;
  final bool isQuote;
  final bool isMerged;
  final bool isHasMerged;

  final ChatEventController? chatController;

  const ChatEvent({
    super.key,
    required this.item,
    this.isContentPreviewing = false,
    this.isMerged = false,
    this.isHasMerged = false,
    this.isQuote = false,
    this.chatController,
  });

  String _formatDuration(Duration duration) {
    String negativeSign = duration.isNegative ? '-' : '';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
    return '$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  Widget buildQuote() {
    return FutureBuilder(
      future: chatController!.getEvent(
        item.body['quote_event'],
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }

        return ChatEvent(
          item: snapshot.data!.data,
          isMerged: false,
          isQuote: true,
        ).paddingOnly(left: isMerged ? 52 : 0);
      },
    );
  }

  Widget buildContent() {
    switch (item.type) {
      case 'messages.new':
        return ChatEventMessage(
          item: item,
          isContentPreviewing: isContentPreviewing,
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'messages.edit':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.edit_note, size: 16),
          text: 'messageEditDesc'.trParams({'id': '#${item.id}'}),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'messages.delete':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.cancel_schedule_send, size: 16),
          text: 'messageDeleteDesc'.trParams({'id': '#${item.id}'}),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'calls.start':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.call_made, size: 16),
          text: 'messageCallStartDesc'
              .trParams({'user': '@${item.sender.account.name}'}),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'calls.end':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.call_received, size: 16),
          text: 'messageCallEndDesc'.trParams({
            'duration': _formatDuration(
              Duration(seconds: item.body['last']),
            ),
          }),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      case 'system.changes':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.manage_history, size: 16),
          text: item.body['text'],
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
      default:
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.error, size: 16),
          text: 'messageTypeUnsupported'.trParams({'type': item.type}),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
          isQuote: isQuote,
        );
    }
  }

  Widget buildBody(BuildContext context) {
    if (isContentPreviewing || (isMerged && !isQuote)) {
      return Column(
        children: [
          if (item.body['quote_event'] != null && chatController != null)
            buildQuote(),
          buildContent(),
        ],
      );
    } else if (isQuote) {
      return Card(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Opacity(
              opacity: 0.75,
              child: FaIcon(FontAwesomeIcons.quoteLeft, size: 14),
            ).paddingOnly(bottom: 2.75),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AccountAvatar(
                          content: item.sender.account.avatar, radius: 9),
                      const SizedBox(width: 5),
                      Text(
                        item.sender.account.nick,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(format(item.createdAt, locale: 'en_short')),
                    ],
                  ),
                  buildContent().paddingOnly(left: 0.5),
                ],
              ),
            ),
          ],
        ).paddingOnly(left: 12, right: 12, top: 8, bottom: 4),
      ).paddingOnly(left: isMerged ? 52 : 0, right: 4);
    } else {
      return Column(
        key: Key('m${item.uuid}'),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                child: AccountAvatar(content: item.sender.account.avatar),
                onTap: () {
                  showModalBottomSheet(
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    context: context,
                    builder: (context) => AccountProfilePopup(
                      account: item.sender.account,
                    ),
                  );
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.sender.account.nick,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        Text(format(item.createdAt, locale: 'en_short'))
                      ],
                    ).paddingSymmetric(horizontal: 12),
                    if (item.body['quote_event'] != null &&
                        chatController != null)
                      buildQuote(),
                    buildContent(),
                  ],
                ),
              ),
            ],
          ).paddingSymmetric(horizontal: 12),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return buildBody(context);
  }
}
