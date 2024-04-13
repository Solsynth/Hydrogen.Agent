import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solian/models/post.dart';

class MomentContent extends StatelessWidget {
  final Post item;
  final bool brief;

  const MomentContent({super.key, required this.brief, required this.item});

  @override
  Widget build(BuildContext context) {
    return Markdown(
      selectable: !brief,
      data: item.content,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(0),
    );
  }
}
