import 'dart:math';

import 'package:file_saver/file_saver.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/posts.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/posts/post_editor.dart';
import 'package:solian/widgets/loading_indicator.dart';
import 'package:solian/widgets/posts/post_share.dart';
import 'package:solian/widgets/reports/abuse_report.dart';

class PostAction extends StatefulWidget {
  final Post item;
  final bool noReact;

  const PostAction({super.key, required this.item, this.noReact = false});

  @override
  State<PostAction> createState() => _PostActionState();
}

class _PostActionState extends State<PostAction> {
  bool _isBusy = false;
  bool _canModifyContent = false;

  void _checkAbleToModifyContent() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    _canModifyContent = auth.userProfile.value!['id'] == widget.item.author.id;
  }

  Future<void> _doShare({bool noUri = false}) async {
    ShareResult result;
    String id;
    final box = context.findRenderObject() as RenderBox?;
    if (widget.item.alias?.isNotEmpty ?? false) {
      id = '${widget.item.areaAlias}/${widget.item.alias}';
    } else {
      id = '${widget.item.id}';
    }
    if ((PlatformInfo.isAndroid || PlatformInfo.isIOS) && !noUri) {
      result = await Share.shareUri(
        Uri.parse('https://solsynth.dev/posts/$id'),
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } else {
      final extraContent = <String?>[
        widget.item.body['title'],
        widget.item.body['description'],
      ].where((x) => x != null && x.isNotEmpty).toList();
      final isExtraNotEmpty = extraContent.any((x) => x != null);
      result = await Share.share(
        'postShareContent'.trParams({
          'username': widget.item.author.nick,
          'content':
              '${extraContent.join('\n')}${isExtraNotEmpty ? '\n\n' : ''}${widget.item.body['content'] ?? 'no content'}',
          'link': 'https://solsynth.dev/posts/$id',
        }),
        subject: 'postShareSubject'.trParams({
          'username': '@${widget.item.author.name}',
          'title': widget.item.body['title'] ?? '#${widget.item.id}',
        }),
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    }

    if (result.status != ShareResultStatus.dismissed) {
      await FirebaseAnalytics.instance.logShare(
        contentType: 'Post',
        itemId: widget.item.id.toString(),
        method: result.raw,
      );
    }
  }

  Future<void> _shareImage() async {
    final List<String> attachments = widget.item.body['attachments'] is List
        ? List.from(widget.item.body['attachments']?.whereType<String>())
        : List.empty();
    final hasMultipleAttachment = attachments.length > 1;

    setState(() => _isBusy = true);

    final double width = hasMultipleAttachment ? 640 : 480;

    final screenshot = ScreenshotController();
    final image = await screenshot.captureFromLongWidget(
      MediaQuery(
        data: MediaQuery.of(context).copyWith(
          size: Size(width, double.infinity),
        ),
        child: PostShareImage(item: widget.item),
      ),
      context: context,
      pixelRatio: 2,
      constraints: BoxConstraints(
        minWidth: 480,
        maxWidth: width,
        minHeight: 640,
        maxHeight: double.infinity,
      ),
    );

    final filename = 'share_post#${widget.item.id}';

    if (PlatformInfo.isAndroid || PlatformInfo.isIOS) {
      final box = context.findRenderObject() as RenderBox?;

      final file = XFile.fromData(
        image,
        mimeType: 'image/png',
        name: filename,
      );
      await Share.shareXFiles(
        [file],
        subject: 'postShareSubject'.trParams({
          'username': '@${widget.item.author.name}',
          'title': widget.item.body['title'] ?? '#${widget.item.id}',
        }),
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    } else {
      final filepath = await FileSaver.instance.saveFile(
        name: filename,
        ext: 'png',
        mimeType: MimeType.png,
        bytes: image,
      );
      context.showSnackbar('fileSavedAt'.trParams({'path': filepath}));
    }

    setState(() => _isBusy = false);
  }

  Future<Post> _getFullPost() async {
    final PostProvider posts = Get.find();

    try {
      final resp = await posts.getPost(widget.item.id.toString());
      return Post.fromJson(resp.body);
    } catch (e) {
      context.showErrorDialog(e).then((_) => Navigator.pop(context));
    }

    return widget.item;
  }

  @override
  void initState() {
    super.initState();
    _checkAbleToModifyContent();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'postActionList'.tr,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                children: [
                  Text(
                    '#${widget.item.id.toString().padLeft(8, '0')}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (widget.item.alias?.isNotEmpty ?? false)
                    Text(
                      '·',
                      style: Theme.of(context).textTheme.bodySmall,
                    ).paddingSymmetric(horizontal: 6),
                  if (widget.item.alias?.isNotEmpty ?? false)
                    Expanded(
                      child: Text(
                        '${widget.item.areaAlias}:${widget.item.alias}',
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          LoadingIndicator(
            isActive: _isBusy,
            backgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHigh
                .withOpacity(0.5),
          ),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.share),
                  title: Text('share'.tr),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (PlatformInfo.isIOS || PlatformInfo.isAndroid)
                        IconButton(
                          icon: const Icon(Icons.link_off),
                          tooltip: 'shareNoUri'.tr,
                          onPressed: () async {
                            await _doShare(noUri: true);
                            Navigator.pop(context);
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.image),
                        tooltip: 'shareImage'.tr,
                        onPressed: _isBusy
                            ? null
                            : () async {
                                await _shareImage();
                                Navigator.pop(context);
                              },
                      ),
                    ],
                  ),
                  onTap: () async {
                    await _doShare();
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.flag),
                  title: Text('report'.tr),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AbuseReportDialog(
                        resourceId: 'post:${widget.item.id}',
                      ),
                    ).then((status) {
                      if (status == true) {
                        Navigator.pop(context);
                      }
                    });
                  },
                ),
                if (!widget.noReact)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const FaIcon(FontAwesomeIcons.reply, size: 20),
                    title: Text('reply'.tr),
                    onTap: () async {
                      Navigator.pop(
                        context,
                        AppRouter.instance.pushNamed(
                          'postEditor',
                          extra: PostPublishArguments(reply: widget.item),
                        ),
                      );
                    },
                  ),
                if (!widget.noReact)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const FaIcon(FontAwesomeIcons.retweet, size: 20),
                    title: Text('repost'.tr),
                    onTap: () async {
                      Navigator.pop(
                        context,
                        AppRouter.instance.pushNamed(
                          'postEditor',
                          extra: PostPublishArguments(repost: widget.item),
                        ),
                      );
                    },
                  ),
                if (_canModifyContent && !widget.noReact)
                  const Divider(thickness: 0.3, height: 0.3)
                      .paddingSymmetric(vertical: 16),
                if (_canModifyContent)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.push_pin),
                    title: Text(
                      widget.item.pinnedAt == null
                          ? 'pinPost'.tr
                          : 'unpinPost'.tr,
                    ),
                    onTap: () async {
                      final client = await Get.find<AuthProvider>()
                          .configureClient('interactive');
                      await client.post('/posts/${widget.item.id}/pin', {});
                      Navigator.pop(context, true);
                    },
                  ),
                if (_canModifyContent)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.edit),
                    title: Text('edit'.tr),
                    onTap: _isBusy
                        ? null
                        : () async {
                            setState(() => _isBusy = true);
                            var item = widget.item;
                            if (item.body?['content_truncated'] == true) {
                              item = await _getFullPost();
                            }
                            Navigator.pop(
                              context,
                              AppRouter.instance.pushNamed(
                                'postEditor',
                                extra: PostPublishArguments(edit: item),
                              ),
                            );
                            if (mounted) setState(() => _isBusy = false);
                          },
                  ),
                if (_canModifyContent)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.delete),
                    title: Text('delete'.tr),
                    onTap: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) =>
                            PostDeletionDialog(item: widget.item),
                      );
                      if (value != null) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PostDeletionDialog extends StatefulWidget {
  final Post item;

  const PostDeletionDialog({super.key, required this.item});

  @override
  State<PostDeletionDialog> createState() => _PostDeletionDialogState();
}

class _PostDeletionDialogState extends State<PostDeletionDialog> {
  bool _isBusy = false;

  void _performAction() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final client = await auth.configureClient('interactive');

    setState(() => _isBusy = true);
    final resp = await client.delete('/posts/${widget.item.id}');
    setState(() => _isBusy = false);

    if (resp.statusCode != 200) {
      context.showErrorDialog(resp.bodyString);
    } else {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('postDeletionConfirm'.tr),
      content: Text('postDeletionConfirmCaption'.trParams({
        'content': widget.item.body['content']
            .substring(0, min<int>(widget.item.body['content'].length, 60))
            .trim(),
      })),
      actions: <Widget>[
        TextButton(
          onPressed: _isBusy ? null : () => Navigator.pop(context),
          child: Text('cancel'.tr),
        ),
        TextButton(
          onPressed: _isBusy ? null : () => _performAction(),
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
