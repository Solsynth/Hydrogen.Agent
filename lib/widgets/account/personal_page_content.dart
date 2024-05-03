import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solian/models/personal_page.dart';
import 'package:url_launcher/url_launcher_string.dart';

class PersonalPageContent extends StatelessWidget {
  final PersonalPage item;

  const PersonalPageContent({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Markdown(
      selectable: true,
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
