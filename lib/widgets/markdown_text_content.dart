import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:url_launcher/url_launcher_string.dart';

class MarkdownTextContent extends StatelessWidget {
  final String content;
  final bool isSelectable;

  const MarkdownTextContent({
    super.key,
    required this.content,
    this.isSelectable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Markdown(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      data: content,
      padding: EdgeInsets.zero,
      selectable: isSelectable,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              width: 1.0,
              color: Theme.of(context).dividerColor,
            ),
          ),
        ),
      ),
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
