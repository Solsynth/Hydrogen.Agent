import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:solian/models/message.dart';
import 'package:solian/widgets/chat/content.dart';
import 'package:solian/widgets/posts/content/attachment.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:math' as math;

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

  Widget renderReply() {
    final padding =
        underMerged ? const EdgeInsets.only(left: 14, right: 8, top: 4) : const EdgeInsets.only(left: 8, right: 8);

    if (item.replyTo != null) {
      return Row(
        children: [
          Container(
            padding: padding,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(math.pi),
                    child: const Icon(Icons.reply, size: 16),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: NetworkImage(item.replyTo!.sender.account.avatar),
                  ),
                ]),
          ),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, top: 2),
                  child: ChatMessageContent(item: item.replyTo!),
                ),
                renderAttachment()
              ],
            ),
          ),
        ],
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
          Expanded(
            child: Column(
              children: [renderReply(), contentPart, renderAttachment()],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          renderReply(),
          Row(
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
          ),
        ],
      );
    }
  }
}
