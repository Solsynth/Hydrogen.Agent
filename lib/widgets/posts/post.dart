import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/models/post.dart';
import 'package:solian/router.dart';
import 'package:solian/utils/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/posts/comment_list.dart';
import 'package:solian/widgets/posts/content/article.dart';
import 'package:solian/widgets/posts/content/attachment.dart';
import 'package:solian/widgets/posts/content/moment.dart';
import 'package:solian/widgets/posts/post_action.dart';
import 'package:solian/widgets/posts/reaction_list.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

class PostItem extends StatefulWidget {
  final Post item;
  final bool brief;
  final bool ripple;
  final Function? onUpdate;
  final Function? onDelete;
  final Function? onTap;

  const PostItem({
    super.key,
    required this.item,
    this.brief = true,
    this.ripple = true,
    this.onUpdate,
    this.onDelete,
    this.onTap,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  Map<String, dynamic>? reactionList;

  void viewActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => PostItemAction(
        item: widget.item,
        onUpdate: widget.onUpdate,
      ),
    );
  }

  void viewComments() {
    final PagingController<int, Post> commentPaging = PagingController(firstPageKey: 0);

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          children: [
            CommentListHeader(
              related: widget.item,
              paging: commentPaging,
            ),
            Expanded(
              child: CustomScrollView(
                slivers: [
                  CommentList(
                    related: widget.item,
                    dataset: '${widget.item.modelType}s',
                    paging: commentPaging,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget renderContent() {
    switch (widget.item.modelType) {
      case 'article':
        return ArticleContent(item: widget.item, brief: widget.brief);
      default:
        return MomentContent(item: widget.item, brief: widget.brief);
    }
  }

  Widget renderAttachments() {
    if (widget.item.modelType == 'article') return Container();

    if (widget.item.attachments != null && widget.item.attachments!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AttachmentList(
          items: widget.item.attachments!,
          provider: 'interactive',
          noTag: SolianTheme.isLargeScreen(context) && widget.brief,
        ),
      );
    } else {
      return Container();
    }
  }

  Widget renderReactions() {
    return Container(
      height: 48,
      padding: const EdgeInsets.only(top: 8, left: 4, right: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ActionChip(
            avatar: const Icon(Icons.comment),
            label: Text(widget.item.commentCount.toString()),
            tooltip: AppLocalizations.of(context)!.comment,
            onPressed: () => viewComments(),
          ),
          const VerticalDivider(thickness: 0.3, indent: 8, endIndent: 8),
          Expanded(
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
          ),
        ],
      ),
    );
  }

  String getAuthorDescribe() =>
      widget.item.author.description.isNotEmpty ? widget.item.author.description : 'No description yet.';

  @override
  void initState() {
    reactionList = widget.item.reactionList ?? {};
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

    if (widget.brief) {
      content = Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  child: AccountAvatar(
                    source: widget.item.author.avatar,
                    direct: true,
                  ),
                  onTap: () {
                    SolianRouter.router.pushNamed(
                      'users.info',
                      pathParameters: {'user': widget.item.author.name},
                    );
                  },
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...headingParts,
                      Padding(
                        padding: const EdgeInsets.only(left: 12, right: 12, top: 4),
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
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  child: AccountAvatar(
                    source: widget.item.author.avatar,
                    direct: true,
                  ),
                  onTap: () {
                    SolianRouter.router.pushNamed(
                      'users.info',
                      pathParameters: {'user': widget.item.author.name},
                    );
                  },
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: renderContent(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: renderAttachments(),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: renderReactions(),
            ),
          ),
        ],
      );
    }

    if (widget.ripple) {
      return InkWell(
        child: content,
        onTap: () {
          if (widget.onTap != null) widget.onTap!();
        },
        onLongPress: () => viewActions(),
      );
    } else {
      return GestureDetector(
        child: content,
        onTap: () {
          if (widget.onTap != null) widget.onTap!();
        },
        onLongPress: () => viewActions(),
      );
    }
  }
}
