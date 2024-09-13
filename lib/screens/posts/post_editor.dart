import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:markdown_toolbar/markdown_toolbar.dart';
import 'package:solian/controllers/post_editor_controller.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/attachment_uploader.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/navigation.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/markdown_text_content.dart';
import 'package:solian/widgets/posts/post_item.dart';
import 'package:badges/badges.dart' as badges;

class PostPublishArguments {
  final Post? edit;
  final Post? reply;
  final Post? repost;
  final Realm? realm;

  PostPublishArguments({
    this.edit,
    this.reply,
    this.repost,
    this.realm,
  });
}

class PostPublishScreen extends StatefulWidget {
  final Post? edit;
  final Post? reply;
  final Post? repost;
  final Realm? realm;
  final int mode;

  const PostPublishScreen({
    super.key,
    this.edit,
    this.reply,
    this.repost,
    this.realm,
    required this.mode,
  });

  @override
  State<PostPublishScreen> createState() => _PostPublishScreenState();
}

class _PostPublishScreenState extends State<PostPublishScreen> {
  final _editorController = PostEditorController();
  final _contentFocusNode = FocusNode();

  bool _isBusy = false;

  void _applyPost() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;
    if (_editorController.isEmpty) return;

    final AttachmentUploaderController uploader = Get.find();
    if (uploader.queueOfUpload.any(
      ((x) => x.isUploading),
    )) {
      context.showErrorDialog('attachmentUploadInProgress'.tr);
      return;
    }

    setState(() => _isBusy = true);

    final client = auth.configureClient('interactive');

    Response resp;
    if (widget.edit != null) {
      resp = await client.put(
        '/${_editorController.typeEndpoint}/${widget.edit!.id}',
        _editorController.payload,
      );
    } else {
      resp = await client.post(
        '/${_editorController.typeEndpoint}',
        _editorController.payload,
      );
    }
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      _editorController.currentClear();
      _editorController.localClear();
      AppRouter.instance.pop(resp.body);
    }

    setState(() => _isBusy = false);
  }

  void _syncWidget() {
    _editorController.mode.value = widget.mode;
    if (widget.edit != null) {
      _editorController.editTarget = widget.edit;
    }
    if (widget.realm != null) {
      _editorController.realmZone.value = widget.realm;
    }
  }

  void _cancelAction() {
    _editorController.localClear();
    AppRouter.instance.pop();
  }

  Post? get _editTo => _editorController.editTo.value;

  Post? get _replyTo => _editorController.replyTo.value;

  Post? get _repostTo => _editorController.repostTo.value;

  @override
  void initState() {
    super.initState();
    if (widget.edit == null && widget.reply == null && widget.repost == null) {
      _editorController.localRead().then((res) {
        if (!res) {
          final navState = Get.find<NavigationStateProvider>();
          _editorController.realmZone.value = navState.focusedRealm.value;
        }
      });
    }
    if (widget.reply != null) {
      _editorController.replyTo.value = widget.reply;
    }
    if (widget.repost != null) {
      _editorController.repostTo.value = widget.repost;
    }
    _editorController.contentController.addListener(() => setState(() {}));
    _syncWidget();
  }

  @override
  Widget build(BuildContext context) {
    final notifyBannerActions = [
      TextButton(
        onPressed: _cancelAction,
        child: Text('cancel'.tr),
      )
    ];

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarLeadingButton.adaptive(context),
          title: Obx(
            () => AppBarTitle(
              _editorController.mode.value == 0
                  ? 'postEditorModeStory'.tr
                  : 'postEditorModeArticle'.tr,
            ),
          ),
          centerTitle: false,
          toolbarHeight: AppTheme.toolbarHeight(context),
          actions: [
            TextButton(
              onPressed: _isBusy ? null : () => _applyPost(),
              child: Obx(
                () => Text(
                  _editorController.isDraft.isTrue
                      ? 'draftSave'.tr.toUpperCase()
                      : 'postAction'.tr.toUpperCase(),
                ),
              ),
            )
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
              title: Row(
                children: [
                  Text(
                    _editorController.title ?? 'title'.tr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(6),
                  if (_editorController.aliasController.text.isNotEmpty)
                    Badge(
                      label: Text('#${_editorController.aliasController.text}'),
                    ),
                ],
              ),
              subtitle: Text(
                _editorController.description ?? 'description'.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              contentPadding: const EdgeInsets.only(
                left: 17,
                right: 8,
                top: 0,
                bottom: 0,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _editorController.editOverview(context).then((_) {
                    setState(() {});
                  });
                },
              ),
            ),
            if (_editTo != null && _editTo!.isDraft != true)
              MaterialBanner(
                leading: const Icon(Icons.edit),
                leadingPadding: const EdgeInsets.only(left: 10, right: 20),
                dividerColor: Colors.transparent,
                content: Text('postEditingNotify'.tr),
                actions: notifyBannerActions,
              ),
            if (_replyTo != null)
              ExpansionTile(
                leading: const FaIcon(
                  FontAwesomeIcons.reply,
                  size: 18,
                ).paddingOnly(left: 2),
                title: Text('postReplyingNotify'.trParams(
                  {'username': '@${widget.reply!.author.name}'},
                )),
                collapsedBackgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: PostItem(
                        item: _replyTo!,
                        isReactable: false,
                      ).paddingOnly(bottom: 8),
                    ),
                  ),
                ],
              ),
            if (_repostTo != null)
              ExpansionTile(
                leading: const FaIcon(
                  FontAwesomeIcons.retweet,
                  size: 18,
                ).paddingOnly(left: 2),
                title: Text('postRepostingNotify'.trParams(
                  {'username': '@${widget.repost!.author.name}'},
                )),
                collapsedBackgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                children: [
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: SingleChildScrollView(
                      child: PostItem(
                        item: _repostTo!,
                        isReactable: false,
                      ).paddingOnly(bottom: 8),
                    ),
                  ),
                ],
              ),
            if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: TextField(
                                  maxLines: null,
                                  autofocus: true,
                                  autocorrect: true,
                                  keyboardType: TextInputType.multiline,
                                  controller:
                                      _editorController.contentController,
                                  focusNode: _contentFocusNode,
                                  decoration: InputDecoration.collapsed(
                                    hintText: 'postContentPlaceholder'.tr,
                                  ),
                                  onTapOutside: (_) => FocusManager
                                      .instance.primaryFocus
                                      ?.unfocus(),
                                ),
                              ),
                              const Gap(120)
                            ],
                          ),
                        ),
                        Obx(() {
                          final textStyle = TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.75),
                          );
                          final showFactors = [
                            _editorController.isRestoreFromLocal.value,
                            _editorController.lastSaveTime.value != null,
                          ];
                          final doShow = showFactors.any((x) => x);
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 4,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                if (showFactors[0])
                                  Text('postRestoreFromLocal'.tr,
                                          style: textStyle)
                                      .paddingOnly(right: 4),
                                if (showFactors[0])
                                  InkWell(
                                    child: Text('clear'.tr, style: textStyle),
                                    onTap: () {
                                      _editorController.localClear();
                                      _editorController.currentClear();
                                      setState(() {});
                                    },
                                  ),
                                if (showFactors.where((x) => x).length > 1)
                                  Text(
                                    '·',
                                    style: textStyle,
                                  ).paddingSymmetric(horizontal: 8),
                                if (showFactors[1])
                                  Text(
                                    'postAutoSaveAt'.trParams({
                                      'date': DateFormat('HH:mm:ss').format(
                                        _editorController.lastSaveTime.value ??
                                            DateTime.now(),
                                      )
                                    }),
                                    style: textStyle,
                                  ),
                              ],
                            ),
                          )
                              .animate(
                                key: const Key('post-editor-hint-animation'),
                                target: doShow ? 1 : 0,
                              )
                              .fade(curve: Curves.easeInOut, duration: 300.ms);
                        }),
                      ],
                    ),
                  ),
                  if (AppTheme.isLargeScreen(context))
                    const VerticalDivider(width: 0.3, thickness: 0.3)
                        .paddingSymmetric(
                      horizontal: 16,
                    ),
                  if (AppTheme.isLargeScreen(context))
                    Expanded(
                      child: SingleChildScrollView(
                        child: MarkdownTextContent(
                          content: _editorController.contentController.text,
                          parentId: 'post-editor-preview',
                        ).paddingOnly(top: 12, right: 16),
                      ),
                    ),
                ],
              ),
            ),
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(thickness: 0.3, height: 0.3),
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        if (_editorController.mode.value == 0)
                          Obx(
                            () => TweenAnimationBuilder<double>(
                              tween: Tween(
                                begin: 0,
                                end: _editorController.contentLength.value /
                                    4096,
                              ),
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              builder: (context, value, _) => SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  backgroundColor: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer,
                                  color: _editorController.contentLength.value >
                                          4096
                                      ? Colors.red[900]
                                      : Theme.of(context).colorScheme.primary,
                                  value: value,
                                ),
                              ).paddingAll(10),
                            ),
                          ).paddingSymmetric(horizontal: 4),
                        Obx(() {
                          final isDraft = _editorController.isDraft.value;
                          return IconButton(
                            icon: const Icon(
                              Icons.drive_file_rename_outline,
                              color: Colors.grey,
                            )
                                .animate(
                                  target: isDraft ? 0 : 1,
                                )
                                .fadeOut(duration: 150.ms)
                                .swap(
                                  duration: 150.ms,
                                  builder: (_, __) => const Icon(
                                    Icons.public,
                                    color: Colors.green,
                                  ).animate().fadeIn(duration: 150.ms),
                                ),
                            onPressed: () {
                              _editorController.toggleDraftMode();
                            },
                          );
                        }),
                        IconButton(
                          icon: const Icon(Icons.disabled_visible),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            _editorController.editVisibility(context);
                          },
                        ),
                        IconButton(
                          icon: Obx(() {
                            return badges.Badge(
                              badgeContent: Text(
                                _editorController.attachments.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              showBadge:
                                  _editorController.attachments.isNotEmpty,
                              position: badges.BadgePosition.topEnd(
                                top: -12,
                                end: -8,
                              ),
                              child: const Icon(Icons.file_present_rounded),
                            );
                          }),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            _editorController.editAttachment(context);
                          },
                        ),
                        IconButton(
                          icon: Obx(() {
                            return badges.Badge(
                              badgeContent: Text(
                                _editorController.tags.length.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                              showBadge: _editorController.tags.isNotEmpty,
                              position: badges.BadgePosition.topEnd(
                                top: -12,
                                end: -8,
                              ),
                              child: const Icon(Icons.label),
                            );
                          }),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            _editorController.editCategoriesAndTags(context);
                          },
                        ),
                        IconButton(
                          icon: Obx(() {
                            return badges.Badge(
                              showBadge:
                                  _editorController.realmZone.value != null,
                              position: badges.BadgePosition.topEnd(
                                top: -4,
                                end: -6,
                              ),
                              child: const Icon(Icons.workspaces),
                            );
                          }),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            _editorController.editPublishZone(context);
                          },
                        ),
                        IconButton(
                          icon: Obx(() {
                            return badges.Badge(
                              showBadge:
                                  _editorController.thumbnail.value != null,
                              position: badges.BadgePosition.topEnd(
                                top: -4,
                                end: -6,
                              ),
                              child: const Icon(Icons.preview),
                            );
                          }),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            _editorController.editThumbnail(context);
                          },
                        ),
                        IconButton(
                          icon: Obx(() {
                            return badges.Badge(
                              showBadge:
                                  _editorController.publishedAt.value != null ||
                                      _editorController.publishedUntil.value !=
                                          null,
                              position: badges.BadgePosition.topEnd(
                                top: -4,
                                end: -6,
                              ),
                              child: const Icon(Icons.schedule),
                            );
                          }),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () {
                            _editorController.editPublishDate(context);
                          },
                        ),
                        MarkdownToolbar(
                          hideImage: true,
                          useIncludedTextField: false,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          iconColor: Theme.of(context).colorScheme.onSurface,
                          controller: _editorController.contentController,
                          focusNode: _contentFocusNode,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(20)),
                          width: 40,
                        ).paddingSymmetric(horizontal: 2),
                      ],
                    ).paddingSymmetric(horizontal: 6, vertical: 8),
                  ),
                ],
              ).paddingOnly(bottom: MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _contentFocusNode.dispose();
    _editorController.dispose();
    super.dispose();
  }
}
