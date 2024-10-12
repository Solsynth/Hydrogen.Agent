import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:solian/models/link.dart';
import 'package:solian/providers/link_expander.dart';
import 'package:solian/widgets/auto_cache_image.dart';
import 'package:url_launcher/url_launcher_string.dart';

class LinkExpansion extends StatefulWidget {
  final String content;

  const LinkExpansion({super.key, required this.content});

  @override
  State<LinkExpansion> createState() => _LinkExpansionState();
}

class _LinkExpansionState extends State<LinkExpansion> {
  Widget _buildImage(String url, {double? width, double? height}) {
    if (url.endsWith('svg')) {
      return SvgPicture.network(url, width: width, height: height);
    }
    return AutoCacheImage(
      url,
      width: width,
      height: height,
    );
  }

  List<LinkMeta>? _meta;

  Future<void> _doExpand() async {
    final linkRegex = RegExp(
      r'(?<!\()(?:(?:https?):\/\/|www\.)(?:[-_a-z0-9]+\.)*(?:[-a-z0-9]+\.[-a-z0-9]+)[^\s<]*[^\s<?!.,:*_~]',
    );
    final matches = linkRegex.allMatches(widget.content);
    if (matches.isEmpty) return;

    final LinkExpandProvider expandController = Get.find();

    if (matches.isEmpty) return;

    List<LinkMeta> out = List.empty(growable: true);
    for (final x in matches) {
      final result = await expandController.expandLink(x.group(0)!);
      if (result != null) out.add(result);
    }

    setState(() => _meta = out);
  }

  @override
  void initState() {
    super.initState();
    _doExpand();
  }

  @override
  Widget build(BuildContext context) {
    if (_meta?.isEmpty ?? true) return const SizedBox.shrink();

    return Wrap(
      children: _meta!.map((x) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: _meta!.length == 1 ? 480 : 340,
          ),
          child: Builder(
            builder: (context) {
              final isRichDescription = [
                'solsynth.dev',
              ].contains(Uri.parse(x.url).host);

              return GestureDetector(
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ([(x.icon?.isNotEmpty ?? false), x.siteName != null]
                          .any((x) => x))
                        Row(
                          children: [
                            if (x.icon?.isNotEmpty ?? false)
                              ClipRRect(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                child: _buildImage(
                                  x.icon!,
                                  width: 32,
                                  height: 32,
                                ),
                              ).paddingOnly(right: 8),
                            if (x.siteName != null)
                              Expanded(
                                child: Text(
                                  x.siteName!,
                                  style: Theme.of(context).textTheme.labelLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ).paddingOnly(
                          bottom: (x.icon?.isNotEmpty ?? false) ? 8 : 4,
                        ),
                      if (x.image != null &&
                          (x.image?.startsWith('http') ?? false))
                        ClipRRect(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          child: _buildImage(x.image!),
                        ).paddingOnly(bottom: 8),
                      Text(
                        x.title ?? 'No Title',
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      if (x.description != null && isRichDescription)
                        MarkdownBody(data: x.description!)
                      else if (x.description != null)
                        Text(
                          x.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ).paddingAll(12),
                ),
                onTap: () {
                  launchUrlString(x.url);
                },
              );
            },
          ),
        );
      }).toList(),
    );
  }
}
