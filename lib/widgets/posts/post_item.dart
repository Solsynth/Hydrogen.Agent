import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/posts/post_detail.dart';
import 'package:solian/shells/title_shell.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:solian/widgets/link_expansion.dart';
import 'package:solian/widgets/markdown_text_content.dart';
import 'package:solian/widgets/posts/post_tags.dart';
import 'package:solian/widgets/posts/post_quick_action.dart';
import 'package:solian/widgets/relative_date.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:timeago/timeago.dart' show format;

class PostItem extends StatefulWidget {
  final Post item;
  final bool isClickable;
  final bool isCompact;
  final bool isReactable;
  final bool isShowReply;
  final bool isShowEmbed;
  final bool isOverrideEmbedClickable;
  final bool isFullDate;
  final bool isContentSelectable;
  final bool showFeaturedReply;
  final String? attachmentParent;

  final EdgeInsets? padding;

  final Function? onComment;

  const PostItem({
    super.key,
    required this.item,
    this.isClickable = false,
    this.isCompact = false,
    this.isReactable = true,
    this.isShowReply = true,
    this.isShowEmbed = true,
    this.isOverrideEmbedClickable = false,
    this.isFullDate = false,
    this.isContentSelectable = false,
    this.showFeaturedReply = false,
    this.attachmentParent,
    this.padding,
    this.onComment,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late final Post item;

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  static final visibilityIcons = [
    Icons.public,
    Icons.group,
    Icons.visibility,
    Icons.visibility_off,
    Icons.lock,
  ];

  @override
  void initState() {
    item = widget.item;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> attachments = item.body['attachments'] is List
        ? List.from(item.body['attachments']?.whereType<String>())
        : List.empty();
    final hasAttachment = attachments.isNotEmpty;

    if (widget.isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostThumbnail(
            rid: item.body['thumbnail'],
            parentId: widget.item.id.toString(),
          ).paddingOnly(bottom: 8),
          _PostHeaderWidget(
            isCompact: widget.isCompact,
            isFullDate: widget.isFullDate,
            item: item,
          ).paddingSymmetric(horizontal: 12),
          _PostHeaderDividerWidget(item: item).paddingSymmetric(horizontal: 12),
          SizedContainer(
            maxWidth: 640,
            child: MarkdownTextContent(
              parentId: 'p${item.id}',
              content: item.body['content'],
              isAutoWarp: item.type == 'story',
              isSelectable: widget.isContentSelectable,
            ),
          ).paddingOnly(
            left: 12,
            right: 12,
            bottom: hasAttachment ? 4 : 0,
          ),
          if (widget.item.body?['content_truncated'] == true)
            Opacity(
              opacity: 0.8,
              child: InkWell(child: Text('readMore'.tr)),
            ).paddingOnly(
              left: 12,
              top: 4,
            ),
          LinkExpansion(content: item.body['content']).paddingOnly(
            left: 8,
            right: 8,
          ),
          if (attachments.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.file_copy,
                  size: 15,
                  color: _unFocusColor,
                ).paddingOnly(right: 5),
                Text(
                  'attachmentHint'.trParams(
                    {'count': attachments.length.toString()},
                  ),
                  style: TextStyle(color: _unFocusColor),
                )
              ],
            ).paddingOnly(left: 14, top: 4),
        ],
      );
    }

    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostThumbnail(
            rid: item.body['thumbnail'],
            parentId: widget.item.id.toString(),
          ).paddingOnly(bottom: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PostHeaderWidget(
                isCompact: widget.isCompact,
                isFullDate: widget.isFullDate,
                item: item,
              ),
              _PostHeaderDividerWidget(item: item),
              SizedContainer(
                maxWidth: 640,
                child: MarkdownTextContent(
                  parentId: 'p${item.id}-embed',
                  content: item.body['content'],
                  isAutoWarp: item.type == 'story',
                  isSelectable: widget.isContentSelectable,
                ),
              ),
              if (widget.item.body?['content_truncated'] == true)
                Opacity(
                  opacity: 0.8,
                  child: InkWell(child: Text('readMore'.tr)),
                ).paddingOnly(top: 4),
              if (widget.item.replyTo != null && widget.isShowEmbed)
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.only(top: 8),
                  child: _PostEmbedWidget(
                    isClickable: widget.isClickable,
                    isOverrideEmbedClickable: widget.isOverrideEmbedClickable,
                    item: widget.item.replyTo!,
                    username: widget.item.replyTo!.author.name,
                    hintText: 'postRepliedNotify',
                    icon: FontAwesomeIcons.reply,
                    id: widget.item.replyTo!.id.toString(),
                  ),
                ),
              if (widget.item.repostTo != null && widget.isShowEmbed)
                Container(
                  constraints: const BoxConstraints(maxWidth: 480),
                  padding: const EdgeInsets.only(top: 8),
                  child: _PostEmbedWidget(
                    isClickable: widget.isClickable,
                    isOverrideEmbedClickable: widget.isOverrideEmbedClickable,
                    item: widget.item.repostTo!,
                    username: widget.item.repostTo!.author.name,
                    hintText: 'postRepostedNotify',
                    icon: FontAwesomeIcons.retweet,
                    id: widget.item.repostTo!.id.toString(),
                  ),
                ),
              _PostFooterWidget(item: item),
              LinkExpansion(content: item.body['content']),
            ],
          ).paddingSymmetric(
            horizontal: (widget.padding?.horizontal ?? 0) + 16,
          ),
          if (hasAttachment) const Gap(8),
          _PostAttachmentWidget(
            item: item,
            padding: widget.padding,
          ),
          if (widget.showFeaturedReply)
            _PostFeaturedReplyWidget(item: item).paddingSymmetric(
              horizontal: (widget.padding?.horizontal ?? 0) + 12,
            ),
          if (widget.isShowReply || widget.isReactable)
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
              onComment: () {
                if (widget.onComment != null) {
                  widget.onComment!();
                }
              },
            ).paddingOnly(
              top: 8,
              left: (widget.padding?.left ?? 0) + 14,
              right: (widget.padding?.right ?? 0) + 14,
            )
        ],
      ).paddingOnly(
        top: widget.padding?.top ?? 0,
        bottom: widget.padding?.bottom ?? 0,
      ),
      onTap: () {
        if (widget.isClickable) {
          AppRouter.instance.pushNamed(
            'postDetail',
            pathParameters: {'id': item.id.toString()},
            extra: item,
          );
        }
      },
    );
  }
}

class _PostFeaturedReplyWidget extends StatelessWidget {
  final Post item;

  const _PostFeaturedReplyWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final unFocusColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

    if ((item.metric?.replyCount ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    return FutureBuilder(
      future: Get.find<PostProvider>().listPostFeaturedReply(
        item.id.toString(),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.only(top: 8),
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: snapshot.data!
                  .map(
                    (reply) => ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(8)),
                      child: OpenContainer(
                        closedBuilder: (_, openContainer) => Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AttachedCircleAvatar(
                              content: reply.author.avatar,
                              radius: 10,
                            ),
                            const Gap(6),
                            Text(
                              reply.author.nick,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Gap(6),
                            Text(
                              format(
                                reply.publishedAt?.toLocal() ?? DateTime.now(),
                                locale: 'en_short',
                              ),
                            ).paddingOnly(top: 0.5),
                            const Gap(8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  MarkdownTextContent(
                                    isAutoWarp: reply.type == 'story',
                                    content: reply.body['content'],
                                    parentId:
                                        'p${item.id}-featured-reply${reply.id}',
                                  ),
                                  if (reply.body['attachments'] is List &&
                                      reply.body['attachments'].isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.file_copy,
                                          size: 15,
                                          color: unFocusColor,
                                        ).paddingOnly(right: 5),
                                        Text(
                                          'attachmentHint'.trParams(
                                            {
                                              'count': reply
                                                  .body['attachments'].length
                                                  .toString(),
                                            },
                                          ),
                                          style: TextStyle(color: unFocusColor),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ).paddingSymmetric(horizontal: 12, vertical: 8),
                        openBuilder: (_, __) => TitleShell(
                          title: 'postDetail'.tr,
                          child: PostDetailScreen(
                            id: reply.id.toString(),
                            post: reply,
                          ),
                        ),
                        closedElevation: 0,
                        openElevation: 0,
                        closedColor:
                            Theme.of(context).colorScheme.surfaceContainer,
                        openColor: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ).animate().fadeIn(
              duration: 300.ms,
              curve: Curves.easeIn,
            );
      },
    );
  }
}

class _PostAttachmentWidget extends StatelessWidget {
  final Post item;
  final EdgeInsets? padding;

  const _PostAttachmentWidget({required this.item, required this.padding});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppTheme.isLargeScreen(context);

    final List<String> attachments = item.body['attachments'] is List
        ? List.from(item.body['attachments']?.whereType<String>())
        : List.empty();

    if (attachments.isEmpty) return const SizedBox.shrink();

    if (attachments.length == 1 && !isLargeScreen) {
      return AttachmentList(
        parentId: item.id.toString(),
        attachmentIds: item.preload == null ? attachments : null,
        attachments: item.preload?.attachments,
        autoload: false,
        isFullWidth: true,
      );
    } else if (attachments.length == 1) {
      return AttachmentList(
        parentId: item.id.toString(),
        attachmentIds: item.preload == null ? attachments : null,
        attachments: item.preload?.attachments,
        autoload: false,
        isColumn: true,
      ).paddingSymmetric(horizontal: (padding?.horizontal ?? 0) + 14);
    } else if (attachments.length > 1 &&
        attachments.length % 3 == 0 &&
        !isLargeScreen) {
      return AttachmentList(
        parentId: item.id.toString(),
        attachmentIds: item.preload == null ? attachments : null,
        attachments: item.preload?.attachments,
        autoload: false,
        isGrid: true,
      ).paddingSymmetric(horizontal: (padding?.horizontal ?? 0) + 14);
    } else {
      return AttachmentList(
        parentId: item.id.toString(),
        attachmentIds: item.preload == null ? attachments : null,
        attachments: item.preload?.attachments,
        padding: EdgeInsets.symmetric(
          horizontal: (padding?.horizontal ?? 0) + 14,
        ),
        autoload: false,
      );
    }
  }
}

class _PostEmbedWidget extends StatelessWidget {
  final bool isClickable;
  final bool isOverrideEmbedClickable;
  final Post item;
  final String username;
  final String hintText;
  final IconData icon;
  final String id;

  const _PostEmbedWidget({
    required this.isClickable,
    required this.isOverrideEmbedClickable,
    required this.item,
    required this.username,
    required this.hintText,
    required this.icon,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    final unFocusColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

    return OpenContainer(
      tappable: isClickable || isOverrideEmbedClickable,
      closedBuilder: (_, openContainer) => Column(
        children: [
          Row(
            children: [
              FaIcon(
                icon,
                size: 16,
                color: unFocusColor,
              ),
              const Gap(6),
              Expanded(
                child: Text(
                  hintText.trParams(
                    {'username': '@$username'},
                  ),
                  style: TextStyle(color: unFocusColor),
                ),
              ),
            ],
          ).paddingOnly(left: 2),
          Card(
            elevation: 1,
            child: PostItem(
              item: item,
              isCompact: true,
              attachmentParent: id,
            ).paddingSymmetric(vertical: 8),
          ),
        ],
      ),
      openBuilder: (_, __) => TitleShell(
        title: 'postDetail'.tr,
        child: PostDetailScreen(
          id: id,
          post: item,
        ),
      ),
      closedElevation: 0,
      openElevation: 0,
      closedColor: Colors.transparent,
      openColor: Theme.of(context).colorScheme.surface,
    );
  }
}

class _PostHeaderDividerWidget extends StatelessWidget {
  final Post item;

  const _PostHeaderDividerWidget({
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    if (item.body['description'] != null || item.body['title'] != null) {
      return const Gap(8);
    }
    return const SizedBox.shrink();
  }
}

class _PostFooterWidget extends StatelessWidget {
  final Post item;

  const _PostFooterWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final unFocusColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

    List<String> labels = List.empty(growable: true);
    if (item.editedAt != null) {
      labels.add('postEdited'.trParams({
        'date': DateFormat('yy/M/d HH:mm').format(item.editedAt!.toLocal()),
      }));
    }
    if (item.realm != null) {
      labels.add('postInRealm'.trParams({
        'realm': item.realm!.alias,
      }));
    }

    List<Widget> widgets = List.empty(growable: true);

    if (item.tags?.isNotEmpty ?? false) {
      widgets.add(PostTagsList(tags: item.tags!));
    }
    if (labels.isNotEmpty) {
      widgets.add(Text(
        labels.join(' · '),
        textAlign: TextAlign.left,
        style: TextStyle(
          fontSize: 12,
          color: unFocusColor,
        ),
      ));
    }
    if (item.pinnedAt != null) {
      widgets.add(Text(
        'postPinned'.tr,
        style: TextStyle(fontSize: 12, color: unFocusColor),
      ));
    }

    if (widgets.isEmpty) {
      return const SizedBox.shrink();
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets,
      ).paddingSymmetric(vertical: 4);
    }
  }
}

class _PostHeaderWidget extends StatelessWidget {
  final bool isCompact;
  final bool isFullDate;
  final Post item;

  const _PostHeaderWidget({
    required this.isCompact,
    required this.isFullDate,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AccountAvatar(
              content: item.author.avatar,
              username: item.author.name,
              radius: isCompact ? 10 : null,
            ),
            Gap(isCompact ? 6 : 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        item.author.nick,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (isCompact) const Gap(4),
                      if (isCompact)
                        RelativeDate(
                          item.publishedAt?.toLocal() ?? DateTime.now(),
                          isFull: isFullDate,
                        ).paddingOnly(top: 1),
                    ],
                  ),
                  if (!isCompact)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        RelativeDate(
                          item.publishedAt?.toLocal() ?? DateTime.now(),
                          isFull: isFullDate,
                        ),
                        const Gap(4),
                        Icon(
                          _PostItemState.visibilityIcons[item.visibility],
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.75),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (item.type == 'article')
              Badge(
                label: Text('article'.tr),
              ).paddingOnly(top: 3),
          ],
        ),
        const Gap(8),
        if (item.body['title'] != null)
          Text(
            item.body['title'],
            style: Theme.of(context).textTheme.titleMedium,
          ),
        if (item.body['description'] != null)
          Text(
            item.body['description'],
            style: Theme.of(context).textTheme.titleSmall,
          ),
      ],
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  final String parentId;
  final String? rid;

  const _PostThumbnail({required this.parentId, required this.rid});

  @override
  Widget build(BuildContext context) {
    if (rid?.isEmpty ?? true) return const SizedBox.shrink();
    final border = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 0.3,
    );
    return Container(
      decoration: BoxDecoration(border: Border(top: border, bottom: border)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: AttachmentSelfContainedEntry(
          rid: rid!,
          parentId: 'p$parentId-thumbnail',
        ),
      ),
    );
  }
}
