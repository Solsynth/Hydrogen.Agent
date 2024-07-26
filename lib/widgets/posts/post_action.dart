import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/posts/post_editor.dart';

class PostAction extends StatefulWidget {
  final Post item;
  final bool noReact;

  const PostAction({super.key, required this.item, this.noReact = false});

  @override
  State<PostAction> createState() => _PostActionState();
}

class _PostActionState extends State<PostAction> {
  bool _isBusy = true;
  bool _canModifyContent = false;

  void checkAbleToModifyContent() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    setState(() => _isBusy = true);

    setState(() {
      _canModifyContent =
          auth.userProfile.value!['id'] == widget.item.author.externalId;
      _isBusy = false;
    });
  }

  @override
  void initState() {
    super.initState();
    checkAbleToModifyContent();
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
              Text(
                '#${widget.item.id.toString().padLeft(8, '0')}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          if (_isBusy) const LinearProgressIndicator().animate().scaleX(),
          Expanded(
            child: ListView(
              children: [
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  leading: const Icon(Icons.share),
                  title: Text('share'.tr),
                  onTap: () async {
                    await Share.share(
                      'postShareContent'.trParams({
                        'username': widget.item.author.nick,
                        'content': widget.item.body['text'],
                        'link':
                            'https://sn.solsynth.dev/posts/${widget.item.id}',
                      }),
                      subject: 'postShareSubject'.trParams({
                        'username': widget.item.author.nick,
                      }),
                    );
                    Navigator.pop(context);
                  },
                ),
                if (!widget.noReact)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const FaIcon(FontAwesomeIcons.reply, size: 20),
                    title: Text('reply'.tr),
                    onTap: () async {
                      final value = await AppRouter.instance.pushNamed(
                        'postEditor',
                        extra: PostPublishArguments(reply: widget.item),
                      );
                      if (value != null) {
                        Navigator.pop(context, true);
                      }
                    },
                  ),
                if (!widget.noReact)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const FaIcon(FontAwesomeIcons.retweet, size: 20),
                    title: Text('repost'.tr),
                    onTap: () async {
                      final value = await AppRouter.instance.pushNamed(
                        'postEditor',
                        extra: PostPublishArguments(repost: widget.item),
                      );
                      if (value != null) {
                        Navigator.pop(context, true);
                      }
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
                      final client = Get.find<AuthProvider>()
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
                    onTap: () async {
                      final value = await AppRouter.instance.pushNamed(
                        'postEditor',
                        extra: PostPublishArguments(edit: widget.item),
                      );
                      if (value != null) {
                        Navigator.pop(context, true);
                      }
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

  void performAction() async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return;

    final client = auth.configureClient('interactive');

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
          onPressed: _isBusy ? null : () => performAction(),
          child: Text('confirm'.tr),
        ),
      ],
    );
  }
}
