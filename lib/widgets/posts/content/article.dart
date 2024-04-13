import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solian/models/post.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:solian/utils/service_url.dart';
import 'package:url_launcher/url_launcher_string.dart';

class ArticleContent extends StatelessWidget {
  final Post item;
  final bool brief;

  const ArticleContent({super.key, required this.item, required this.brief});

  @override
  Widget build(BuildContext context) {
    final headingPart = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          item.description,
          style: Theme.of(context).textTheme.bodyMedium,
        )
      ],
    );

    return brief
        ? headingPart
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: headingPart,
              ),
              Markdown(
                padding: const EdgeInsets.all(0),
                selectable: !brief,
                data: item.content,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                extensionSet: markdown.ExtensionSet(
                  markdown.ExtensionSet.gitHubFlavored.blockSyntaxes,
                  markdown.ExtensionSet.gitHubFlavored.inlineSyntaxes,
                ),
                onTapLink: (text, href, title) async {
                  if (href == null) return;
                  await launchUrlString(
                    href,
                    mode: LaunchMode.externalApplication,
                  );
                },
                imageBuilder: (url, _, __) {
                  if (url.toString().startsWith("/api/attachments")) {
                    return Image.network(
                        getRequestUri('interactive', url.toString())
                            .toString());
                  } else {
                    return Image.network(url.toString());
                  }
                },
              ),
            ],
          );
  }
}
