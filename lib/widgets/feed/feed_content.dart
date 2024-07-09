import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:url_launcher/url_launcher_string.dart';

class FeedContent extends StatelessWidget {
  final String content;

  const FeedContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    return Markdown(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      data: content,
      padding: EdgeInsets.zero,
      extensionSet: markdown.ExtensionSet(
        markdown.ExtensionSet.gitHubFlavored.blockSyntaxes,
        <markdown.InlineSyntax>[
          markdown.EmojiSyntax(),
          markdown.AutolinkExtensionSyntax(),
          ...markdown.ExtensionSet.gitHubFlavored.inlineSyntaxes
        ],
      ),
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
