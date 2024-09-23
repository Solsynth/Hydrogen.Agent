import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/screens/posts/post_detail.dart';
import 'package:solian/shells/title_shell.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';
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
  final bool isFullContent;
  final bool isContentSelectable;
  final bool showFeaturedReply;
  final String? attachmentParent;
  final Color? backgroundColor;

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
    this.isFullContent = false,
    this.isContentSelectable = false,
    this.showFeaturedReply = false,
    this.attachmentParent,
    this.backgroundColor,
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

  double _contentHeight = 0;

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
            item: item,
          ).paddingSymmetric(horizontal: 12),
          _PostHeaderDividerWidget(item: item).paddingSymmetric(horizontal: 12),
          Stack(
            children: [
              SizedContainer(
                maxWidth: 640,
                maxHeight: widget.isFullContent ? double.infinity : 80,
                child: _MeasureSize(
                  onChange: (size) {
                    setState(() => _contentHeight = size.height);
                  },
                  child: MarkdownTextContent(
                    parentId: 'p${item.id}',
                    content: item.body['content'],
                    isAutoWarp: item.type == 'story',
                    isSelectable: widget.isContentSelectable,
                  ).paddingOnly(
                    left: 16,
                    right: 12,
                    top: 2,
                    bottom: hasAttachment ? 4 : 0,
                  ),
                ),
              ),
              if (_contentHeight >= 80 && !widget.isFullContent)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: IgnorePointer(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Theme.of(context).colorScheme.surfaceContainerLow,
                            Theme.of(context)
                                .colorScheme
                                .surface
                                .withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          LinkExpansion(content: item.body['content']).paddingOnly(
            left: 8,
            right: 8,
            top: 4,
          ),
          _PostFooterWidget(item: item).paddingOnly(left: 16),
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
            ).paddingOnly(left: 16, top: 4),
        ],
      );
    }

    return OpenContainer(
      tappable: widget.isClickable,
      closedBuilder: (_, openContainer) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PostThumbnail(
            rid: item.body['thumbnail'],
            parentId: widget.item.id.toString(),
          ).paddingOnly(bottom: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                child: AccountAvatar(content: item.author.avatar),
                onTap: () {
                  showModalBottomSheet(
                    useRootNavigator: true,
                    isScrollControlled: true,
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    context: context,
                    builder: (context) => AccountProfilePopup(
                      name: item.author.name,
                    ),
                  );
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PostHeaderWidget(
                      isCompact: widget.isCompact,
                      item: item,
                    ),
                    _PostHeaderDividerWidget(item: item),
                    Stack(
                      children: [
                        SizedContainer(
                          maxWidth: 640,
                          maxHeight:
                              widget.isFullContent ? double.infinity : 320,
                          child: _MeasureSize(
                            onChange: (size) {
                              setState(() => _contentHeight = size.height);
                            },
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: MarkdownTextContent(
                                parentId: 'p${item.id}-embed',
                                content: item.body['content'],
                                isAutoWarp: item.type == 'story',
                                isSelectable: widget.isContentSelectable,
                                isLargeText: item.type == 'article' &&
                                    widget.isFullContent,
                              ).paddingOnly(left: 12, right: 8),
                            ),
                          ),
                        ),
                        if (_contentHeight >= 320 && !widget.isFullContent)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: IgnorePointer(
                              child: Container(
                                height: 320,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      (widget.backgroundColor ??
                                          Theme.of(context)
                                              .colorScheme
                                              .surface),
                                      (widget.backgroundColor ??
                                              Theme.of(context)
                                                  .colorScheme
                                                  .surface)
                                          .withOpacity(0),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (widget.item.replyTo != null && widget.isShowEmbed)
                      Container(
                        constraints: const BoxConstraints(maxWidth: 480),
                        padding: const EdgeInsets.only(top: 4),
                        child: _PostEmbedWidget(
                          isClickable: widget.isClickable,
                          isOverrideEmbedClickable:
                              widget.isOverrideEmbedClickable,
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
                        padding: const EdgeInsets.only(top: 4),
                        child: _PostEmbedWidget(
                          isClickable: widget.isClickable,
                          isOverrideEmbedClickable:
                              widget.isOverrideEmbedClickable,
                          item: widget.item.repostTo!,
                          username: widget.item.repostTo!.author.name,
                          hintText: 'postRepostedNotify',
                          icon: FontAwesomeIcons.retweet,
                          id: widget.item.repostTo!.id.toString(),
                        ),
                      ),
                    _PostFooterWidget(item: item).paddingOnly(left: 12),
                    LinkExpansion(content: item.body['content'])
                        .paddingOnly(top: 4),
                  ],
                ),
              ),
            ],
          ).paddingOnly(
            top: 10,
            bottom:
                (attachments.length == 1 && !AppTheme.isLargeScreen(context))
                    ? 10
                    : 0,
            right: 16,
            left: 16,
          ),
          _PostAttachmentWidget(item: item),
          if (widget.showFeaturedReply) _PostFeaturedReplyWidget(item: item),
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
            ).paddingOnly(
              top: (attachments.length == 1 && !AppTheme.isLargeScreen(context))
                  ? 10
                  : 6,
              left:
                  (attachments.length == 1 && !AppTheme.isLargeScreen(context))
                      ? 24
                      : 60,
              right: 16,
              bottom: 10,
            )
          else
            const Gap(10),
        ],
      ),
      openBuilder: (_, __) => TitleShell(
        title: 'postDetail'.tr,
        child: PostDetailScreen(
          id: item.id.toString(),
          post: item,
        ),
      ),
      closedElevation: 0,
      openElevation: 0,
      closedColor:
          widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      openColor: Theme.of(context).colorScheme.surface,
    );
  }
}

class _PostFeaturedReplyWidget extends StatelessWidget {
  final Post item;

  const _PostFeaturedReplyWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppTheme.isLargeScreen(context);
    final unFocusColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

    if ((item.metric?.replyCount ?? 0) == 0) {
      return const SizedBox.shrink();
    }

    final List<String> attachments = item.body['attachments'] is List
        ? List.from(item.body['attachments']?.whereType<String>())
        : List.empty();

    return FutureBuilder(
      future:
          Get.find<PostProvider>().listPostFeaturedReply(item.id.toString()),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: snapshot.data!
                  .map(
                    (reply) => Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AccountAvatar(content: reply.author.avatar, radius: 10),
                        const Gap(6),
                        Text(
                          reply.author.nick,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  )
                  .toList(),
            ),
          ),
        )
            .animate()
            .fadeIn(
              duration: 300.ms,
              curve: Curves.easeIn,
            )
            .paddingOnly(
              top: (attachments.length == 1 && !isLargeScreen) ? 10 : 6,
              left: (attachments.length == 1 && !isLargeScreen) ? 24 : 60,
              right: 16,
            );
      },
    );
  }
}

class _PostAttachmentWidget extends StatelessWidget {
  final Post item;

  const _PostAttachmentWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final isLargeScreen = AppTheme.isLargeScreen(context);

    final List<String> attachments = item.body['attachments'] is List
        ? List.from(item.body['attachments']?.whereType<String>())
        : List.empty();

    if (attachments.length > 3) {
      return AttachmentList(
        parentId: item.id.toString(),
        attachmentsId: attachments,
        autoload: false,
        isGrid: true,
      ).paddingOnly(left: 36, top: 4, bottom: 4);
    } else if (attachments.length > 1 || isLargeScreen) {
      return AttachmentList(
        parentId: item.id.toString(),
        attachmentsId: attachments,
        autoload: false,
        isColumn: true,
      ).paddingOnly(left: 60, right: 24, top: 4, bottom: 4);
    } else {
      return AttachmentList(
        flatMaxHeight: MediaQuery.of(context).size.width,
        parentId: item.id.toString(),
        attachmentsId: attachments,
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
              Expanded(
                child: Text(
                  hintText.trParams(
                    {'username': '@$username'},
                  ),
                  style: TextStyle(color: unFocusColor),
                ).paddingOnly(left: 6),
              ),
            ],
          ).paddingOnly(left: 12),
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
      closedColor: Theme.of(context).colorScheme.surface,
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
      return const Divider(thickness: 0.3, height: 1).paddingSymmetric(
        vertical: 8,
      );
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
      ).paddingOnly(top: 4);
    }
  }
}

class _PostHeaderWidget extends StatelessWidget {
  final bool isCompact;
  final Post item;

  const _PostHeaderWidget({
    required this.isCompact,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isCompact)
          AccountAvatar(
            content: item.author.avatar,
            radius: 10,
          ).paddingOnly(left: 2, top: 1),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    item.author.nick,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  RelativeDate(item.publishedAt?.toLocal() ?? DateTime.now())
                      .paddingOnly(left: 4),
                ],
              ),
              if (item.body['title'] != null)
                Text(
                  item.body['title'],
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium!
                      .copyWith(fontSize: 15),
                ),
              if (item.body['description'] != null)
                Text(
                  item.body['description'],
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ).paddingOnly(left: isCompact ? 6 : 12),
        ),
        if (item.type == 'article')
          Badge(
            label: Text('article'.tr),
          ).paddingOnly(top: 3),
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

typedef _OnWidgetSizeChange = void Function(Size size);

class _MeasureSizeRenderObject extends RenderProxyBox {
  Size? oldSize;
  _OnWidgetSizeChange onChange;

  _MeasureSizeRenderObject(this.onChange);

  @override
  void performLayout() {
    super.performLayout();

    Size newSize = child!.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChange(newSize);
    });
  }
}

class _MeasureSize extends SingleChildRenderObjectWidget {
  final _OnWidgetSizeChange onChange;

  const _MeasureSize({
    required this.onChange,
    required Widget super.child,
  });

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MeasureSizeRenderObject(onChange);
  }

  @override
  void updateRenderObject(
      BuildContext context, covariant _MeasureSizeRenderObject renderObject) {
    renderObject.onChange = onChange;
  }
}
