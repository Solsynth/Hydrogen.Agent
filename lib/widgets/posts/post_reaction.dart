import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/reaction.dart';

class PostReactionPopup extends StatelessWidget {
  final Map<String, int> reactionList;
  final void Function(String key, ReactInfo info) onReact;

  const PostReactionPopup({
    super.key,
    required this.reactionList,
    required this.onReact,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'postReaction'.tr,
            style: Theme.of(context).textTheme.headlineSmall,
          ).paddingOnly(left: 24, right: 24, top: 32, bottom: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                runSpacing: 4.0,
                spacing: 8.0,
                children: reactions.entries.map((e) {
                  return ActionChip(
                    avatar: Text(e.value.icon),
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e.key,
                            style: const TextStyle(fontFamily: 'monospace')),
                        const SizedBox(width: 6),
                        Text('x${reactionList[e.key]?.toString() ?? '0'}',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    onPressed: () {
                      onReact(e.key, e.value);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ).paddingSymmetric(horizontal: 24),
            ),
          ),
        ],
      ),
    );
  }
}
