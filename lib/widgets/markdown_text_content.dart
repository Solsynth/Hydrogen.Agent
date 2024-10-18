import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:path/path.dart';
import 'package:solian/providers/stickers.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:solian/widgets/auto_cache_image.dart';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'account/account_profile_popup.dart';

class MarkdownTextContent extends StatefulWidget {
  final String content;
  final String parentId;
  final bool isSelectable;
  final bool isLargeText;
  final bool isAutoWarp;

  const MarkdownTextContent({
    super.key,
    required this.content,
    required this.parentId,
    this.isSelectable = false,
    this.isLargeText = false,
    this.isAutoWarp = false,
  });

  @override
  State<MarkdownTextContent> createState() => _MarkdownTextContentState();
}

class _MarkdownTextContentState extends State<MarkdownTextContent> {
  final List<int> _stickerSizes = [];

  @override
  initState() {
    super.initState();
    final stickerRegex = RegExp(r':([-\w]+):');

    // Split the content into paragraphs
    final paragraphs = widget.content.split(RegExp(r'\n\s*\n'));

    // Iterate over each paragraph to process stickers individually

    for (var idx = 0; idx < paragraphs.length; idx++) {
      // Getting paragraph
      var paragraph = paragraphs[idx];

      // Matching stickers
      final stickerMatch = stickerRegex.allMatches(paragraph);
      if (stickerMatch.length > 3) {
        _stickerSizes.addAll(List.filled(stickerMatch.length, 16));
      } else if (stickerMatch.length > 1) {
        _stickerSizes.addAll(List.filled(stickerMatch.length, 32));
      } else {
        _stickerSizes.addAll(List.filled(stickerMatch.length, 128));
      }
    }
  }

  Widget _buildContent(BuildContext context) {
    var stickerIdx = 0;

    return Markdown(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      data: widget.content,
      padding: EdgeInsets.zero,
      styleSheet: MarkdownStyleSheet.fromTheme(
        Theme.of(context),
      ).copyWith(
          textScaler: TextScaler.linear(widget.isLargeText ? 1.1 : 1),
          blockquote: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          blockquoteDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          horizontalRuleDecoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                width: 1.0,
                color: Theme.of(context).dividerColor,
              ),
            ),
          ),
          codeblockDecoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).dividerColor,
              width: 0.3,
            ),
            borderRadius: const BorderRadius.all(Radius.circular(4)),
            color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
          )),
      builders: {
        'code': _MarkdownTextCodeElement(),
      },
      softLineBreak: true,
      extensionSet: markdown.ExtensionSet(
        <markdown.BlockSyntax>[
          markdown.CodeBlockSyntax(),
          ...markdown.ExtensionSet.commonMark.blockSyntaxes,
          ...markdown.ExtensionSet.gitHubFlavored.blockSyntaxes,
        ],
        <markdown.InlineSyntax>[
          if (widget.isAutoWarp) markdown.LineBreakSyntax(),
          _UserNameCardInlineSyntax(),
          _CustomEmoteInlineSyntax(),
          markdown.AutolinkSyntax(),
          markdown.AutolinkExtensionSyntax(),
          markdown.CodeSyntax(),
          ...markdown.ExtensionSet.commonMark.inlineSyntaxes,
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
        BoxFit? fit;
        if (url.startsWith('solink://')) {
          final segments = url.replaceFirst('solink://', '').split('/');
          switch (segments[0]) {
            case 'stickers':
              double radius = 4;
              final StickerProvider sticker = Get.find();

              // Adjust sticker size based on the sticker count in this paragraph
              width =
                  _stickerSizes.elementAtOrNull(stickerIdx)?.toDouble() ?? 16;
              height =
                  _stickerSizes.elementAtOrNull(stickerIdx)?.toDouble() ?? 16;
              if (width > 16) {
                radius = 8;
              }
              stickerIdx++;
              fit = BoxFit.contain;
              return ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(radius)),
                child: Container(
                  width: width,
                  height: height,
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: FutureBuilder(
                    future: sticker.getStickerByAlias(segments[1]),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return AutoCacheImage(
                        snapshot.data!.imageUrl,
                        width: width,
                        height: height,
                        fit: fit,
                        noErrorWidget: true,
                      );
                    },
                  ),
                ),
              ).paddingSymmetric(vertical: 4);
            case 'attachments':
              const radius = BorderRadius.all(Radius.circular(8));
              return LimitedBox(
                maxHeight: MediaQuery.of(context).size.width,
                child: ClipRRect(
                  borderRadius: radius,
                  child: AttachmentSelfContainedEntry(
                    isDense: true,
                    parentId: widget.parentId,
                    rid: segments[1],
                  ),
                ),
              ).paddingSymmetric(vertical: 4);
          }
        }
        return AutoCacheImage(
          url,
          width: width,
          height: height,
          fit: fit,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isSelectable) {
      return SelectionArea(child: _buildContent(context));
    }
    return _buildContent(context);
  }
}

class _UserNameCardInlineSyntax extends markdown.InlineSyntax {
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

class _CustomEmoteInlineSyntax extends markdown.InlineSyntax {
  _CustomEmoteInlineSyntax() : super(r':([-\w]+):');

  @override
  bool onMatch(markdown.InlineParser parser, Match match) {
    final StickerProvider sticker = Get.find();
    final alias = match[1]!.toUpperCase();
    if (sticker.stickerCache.containsKey(alias) &&
        sticker.stickerCache[alias] == null) {
      parser.advanceBy(1);
      return false;
    }

    final element = markdown.Element.empty('img');
    element.attributes['src'] = 'solink://stickers/$alias';
    parser.addNode(element);

    return true;
  }
}

class _MarkdownTextCodeElement extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(
    markdown.Element element,
    TextStyle? preferredStyle,
  ) {
    var language = '';

    if (element.attributes['class'] != null) {
      String lg = element.attributes['class'] as String;
      language = lg.substring(9).trim();
    }
    return SizedBox(
      child: FutureBuilder(
        future: (() async {
          final docPath = '../../../';
          final highlightingPath =
              join(docPath, 'assets/highlighting', language);
          await Highlighter.initialize([highlightingPath]);
          return Highlighter(
            language: highlightingPath,
            theme: PlatformDispatcher.instance.platformBrightness ==
                    Brightness.light
                ? await HighlighterTheme.loadLightTheme()
                : await HighlighterTheme.loadDarkTheme(),
          );
        })(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final highlighter = snapshot.data!;
            return Text.rich(
              highlighter.highlight(element.textContent.trim()),
              style: GoogleFonts.robotoMono(),
            );
          }
          return Text(
            element.textContent.trim(),
            style: GoogleFonts.robotoMono(),
          );
        },
      ),
    ).paddingAll(8);
  }
}
