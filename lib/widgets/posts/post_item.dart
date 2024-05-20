import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:timeago/timeago.dart' show format;

class PostItem extends StatefulWidget {
  final Post item;

  const PostItem({super.key, required this.item});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late final Post item;

  @override
  void initState() {
    item = widget.item;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachment = item.attachments?.isNotEmpty ?? false;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccountAvatar(content: item.author.avatar.toString()),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        item.author.nick,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ).paddingOnly(left: 12),
                      Text(format(item.createdAt, locale: 'en_short')).paddingOnly(left: 4),
                    ],
                  ),
                  Markdown(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    data: item.content,
                    padding: const EdgeInsets.all(0),
                  ).paddingOnly(left: 12, right: 8),
                ],
              ),
            )
          ],
        ).paddingOnly(
          top: 18,
          bottom: hasAttachment ? 10 : 0,
          right: 16,
          left: 16,
        ),
        AttachmentList(attachmentsId: item.attachments ?? List.empty()),
        PostQuickAction(
          item: widget.item,
          onReact: (symbol, changes) {
            setState(() {
              item.reactionList[symbol] = (item.reactionList[symbol] ?? 0) + changes;
            });
          },
        ).paddingOnly(
          top: hasAttachment ? 10 : 6,
          left: hasAttachment ? 16 : 60,
          right: 16,
          bottom: 10,
        ),
      ],
    );
  }
}
