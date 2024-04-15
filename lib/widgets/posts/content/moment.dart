import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solian/models/post.dart';
import 'package:url_launcher/url_launcher_string.dart';

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
      onTapLink: (text, href, title) async {
        if (href == null) return;
        await launchUrlString(
          href,
          mode: LaunchMode.externalApplication,
        );
      },
    );
  }
}
