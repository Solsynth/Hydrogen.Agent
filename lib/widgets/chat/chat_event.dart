import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
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

  const ChatEvent({
    super.key,
    required this.item,
    this.isContentPreviewing = false,
    this.isMerged = false,
    this.isHasMerged = false,
    this.isQuote = false,
  });

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
        );
      case 'messages.delete':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.cancel_schedule_send, size: 16),
          text: 'messageDeleteDesc'.trParams({'id': '#${item.id}'}),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
        );
      case 'system.changes':
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.manage_history, size: 16),
          text: item.body['text'],
          isMerged: isMerged,
          isHasMerged: isHasMerged,
        );
      default:
        return ChatEventMessageActionLog(
          icon: const Icon(Icons.error, size: 16),
          text: 'messageTypeUnsupported'.trParams({'type': item.type}),
          isMerged: isMerged,
          isHasMerged: isHasMerged,
        );
    }
  }

  Widget buildBody(BuildContext context) {
    if (isContentPreviewing || isMerged) {
      return buildContent();
    } else if (isQuote) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.scale(
            scaleX: -1,
            child: const FaIcon(FontAwesomeIcons.reply, size: 14),
          ),
          const SizedBox(width: 12),
          AccountAvatar(content: item.sender.account.avatar, radius: 8),
          const SizedBox(width: 4),
          Text(
            item.sender.account.nick,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: buildContent()),
        ],
      );
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
