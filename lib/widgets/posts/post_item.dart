import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:timeago/timeago.dart' show format;

class PostItem extends StatefulWidget {
  final Post item;

  const PostItem({super.key, required this.item});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AccountAvatar(content: widget.item.author.avatar),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Text(widget.item.author.nick, style: const TextStyle(fontWeight: FontWeight.bold)).paddingOnly(left: 8),
                  Text(format(widget.item.createdAt, locale: 'en_short')).paddingOnly(left: 4),
                ],
              ),
              Markdown(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                data: widget.item.content,
                padding: const EdgeInsets.all(0),
              ).paddingSymmetric(horizontal: 8),
            ],
          ),
        )
      ],
    );
  }
}
