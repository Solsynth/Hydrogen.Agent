import 'package:flutter/material.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/posts/post_list.dart';

class PostSingleDisplay extends StatelessWidget {
  final Post item;
  final Function onUpdate;

  const PostSingleDisplay({
    super.key,
    required this.item,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        alignment: Alignment.center,
        child: Card(
          child: PostListEntryWidget(
            item: item,
            isClickable: true,
            isShowEmbed: true,
            isNestedClickable: true,
            onUpdate: onUpdate,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
        ),
      ),
    );
  }
}
