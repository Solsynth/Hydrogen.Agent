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
  final void Function(String symbol, int num) onReact;

  const PostQuickAction({
    super.key,
    required this.item,
    this.isShowReply = true,
    this.isReactable = true,
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
      isScrollControlled: true,
      context: context,
      builder: (context) => PostReactionPopup(
        item: widget.item,
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
    if (!await auth.isAuthorized) return;

    final client = auth.configureClient(service: 'interactive');

    setState(() => _isSubmitting = true);

    final resp = await client.post('/api/posts/${widget.item.alias}/react', {
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

    if (!widget.isReactable && widget.item.reactionList.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onReact('thumb_up', 0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const density = VisualDensity(horizontal: -4, vertical: -3);

    return SizedBox(
      height: 32,
      width: double.infinity,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (widget.isReactable && widget.isShowReply)
            ActionChip(
              avatar: const Icon(Icons.comment),
              label: Text(widget.item.replyCount.toString()),
              visualDensity: density,
              onPressed: () {
                showModalBottomSheet(
                  useRootNavigator: true,
                  context: context,
                  builder: (context) {
                    return PostReplyListPopup(item: widget.item);
                  },
                );
              },
            ),
          if (widget.isReactable && widget.isShowReply)
            const VerticalDivider(
                    thickness: 0.3, width: 0.3, indent: 8, endIndent: 8)
                .paddingSymmetric(horizontal: 8),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.horizontal,
              children: [
                ...widget.item.reactionList.entries.map((x) {
                  final info = reactions[x.key];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: Text(info!.icon),
                      label: Text(x.value.toString()),
                      tooltip: ':${x.key}:',
                      visualDensity: density,
                      onPressed: _isSubmitting
                          ? null
                          : () => doWidgetReact(x.key, info.attitude),
                    ),
                  );
                }),
                if (widget.isReactable)
                  ActionChip(
                    avatar: const Icon(Icons.add_reaction, color: Colors.teal),
                    label: Text('reactAdd'.tr),
                    visualDensity: density,
                    onPressed: () => showReactMenu(),
                  ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
