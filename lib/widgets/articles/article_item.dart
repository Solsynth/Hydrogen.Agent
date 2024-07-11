import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/articles.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';
import 'package:solian/widgets/articles/article_quick_action.dart';
import 'package:solian/widgets/markdown_text_content.dart';
import 'package:solian/widgets/feed/feed_tags.dart';
import 'package:timeago/timeago.dart' show format;

class ArticleItem extends StatefulWidget {
  final Article item;
  final bool isClickable;
  final bool isReactable;
  final bool isFullDate;
  final bool isFullContent;
  final String? overrideAttachmentParent;

  const ArticleItem({
    super.key,
    required this.item,
    this.isClickable = false,
    this.isReactable = true,
    this.isFullDate = false,
    this.isFullContent = false,
    this.overrideAttachmentParent,
  });

  @override
  State<ArticleItem> createState() => _ArticleItemState();
}

class _ArticleItemState extends State<ArticleItem> {
  late final Article item;

  @override
  void initState() {
    item = widget.item;
    super.initState();
  }

  Widget buildDate() {
    if (widget.isFullDate) {
      return Text(DateFormat('y/M/d H:m').format(item.createdAt.toLocal()));
    } else {
      return Text(format(item.createdAt.toLocal(), locale: 'en_short'));
    }
  }

  Widget buildHeader() {
    return Row(
      children: [
        Text(
          item.author.nick,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        buildDate().paddingOnly(left: 4),
      ],
    );
  }

  Widget buildFooter() {
    List<String> labels = List.from(['article'.tr], growable: true);
    if (widget.item.createdAt != widget.item.updatedAt) {
      labels.add('postEdited'.trParams({
        'date': DateFormat('yy/M/d H:m').format(item.updatedAt.toLocal()),
      }));
    }
    if (widget.item.realm != null) {
      labels.add('postInRealm'.trParams({
        'realm': '#${widget.item.realm!.alias}',
      }));
    }

    List<Widget> widgets = List.empty(growable: true);

    if (widget.item.tags?.isNotEmpty ?? false) {
      widgets.add(FeedTagsList(tags: widget.item.tags!));
    }
    if (labels.isNotEmpty) {
      widgets.add(Text(
        labels.join(' · '),
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
        ),
      ));
    }

    if (widgets.isEmpty) {
      return const SizedBox();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ).paddingOnly(top: 4);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isFullContent) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AccountAvatar(content: item.author.avatar.toString()),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildHeader(),
                Text(item.title, style: const TextStyle(fontSize: 15)),
                Text(
                  item.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
                ),
                buildFooter(),
              ],
            ).paddingOnly(left: 12),
          ),
        ],
      ).paddingOnly(
        top: 10,
        bottom: 10,
        right: 16,
        left: 16,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              child: AccountAvatar(content: item.author.avatar.toString()),
              onTap: () {
                showModalBottomSheet(
                  useRootNavigator: true,
                  isScrollControlled: true,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  context: context,
                  builder: (context) => AccountProfilePopup(
                    account: item.author,
                  ),
                );
              },
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildHeader(),
                  Text(item.title),
                  Text(
                    item.description,
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.8),
                    ),
                  ),
                ],
              ).paddingOnly(left: 12),
            )
          ],
        ).paddingOnly(
          top: 10,
          right: 16,
          left: 16,
        ),
        MarkdownTextContent(content: item.content).paddingOnly(
          left: 20,
          right: 20,
          top: 10,
          bottom: 8,
        ),
        buildFooter().paddingOnly(left: 20),
        if (widget.isReactable)
          ArticleQuickAction(
            isReactable: widget.isReactable,
            item: widget.item,
            onReact: (symbol, changes) {
              setState(() {
                item.reactionList[symbol] =
                    (item.reactionList[symbol] ?? 0) + changes;
              });
            },
          ).paddingOnly(
            top: 6,
            left: 16,
            right: 16,
            bottom: 10,
          )
        else
          const SizedBox(height: 10),
      ],
    );
  }
}
