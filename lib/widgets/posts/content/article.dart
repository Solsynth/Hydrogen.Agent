import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:solian/models/post.dart';
import 'package:markdown/markdown.dart' as markdown;
import 'package:url_launcher/url_launcher_string.dart';

class ArticleContent extends StatelessWidget {
  final Post item;
  final bool brief;

  const ArticleContent({super.key, required this.item, required this.brief});

  @override
  Widget build(BuildContext context) {
    return brief
        ? Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
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
            ),
        )
        : Column(
            children: [
              ListTile(
                title: Text(item.title),
                subtitle: Text(item.description),
              ),
              const Divider(color: Color(0xffefefef)),
              Markdown(
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
              ),
            ],
          );
  }
}
