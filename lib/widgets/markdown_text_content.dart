import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_selectionarea/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:markdown/markdown.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/stickers.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'account/account_profile_popup.dart';

class MarkdownTextContent extends StatelessWidget {
  final String content;
  final String parentId;
  final bool isSelectable;

  const MarkdownTextContent({
    super.key,
    required this.content,
    required this.parentId,
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
          markdown.AutolinkSyntax(),
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
      imageBuilder: (uri, title, alt) {
        var url = uri.toString();
        double? width, height;
        if (url.startsWith('solink://')) {
          final segments = url.replaceFirst('solink://', '').split('/');
          switch (segments[0]) {
            case 'stickers':
              final StickerProvider sticker = Get.find();
              url = sticker.aliasImageMapping[segments[1]]!;
              width = 28;
              height = 28;
              break;
            case 'attachments':
              const radius = BorderRadius.all(Radius.circular(8));
              return LimitedBox(
                maxHeight: 360,
                child: ClipRRect(
                  borderRadius: radius,
                  child: AttachmentSelfContainedEntry(
                    isDense: true,
                    parentId: parentId,
                    id: int.parse(segments[1]),
                  ),
                ),
              ).paddingSymmetric(vertical: 4);
          }
        }

        return PlatformInfo.canCacheImage
            ? CachedNetworkImage(imageUrl: url, width: width, height: height)
            : Image.network(url, width: width, height: height);
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
    final StickerProvider sticker = Get.find();
    final alias = match[1]!;
    if (sticker.aliasImageMapping[alias] == null) {
      parser.advanceBy(1);
      return false;
    }

    final element = markdown.Element.empty('img');
    element.attributes['src'] = 'solink://stickers/$alias';
    parser.addNode(element);

    return true;
  }
}
