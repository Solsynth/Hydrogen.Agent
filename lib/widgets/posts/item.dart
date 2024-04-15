import 'package:flutter/material.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/posts/content/article.dart';
import 'package:solian/widgets/posts/content/attachment.dart';
import 'package:solian/widgets/posts/content/moment.dart';
import 'package:solian/widgets/posts/item_action.dart';
import 'package:solian/widgets/posts/reaction_list.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostItem extends StatefulWidget {
  final Post item;
  final bool? brief;
  final Function? onUpdate;
  final Function? onDelete;

  const PostItem({
    super.key,
    required this.item,
    this.brief,
    this.onUpdate,
    this.onDelete,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  Map<String, dynamic>? reactionList;

  void viewActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => PostItemAction(
        item: widget.item,
        onUpdate: widget.onUpdate,
      ),
    );
  }

  Widget renderContent() {
    switch (widget.item.modelType) {
      case 'article':
        return ArticleContent(item: widget.item, brief: widget.brief ?? true);
      default:
        return MomentContent(item: widget.item, brief: widget.brief ?? true);
    }
  }

  Widget renderAttachments() {
    if (widget.item.modelType == 'article') return Container();

    if (widget.item.attachments != null &&
        widget.item.attachments!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AttachmentList(items: widget.item.attachments!),
      );
    } else {
      return Container();
    }
  }

  Widget renderReactions() {
    if (reactionList != null && reactionList!.isNotEmpty) {
      return Container(
        height: 48,
        padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
        child: ReactionList(
          item: widget.item,
          reactionList: reactionList,
          onReact: (symbol, changes) {
            setState(() {
              if (!reactionList!.containsKey(symbol)) {
                reactionList![symbol] = 0;
              }
              reactionList![symbol] += changes;
            });
          },
        ),
      );
    } else {
      return Container();
    }
  }

  String getAuthorDescribe() => widget.item.author.description.isNotEmpty
      ? widget.item.author.description
      : 'No description yet.';

  @override
  void initState() {
    reactionList = widget.item.reactionList;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final headingParts = [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              widget.item.author.nick,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 4),
            Text(timeago.format(widget.item.createdAt))
          ],
        ),
      ),
    ];

    Widget content;

    if (widget.brief ?? true) {
      content = Padding(
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
                      ...headingParts,
                      Padding(
                        padding:
                            const EdgeInsets.only(left: 12, right: 12, top: 4),
                        child: renderContent(),
                      ),
                      renderAttachments(),
                      renderReactions(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      content = Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(widget.item.author.avatar),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...headingParts,
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          getAuthorDescribe(),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Divider(thickness: 0.3),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: renderContent(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: renderAttachments(),
          )
        ],
      );
    }

    return GestureDetector(
      child: content,
      onLongPress: () {
        viewActions(context);
      },
    );
  }
}
