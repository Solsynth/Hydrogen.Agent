import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:solian/models/post.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:solian/widgets/posts/post_quick_action.dart';
import 'package:timeago/timeago.dart' show format;
import 'package:url_launcher/url_launcher_string.dart';

class PostItem extends StatefulWidget {
  final Post item;
  final bool isClickable;
  final bool isCompact;
  final bool isReactable;
  final bool isShowReply;
  final bool isShowEmbed;
  final String? overrideAttachmentParent;

  const PostItem({
    super.key,
    required this.item,
    this.isClickable = false,
    this.isCompact = false,
    this.isReactable = true,
    this.isShowReply = true,
    this.isShowEmbed = true,
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
            Text(
              'postRepliedNotify'.trParams(
                {'username': '@${widget.item.replyTo!.author.name}'},
              ),
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
            ).paddingOnly(left: 6),
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
            Text(
              'postRepostedNotify'.trParams(
                {'username': '@${widget.item.repostTo!.author.name}'},
              ),
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
            ).paddingOnly(left: 6),
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
        children: [
          Row(
            children: [
              AccountAvatar(content: item.author.avatar.toString(), radius: 10),
              Text(
                item.author.nick,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ).paddingOnly(left: 6),
              Text(format(item.createdAt, locale: 'en_short'))
                  .paddingOnly(left: 4),
            ],
          ).paddingSymmetric(horizontal: 12),
          Markdown(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            data: item.content,
            padding: const EdgeInsets.all(0),
            onTapLink: (text, href, title) async {
              if (href == null) return;
              await launchUrlString(
                href,
                mode: LaunchMode.externalApplication,
              );
            },
          ).paddingOnly(
            left: 16,
            right: 12,
            top: 2,
            bottom: hasAttachment ? 4 : 0,
          ),
          AttachmentList(
            parentId: widget.overrideAttachmentParent ?? widget.item.alias,
            attachmentsId: item.attachments ?? List.empty(),
          ),
        ],
      );
    }

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
                      Text(format(item.createdAt, locale: 'en_short'))
                          .paddingOnly(left: 4),
                    ],
                  ),
                  Markdown(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    data: item.content,
                    padding: const EdgeInsets.all(0),
                  ).paddingOnly(left: 12, right: 8),
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
        ),
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
          left: hasAttachment ? 16 : 60,
          right: 16,
          bottom: 10,
        ),
      ],
    );
  }
}
