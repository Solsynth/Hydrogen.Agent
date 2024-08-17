import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get_utils/get_utils.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/post.dart';
import 'package:solian/screens/posts/post_detail.dart';
import 'package:solian/shells/title_shell.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:solian/widgets/markdown_text_content.dart';
import 'package:solian/widgets/posts/post_tags.dart';
import 'package:solian/widgets/posts/post_quick_action.dart';
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

  Widget _buildDate() {
    if (widget.isFullDate) {
      return Text(DateFormat('y/M/d HH:mm')
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

  Widget _buildThumbnail() {
    if (widget.item.body['thumbnail'] == null) return const SizedBox();
    final border = BorderSide(
      color: Theme.of(context).dividerColor,
      width: 0.3,
    );
    return Container(
      decoration: BoxDecoration(border: Border(top: border, bottom: border)),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: AttachmentSelfContainedEntry(
          id: widget.item.body['thumbnail'],
          parentId: 'p${item.id}-thumbnail',
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isCompact)
          AccountAvatar(
            content: item.author.avatar.toString(),
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
                  _buildDate().paddingOnly(left: 4),
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
          ).paddingOnly(left: widget.isCompact ? 6 : 12),
        ),
        if (widget.item.type == 'article')
          Badge(
            label: Text('article'.tr),
          ).paddingOnly(top: 3),
      ],
    );
  }

  Widget _buildHeaderDivider() {
    if (item.body['description'] != null || item.body['title'] != null) {
      return const Divider(thickness: 0.3, height: 1).paddingSymmetric(
        vertical: 8,
      );
    }
    return const SizedBox();
  }

  Widget _buildFooter() {
    List<String> labels = List.empty(growable: true);
    if (widget.item.editedAt != null) {
      labels.add('postEdited'.trParams({
        'date': DateFormat('yy/M/d HH:mm').format(item.editedAt!.toLocal()),
      }));
    }
    if (widget.item.realm != null) {
      labels.add('postInRealm'.trParams({
        'realm': widget.item.realm!.alias,
      }));
    }

    List<Widget> widgets = List.empty(growable: true);

    if (widget.item.tags?.isNotEmpty ?? false) {
      widgets.add(PostTagsList(tags: widget.item.tags!));
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
    if (widget.item.pinnedAt != null) {
      widgets.add(Text(
        'postPinned'.tr,
        style: TextStyle(fontSize: 12, color: _unFocusColor),
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
    return OpenContainer(
      tappable: widget.isClickable || widget.isOverrideEmbedClickable,
      closedBuilder: (_, openContainer) => Column(
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
              attachmentParent: widget.item.id.toString(),
            ).paddingSymmetric(vertical: 8),
          ),
        ],
      ),
      openBuilder: (_, __) => TitleShell(
        title: 'postDetail'.tr,
        child: PostDetailScreen(
          id: widget.item.replyTo!.id.toString(),
          post: widget.item.replyTo!,
        ),
      ),
      closedElevation: 0,
      openElevation: 0,
      closedColor:
          widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      openColor: Theme.of(context).colorScheme.surface,
    );
  }

  Widget _buildRepost(BuildContext context) {
    return OpenContainer(
      tappable: widget.isClickable || widget.isOverrideEmbedClickable,
      closedBuilder: (_, openContainer) => Column(
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
              attachmentParent: widget.item.id.toString(),
            ).paddingSymmetric(vertical: 8),
          ),
        ],
      ),
      openBuilder: (_, __) => TitleShell(
        title: 'postDetail'.tr,
        child: PostDetailScreen(
          id: widget.item.repostTo!.id.toString(),
          post: widget.item.repostTo!,
        ),
      ),
      closedElevation: 0,
      openElevation: 0,
      closedColor:
          widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
      openColor: Theme.of(context).colorScheme.surface,
    );
  }

  double _contentHeight = 0;

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
          _buildThumbnail(),
          _buildHeader().paddingSymmetric(horizontal: 12),
          _buildHeaderDivider().paddingSymmetric(horizontal: 12),
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
          _buildFooter().paddingOnly(left: 16),
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
          _buildThumbnail().paddingOnly(bottom: 4),
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
                      name: item.author.name,
                    ),
                  );
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    _buildHeaderDivider(),
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
                            child: MarkdownTextContent(
                              parentId: 'p${item.id}-embed',
                              content: item.body['content'],
                              isSelectable: widget.isContentSelectable,
                            ).paddingOnly(left: 12, right: 8),
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
                                      Theme.of(context).colorScheme.surface,
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
                    if (widget.item.replyTo != null && widget.isShowEmbed)
                      _buildReply(context).paddingOnly(top: 4),
                    if (widget.item.repostTo != null && widget.isShowEmbed)
                      _buildRepost(context).paddingOnly(top: 4),
                    _buildFooter().paddingOnly(left: 12),
                  ],
                ),
              ),
            ],
          ).paddingOnly(
            top: 10,
            bottom: hasAttachment ? 10 : 0,
            right: 16,
            left: 16,
          ),
          AttachmentList(
            flatMaxHeight: MediaQuery.of(context).size.width,
            parentId: widget.item.id.toString(),
            attachmentsId: attachments,
            autoload: true,
            isGrid: attachments.length > 1,
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
            ).paddingOnly(
              top: hasAttachment ? 10 : 6,
              left: hasAttachment ? 24 : 60,
              right: 16,
              bottom: 10,
            )
          else
            const SizedBox(height: 10),
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
