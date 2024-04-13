import 'package:flutter/material.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/posts/content/article.dart';
import 'package:solian/widgets/posts/content/attachment.dart';
import 'package:solian/widgets/posts/content/moment.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostItem extends StatefulWidget {
  final Post item;
  final bool? brief;

  const PostItem({super.key, required this.item, this.brief});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  Map<String, dynamic>? reactionList;

  Widget renderContent() {
    switch (widget.item.modelType) {
      case "article":
        return ArticleContent(item: widget.item, brief: widget.brief ?? true);
      default:
        return MomentContent(item: widget.item, brief: widget.brief ?? true);
    }
  }

  Widget renderAttachments() {
    if(widget.item.attachments != null && widget.item.attachments!.isNotEmpty) {
      return AttachmentList(items: widget.item.attachments!);
    } else {
      return Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(widget.item.author.avatar),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Text(
                            widget.item.author.nick,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeago.format(widget.item.createdAt)
                          )
                        ],
                      ),
                    ),
                    renderContent(),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: renderAttachments(),
          ),
        ],
      ),
    );
  }
}
