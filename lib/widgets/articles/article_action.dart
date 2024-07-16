import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/articles.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/articles/article_editor.dart';

class ArticleAction extends StatefulWidget {
  final Article item;

  const ArticleAction({super.key, required this.item});

  @override
  State<ArticleAction> createState() => _ArticleActionState();
}

class _ArticleActionState extends State<ArticleAction> {
  bool _isBusy = true;
  bool _canModifyContent = false;

  void checkAbleToModifyContent() async {
    final AuthProvider provider = Get.find();
    if (!await provider.isAuthorized) return;

    setState(() => _isBusy = true);

    final prof = await provider.getProfile();
    setState(() {
      _canModifyContent = prof.body?['id'] == widget.item.author.externalId;
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
                if (_canModifyContent)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                    leading: const Icon(Icons.edit),
                    title: Text('edit'.tr),
                    onTap: () async {
                      final value = await AppRouter.instance.pushNamed(
                        'articleEditor',
                        extra: ArticlePublishArguments(edit: widget.item),
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
                            ArticleDeletionDialog(item: widget.item),
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

class ArticleDeletionDialog extends StatefulWidget {
  final Article item;

  const ArticleDeletionDialog({super.key, required this.item});

  @override
  State<ArticleDeletionDialog> createState() => _ArticleDeletionDialogState();
}

class _ArticleDeletionDialogState extends State<ArticleDeletionDialog> {
  bool _isBusy = false;

  void performAction() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = auth.configureClient('interactive');

    setState(() => _isBusy = true);
    final resp = await client.delete('/articles/${widget.item.id}');
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
        'content': widget.item.content
            .substring(0, min(widget.item.content.length, 60))
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
