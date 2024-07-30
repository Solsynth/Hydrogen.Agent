import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/controllers/post_editor_controller.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/posts/post_item.dart';
import 'package:badges/badges.dart' as badges;

class PostPublishArguments {
  final Post? edit;
  final Post? reply;
  final Post? repost;
  final Realm? realm;

  PostPublishArguments({this.edit, this.reply, this.repost, this.realm});
}

class PostPublishScreen extends StatefulWidget {
  final Post? edit;
  final Post? reply;
  final Post? repost;
  final Realm? realm;

  const PostPublishScreen({
    super.key,
    this.edit,
    this.reply,
    this.repost,
    this.realm,
  });

  @override
  State<PostPublishScreen> createState() => _PostPublishScreenState();
}

class _PostPublishScreenState extends State<PostPublishScreen> {
  final _editorController = PostEditorController();

  bool _isBusy = false;

  void _applyPost() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;
    if (_editorController.isEmpty) return;

    setState(() => _isBusy = true);

    final client = auth.configureClient('interactive');

    Response resp;
    if (widget.edit != null) {
      resp = await client.put(
        '/stories/${widget.edit!.id}',
        _editorController.payload,
      );
    } else {
      resp = await client.post(
        '/stories',
        _editorController.payload,
      );
    }
    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      _editorController.localClear();
      AppRouter.instance.pop(resp.body);
    }

    setState(() => _isBusy = false);
  }

  void syncWidget() {
    if (widget.edit != null) {
      _editorController.editTarget = widget.edit;
    }
  }

  void cancelAction() {
    AppRouter.instance.pop();
  }

  @override
  void initState() {
    super.initState();
    syncWidget();
  }

  @override
  Widget build(BuildContext context) {
    final notifyBannerActions = [
      TextButton(
        onPressed: cancelAction,
        child: Text('cancel'.tr),
      )
    ];

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarLeadingButton.adaptive(context),
          title: AppBarTitle('postEditorModeStory'.tr),
          centerTitle: false,
          toolbarHeight: SolianTheme.toolbarHeight(context),
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
          children: [
            ListTile(
              tileColor: Theme.of(context).colorScheme.surfaceContainerLow,
              title: Text(
                _editorController.title ?? 'title'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                _editorController.description ?? 'description'.tr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              contentPadding: const EdgeInsets.only(
                left: 16,
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
            Expanded(
              child: ListView(
                children: [
                  if (_isBusy)
                    const LinearProgressIndicator().animate().scaleX(),
                  if (widget.edit != null && widget.edit!.isDraft != true)
                    MaterialBanner(
                      leading: const Icon(Icons.edit),
                      leadingPadding:
                          const EdgeInsets.only(left: 10, right: 20),
                      dividerColor: Colors.transparent,
                      content: Text('postEditingNotify'.tr),
                      actions: notifyBannerActions,
                    ),
                  if (widget.reply != null)
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
                        PostItem(
                          item: widget.reply!,
                          isReactable: false,
                        ).paddingOnly(bottom: 8),
                      ],
                    ),
                  if (widget.repost != null)
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
                        PostItem(
                          item: widget.repost!,
                          isReactable: false,
                        ).paddingOnly(bottom: 8),
                      ],
                    ),
                  if (widget.realm != null)
                    MaterialBanner(
                      leading: const Icon(Icons.group),
                      leadingPadding:
                          const EdgeInsets.only(left: 10, right: 20),
                      dividerColor: Colors.transparent,
                      content: Text(
                        'postInRealmNotify'
                            .trParams({'realm': '#${widget.realm!.alias}'}),
                      ),
                      actions: notifyBannerActions,
                    ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      maxLines: null,
                      autofocus: true,
                      autocorrect: true,
                      keyboardType: TextInputType.multiline,
                      controller: _editorController.contentController,
                      decoration: InputDecoration.collapsed(
                        hintText: 'postContentPlaceholder'.tr,
                      ),
                      onTapOutside: (_) =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                    ),
                  ),
                  const SizedBox(height: 120)
                ],
              ),
            ),
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                            Text('postRestoreFromLocal'.tr, style: textStyle)
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
                        .animate(target: doShow ? 1 : 0)
                        .fade(curve: Curves.easeInOut, duration: 300.ms);
                  }),
                  if (_editorController.mode.value == 0)
                    Obx(
                      () => TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: _editorController.contentLength.value / 4096,
                        ),
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        builder: (context, value, _) => LinearProgressIndicator(
                          minHeight: 2,
                          color: _editorController.contentLength.value > 4096
                              ? Colors.red[900]
                              : Theme.of(context).colorScheme.primary,
                          value: value,
                        ),
                      ),
                    ),
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Obx(
                          () => IconButton(
                            icon: _editorController.isDraft.value
                                ? const Icon(Icons.drive_file_rename_outline)
                                : const Icon(Icons.public),
                            color: _editorController.isDraft.value
                                ? Colors.grey.shade600
                                : Colors.green.shade700,
                            onPressed: () {
                              _editorController.toggleDraftMode();
                            },
                          ),
                        ),
                        IconButton(
                          icon: Obx(
                            () => badges.Badge(
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
                              child: const Icon(Icons.camera_alt),
                            ),
                          ),
                          color: Theme.of(context).colorScheme.primary,
                          onPressed: () =>
                              _editorController.editAttachment(context),
                        ),
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
    _editorController.dispose();
    super.dispose();
  }
}
