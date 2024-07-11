import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/post.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:solian/widgets/markdown_text_content.dart';
import 'package:solian/widgets/feed/feed_tags.dart';
import 'package:solian/widgets/posts/post_quick_action.dart';
import 'package:timeago/timeago.dart' show format;

class PostItem extends StatefulWidget {
  final Post item;
  final bool isClickable;
  final bool isCompact;
  final bool isReactable;
  final bool isShowReply;
  final bool isShowEmbed;
  final bool isFullDate;
  final String? overrideAttachmentParent;

  const PostItem({
    super.key,
    required this.item,
    this.isClickable = false,
    this.isCompact = false,
    this.isReactable = true,
    this.isShowReply = true,
    this.isShowEmbed = true,
    this.isFullDate = false,
    this.overrideAttachmentParent,
  });

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
        if (widget.isCompact)
          AccountAvatar(
            content: item.author.avatar.toString(),
            radius: 10,
          ).paddingOnly(left: 2),
        Text(
          item.author.nick,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ).paddingOnly(left: widget.isCompact ? 6 : 12),
        buildDate().paddingOnly(left: 4),
      ],
    );
  }

  Widget buildFooter() {
    List<String> labels = List.empty(growable: true);
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

  Widget buildReply(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.reply,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
            Expanded(
              child: Text(
                'postRepliedNotify'.trParams(
                  {'username': '@${widget.item.replyTo!.author.name}'},
                ),
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                ),
              ).paddingOnly(left: 6),
            ),
          ],
        ).paddingOnly(left: 12),
        Card(
          elevation: 1,
          child: PostItem(
            item: widget.item.replyTo!,
            isCompact: true,
            overrideAttachmentParent: widget.item.alias,
          ).paddingSymmetric(vertical: 8),
        ),
      ],
    );
  }

  Widget buildRepost(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.retweet,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
            Expanded(
              child: Text(
                'postRepostedNotify'.trParams(
                  {'username': '@${widget.item.repostTo!.author.name}'},
                ),
                style: TextStyle(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                ),
              ).paddingOnly(left: 6),
            ),
          ],
        ).paddingOnly(left: 12),
        Card(
          elevation: 1,
          child: PostItem(
            item: widget.item.repostTo!,
            isCompact: true,
            overrideAttachmentParent: widget.item.alias,
          ).paddingSymmetric(vertical: 8),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAttachment = item.attachments?.isNotEmpty ?? false;

    if (widget.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildHeader().paddingSymmetric(horizontal: 12),
          MarkdownTextContent(content: item.content).paddingOnly(
            left: 16,
            right: 12,
            top: 2,
            bottom: hasAttachment ? 4 : 0,
          ),
          buildFooter().paddingOnly(left: 16),
          AttachmentList(
            parentId: widget.overrideAttachmentParent ?? widget.item.alias,
            attachmentsId: item.attachments ?? List.empty(),
            divided: true,
          ),
        ],
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
                  MarkdownTextContent(content: item.content)
                      .paddingOnly(left: 12, right: 8),
                  if (widget.item.replyTo != null && widget.isShowEmbed)
                    GestureDetector(
                      child: buildReply(context).paddingOnly(top: 4),
                      onTap: () {
                        if (!widget.isClickable) return;
                        AppRouter.instance.pushNamed(
                          'postDetail',
                          pathParameters: {
                            'alias': widget.item.replyTo!.alias,
                          },
                        );
                      },
                    ),
                  if (widget.item.repostTo != null && widget.isShowEmbed)
                    GestureDetector(
                      child: buildRepost(context).paddingOnly(top: 4),
                      onTap: () {
                        if (!widget.isClickable) return;
                        AppRouter.instance.pushNamed(
                          'postDetail',
                          pathParameters: {
                            'alias': widget.item.repostTo!.alias,
                          },
                        );
                      },
                    ),
                  buildFooter().paddingOnly(left: 12),
                ],
              ),
            )
          ],
        ).paddingOnly(
          top: 10,
          bottom: hasAttachment ? 10 : 0,
          right: 16,
          left: 16,
        ),
        AttachmentList(
          parentId: widget.item.alias,
          attachmentsId: item.attachments ?? List.empty(),
          divided: true,
        ),
        if (widget.isShowReply && widget.isReactable)
          PostQuickAction(
            isShowReply: widget.isShowReply,
            isReactable: widget.isReactable,
            item: widget.item,
            onReact: (symbol, changes) {
              setState(() {
                item.reactionList[symbol] =
                    (item.reactionList[symbol] ?? 0) + changes;
              });
            },
          ).paddingOnly(
            top: hasAttachment ? 10 : 6,
            left: hasAttachment ? 24 : 60,
            right: 16,
            bottom: 10,
          )
        else
          const SizedBox(height: 10),
      ],
    );
  }
}
