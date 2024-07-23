import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/posts/post_item.dart';

class PostOwnedListEntry extends StatelessWidget {
  final Post item;
  final Function onTap;

  const PostOwnedListEntry({
    super.key,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PostItem(
              key: Key('p${item.id}'),
              item: item,
              isShowEmbed: false,
              isClickable: false,
              isShowReply: false,
              isReactable: false,
            ).paddingSymmetric(vertical: 8),
          ],
        ),
        onTap: () => onTap(),
      ),
    );
  }
}
