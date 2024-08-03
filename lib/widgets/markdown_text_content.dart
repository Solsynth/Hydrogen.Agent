import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:markdown/markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'account/account_profile_popup.dart';

class MarkdownTextContent extends StatelessWidget {
  final String content;
  final bool isSelectable;

  const MarkdownTextContent({
    super.key,
    required this.content,
    this.isSelectable = false,
  });

  Widget _buildContent(BuildContext context) {
    return Markdown(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      data: content,
      padding: EdgeInsets.zero,
      styleSheet: MarkdownStyleSheet.fromTheme(
        Theme.of(context),
      ).copyWith(
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
          _UserNameCardInlineSyntax(),
          _CustomEmoteInlineSyntax(),
          markdown.EmojiSyntax(),
          markdown.AutolinkExtensionSyntax(),
          ...markdown.ExtensionSet.gitHubFlavored.inlineSyntaxes
        ],
      ),
      onTapLink: (text, href, title) async {
        if (href == null) return;
        if (href.startsWith('solink://')) {
          final segments = href.replaceFirst('solink://', '').split('/');
          switch (segments[0]) {
            case 'users':
              showModalBottomSheet(
                useRootNavigator: true,
                isScrollControlled: true,
                backgroundColor: Theme.of(context).colorScheme.surface,
                context: context,
                builder: (context) => AccountProfilePopup(
                  name: segments[1],
                ),
              );
          }
          return;
        }

        await launchUrlString(
          href,
          mode: LaunchMode.externalApplication,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isSelectable) {
      return SelectionArea(child: _buildContent(context));
    }
    return _buildContent(context);
  }
}

class _UserNameCardInlineSyntax extends InlineSyntax {
  _UserNameCardInlineSyntax() : super(r'@[a-zA-Z0-9_]+');

  @override
  bool onMatch(markdown.InlineParser parser, Match match) {
    final alias = match[0]!;
    final anchor = markdown.Element.text('a', alias)
      ..attributes['href'] = Uri.encodeFull(
        'solink://users/${alias.substring(1)}',
      );
    parser.addNode(anchor);

    return true;
  }
}

class _CustomEmoteInlineSyntax extends InlineSyntax {
  _CustomEmoteInlineSyntax() : super(r':([a-z0-9_+-]+):');

  @override
  bool onMatch(markdown.InlineParser parser, Match match) {
    // final alias = match[1]!;
    // TODO mapping things...
    final element = markdown.Element.empty('img');
    element.attributes['src'] = 'https://www.twitch.tv/creatorcamp/assets/uploads/lul.png';
    parser.addNode(element);

    return true;
  }
}
