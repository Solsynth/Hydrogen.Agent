import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/post.dart';
import 'package:solian/models/reaction.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/widgets/posts/post_reaction.dart';
import 'package:solian/widgets/posts/post_replies.dart';

class PostQuickAction extends StatefulWidget {
  final Post item;
  final bool isReactable;
  final bool isShowReply;
  final Function onComment;
  final void Function(String symbol, int num) onReact;

  const PostQuickAction({
    super.key,
    required this.item,
    this.isShowReply = true,
    this.isReactable = true,
    required this.onComment,
    required this.onReact,
  });

  @override
  State<PostQuickAction> createState() => _PostQuickActionState();
}

class _PostQuickActionState extends State<PostQuickAction> {
  bool _isSubmitting = false;

  void showReactMenu() {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) => PostReactionPopup(
        reactionList: widget.item.metric!.reactionList,
        onReact: (key, value) {
          doWidgetReact(key, value.attitude);
        },
      ),
    );
  }

  Future<void> doWidgetReact(String symbol, int attitude) async {
    if (!widget.isReactable) return;

    final AuthProvider auth = Get.find();

    if (_isSubmitting) return;
    if (auth.isAuthorized.isFalse) return;

    final client = await auth.configureClient('interactive');

    setState(() => _isSubmitting = true);

    final resp = await client.post('/posts/${widget.item.id}/react', {
      'symbol': symbol,
      'attitude': attitude,
    });
    if (resp.statusCode == 201) {
      widget.onReact(symbol, 1);
      context.showSnackbar('reactCompleted'.tr);
    } else if (resp.statusCode == 204) {
      widget.onReact(symbol, -1);
      context.showSnackbar('reactUncompleted'.tr);
    } else {
      context.showErrorDialog(resp.bodyString);
    }

    setState(() => _isSubmitting = false);
  }

  @override
  void initState() {
    super.initState();

    if (!widget.isReactable && widget.item.metric!.reactionList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReact('thumb_up', 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const density = VisualDensity(horizontal: -4, vertical: -3);

    final reactionEntries = widget.item.metric!.reactionList.entries.toList();

    return SizedBox(
      height: 32,
      width: double.infinity,
      child: CustomScrollView(
        scrollDirection: Axis.horizontal,
        slivers: [
          if (widget.isReactable && widget.isShowReply)
            SliverToBoxAdapter(
              child: ActionChip(
                avatar: const Icon(Icons.comment),
                label: Text(widget.item.metric!.replyCount.toString()),
                visualDensity: density,
                onPressed: () {
                  showModalBottomSheet(
                    useRootNavigator: true,
                    context: context,
                    builder: (context) {
                      return PostReplyListPopup(item: widget.item);
                    },
                  ).then((signal) {
                    if (signal == true) {
                      widget.onComment();
                    }
                  });
                },
              ),
            ),
          if (widget.isReactable && widget.isShowReply)
            SliverToBoxAdapter(
              child: const VerticalDivider(
                thickness: 0.3,
                width: 0.3,
                indent: 8,
                endIndent: 8,
              ).paddingSymmetric(horizontal: 8),
            ),
          SliverList.builder(
            itemCount: reactionEntries.length,
            itemBuilder: (context, index) {
              final x = reactionEntries[index];
              final info = reactions[x.key];
              return ActionChip(
                avatar: Text(info!.icon),
                label: Text(x.value.toString()),
                tooltip: ':${x.key}:',
                visualDensity: density,
                onPressed: _isSubmitting
                    ? null
                    : () => doWidgetReact(x.key, info.attitude),
              ).paddingOnly(right: 8);
            },
          ),
          if (widget.isReactable)
            SliverToBoxAdapter(
              child: ActionChip(
                avatar: const Icon(Icons.add_reaction, color: Colors.teal),
                label: Text('reactAdd'.tr),
                visualDensity: density,
                onPressed: () => showReactMenu(),
              ),
            ),
        ],
      ),
    );
  }
}
