import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/link_expander.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LinkExpansion extends StatelessWidget {
  final String content;

  const LinkExpansion({super.key, required this.content});

  Widget _buildImage(String url, {double? width, double? height}) {
    return PlatformInfo.canCacheImage
        ? CachedNetworkImage(imageUrl: url, width: width, height: height)
        : Image.network(url, width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    final linkRegex = RegExp(
      r'(?:(?:https?|ftp):\/\/|www\.)'
      r'(?:[-_a-z0-9]+\.)*(?:[-a-z0-9]+\.[-a-z0-9]+)'
      r'[^\s<]*'
      r'[^\s<?!.,:*_~]',
    );
    final matches = linkRegex.allMatches(content);
    if (matches.isEmpty) {
      return const SizedBox();
    }

    final LinkExpandController expandController = Get.find();

    return Wrap(
      children: matches.map((x) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: matches.length == 1 ? 480 : 340,
          ),
          child: FutureBuilder(
            future: expandController.expandLink(x.group(0)!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox();
              }

              final isRichDescription = [
                "solsynth.dev",
              ].contains(Uri.parse(snapshot.data!.url).host);

              return GestureDetector(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ([
                        (snapshot.data!.icon?.isNotEmpty ?? false),
                        snapshot.data!.siteName != null
                      ].any((x) => x))
                        Row(
                          children: [
                            if (snapshot.data!.icon?.isNotEmpty ?? false)
                              ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                child: _buildImage(
                                  snapshot.data!.icon!,
                                  width: 32,
                                  height: 32,
                                ),
                              ).paddingOnly(right: 8),
                            if (snapshot.data!.siteName != null)
                              Text(
                                snapshot.data!.siteName!,
                                style: Theme.of(context).textTheme.labelLarge,
                              ),
                          ],
                        ).paddingOnly(
                          bottom: (snapshot.data!.icon?.isNotEmpty ?? false)
                              ? 8
                              : 4,
                        ),
                      if (snapshot.data!.image != null &&
                          (snapshot.data!.image?.startsWith('http') ?? false))
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          child: _buildImage(
                            snapshot.data!.image!,
                          ),
                        ).paddingOnly(bottom: 8),
                      Text(
                        snapshot.data!.title ?? 'No Title',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (snapshot.data!.description != null &&
                          isRichDescription)
                        MarkdownBody(data: snapshot.data!.description!)
                      else if (snapshot.data!.description != null)
                        Text(
                          snapshot.data!.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ).paddingAll(12),
                ),
                onTap: () {
                  launchUrlString(x.group(0)!);
                },
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
