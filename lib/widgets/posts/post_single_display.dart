import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/post.dart';
import 'package:solian/widgets/posts/post_item.dart';

class PostSingleDisplay extends StatelessWidget {
  final Post item;

  const PostSingleDisplay({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      child: Card(
        child: SingleChildScrollView(
          child: PostItem(
            item: item,
          ).paddingSymmetric(horizontal: 10, vertical: 16),
        ),
      ),
    );
  }
}
