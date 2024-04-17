import 'package:flutter/material.dart';
import 'package:solian/models/message.dart';
import 'package:solian/widgets/chat/content.dart';
import 'package:solian/widgets/posts/content/attachment.dart';
import 'package:timeago/timeago.dart' as timeago;

class ChatMessage extends StatelessWidget {
  final Message item;
  final bool underMerged;

  const ChatMessage({super.key, required this.item, required this.underMerged});

  Widget renderAttachment() {
    if (item.attachments != null && item.attachments!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: AttachmentList(items: item.attachments!, provider: 'messaging'),
      );
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentPart = Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, top: 2),
      child: ChatMessageContent(item: item),
    );

    final userinfoPart = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Text(
            item.sender.account.nick,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 4),
          Text(timeago.format(item.createdAt))
        ],
      ),
    );

    if (underMerged) {
      return Row(
        children: [
          const SizedBox(width: 40),
          Expanded(child: contentPart),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(item.sender.account.avatar),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                userinfoPart,
                contentPart,
                renderAttachment(),
              ],
            ),
          ),
        ],
      );
    }
  }
}
