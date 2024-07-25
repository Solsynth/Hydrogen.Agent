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
  final bool isContentSelectable;
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
    this.isContentSelectable = false,
    this.overrideAttachmentParent,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late final Post item;

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  @override
  void initState() {
    item = widget.item;
    super.initState();
  }

  Widget _buildDate() {
    if (widget.isFullDate) {
      return Text(DateFormat('y/M/d H:m')
          .format(item.publishedAt?.toLocal() ?? DateTime.now()));
    } else {
      return Text(
        format(
          item.publishedAt?.toLocal() ?? DateTime.now(),
          locale: 'en_short',
        ),
      );
    }
  }

  Widget _buildHeader() {
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
        _buildDate().paddingOnly(left: 4),
      ],
    );
  }

  Widget _buildFooter() {
    List<String> labels = List.empty(growable: true);
    if (widget.item.createdAt != widget.item.updatedAt) {
      labels.add('postEdited'.trParams({
        'date': DateFormat('yy/M/d H:m').format(item.updatedAt.toLocal()),
      }));
    }
    if (widget.item.realm != null) {
      labels.add('postInRealm'.trParams({
        'realm': widget.item.realm!.alias,
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
          color: _unFocusColor,
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

  Widget _buildReply(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.reply,
              size: 16,
              color: _unFocusColor,
            ),
            Expanded(
              child: Text(
                'postRepliedNotify'.trParams(
                  {'username': '@${widget.item.replyTo!.author.name}'},
                ),
                style: TextStyle(color: _unFocusColor),
              ).paddingOnly(left: 6),
            ),
          ],
        ).paddingOnly(left: 12),
        Card(
          elevation: 1,
          child: PostItem(
            item: widget.item.replyTo!,
            isCompact: true,
            overrideAttachmentParent: widget.item.id.toString(),
          ).paddingSymmetric(vertical: 8),
        ),
      ],
    );
  }

  Widget _buildRepost(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            FaIcon(
              FontAwesomeIcons.retweet,
              size: 16,
              color: _unFocusColor,
            ),
            Expanded(
              child: Text(
                'postRepostedNotify'.trParams(
                  {'username': '@${widget.item.repostTo!.author.name}'},
                ),
                style: TextStyle(color: _unFocusColor),
              ).paddingOnly(left: 6),
            ),
          ],
        ).paddingOnly(left: 12),
        Card(
          elevation: 1,
          child: PostItem(
            item: widget.item.repostTo!,
            isCompact: true,
            overrideAttachmentParent: widget.item.id.toString(),
          ).paddingSymmetric(vertical: 8),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<int> attachments = item.body['attachments'] is List
        ? item.body['attachments']?.cast<int>()
        : List.empty();
    final hasAttachment = attachments.isNotEmpty;

    if (widget.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader().paddingSymmetric(horizontal: 12),
          MarkdownTextContent(
            content: item.body['content'],
            isSelectable: widget.isContentSelectable,
          ).paddingOnly(
            left: 16,
            right: 12,
            top: 2,
            bottom: hasAttachment ? 4 : 0,
          ),
          _buildFooter().paddingOnly(left: 16),
          if (attachments.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.attachment,
                  size: 18,
                  color: _unFocusColor,
                ).paddingOnly(right: 6),
                Text(
                  'postAttachmentTip'.trParams(
                    {'count': attachments.length.toString()},
                  ),
                  style: TextStyle(color: _unFocusColor),
                )
              ],
            ).paddingOnly(left: 16, top: 4),
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
                  _buildHeader(),
                  MarkdownTextContent(
                    content: item.body['content'],
                    isSelectable: widget.isContentSelectable,
                  ).paddingOnly(left: 12, right: 8),
                  if (widget.item.replyTo != null && widget.isShowEmbed)
                    GestureDetector(
                      child: _buildReply(context).paddingOnly(top: 4),
                      onTap: () {
                        if (!widget.isClickable) return;
                        AppRouter.instance.pushNamed(
                          'postDetail',
                          pathParameters: {
                            'id': widget.item.replyTo!.id.toString(),
                          },
                        );
                      },
                    ),
                  if (widget.item.repostTo != null && widget.isShowEmbed)
                    GestureDetector(
                      child: _buildRepost(context).paddingOnly(top: 4),
                      onTap: () {
                        if (!widget.isClickable) return;
                        AppRouter.instance.pushNamed(
                          'postDetail',
                          pathParameters: {
                            'alias': widget.item.repostTo!.id.toString(),
                          },
                        );
                      },
                    ),
                  _buildFooter().paddingOnly(left: 12),
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
        Container(
          width: MediaQuery.of(context).size.width,
          constraints: const BoxConstraints(
            maxHeight: 720,
            maxWidth: 640,
          ),
          child: AttachmentList(
            parentId: widget.item.id.toString(),
            attachmentsId: attachments,
            isGrid: attachments.length > 1,
          ),
        ),
        if (widget.isShowReply && widget.isReactable)
          PostQuickAction(
            isShowReply: widget.isShowReply,
            isReactable: widget.isReactable,
            item: widget.item,
            onReact: (symbol, changes) {
              setState(() {
                item.metric!.reactionList[symbol] =
                    (item.metric!.reactionList[symbol] ?? 0) + changes;
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
