import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:solian/models/post.dart';
import 'package:solian/utils/platform.dart';
import 'package:solian/utils/service_url.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:solian/widgets/posts/attachment_screen.dart';
import 'package:uuid/uuid.dart';

class AttachmentItem extends StatefulWidget {
  final int type;
  final String url;
  final String? tag;
  final String? badge;
  final bool noTag;

  const AttachmentItem({
    super.key,
    required this.type,
    required this.url,
    this.tag,
    this.badge,
    this.noTag = false,
  });

  @override
  State<AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends State<AttachmentItem> {
  String getTag() => 'attachment-${widget.tag ?? const Uuid().v4()}';

  late final _videoPlayer = Player(
    configuration: PlayerConfiguration(
      title: 'Attachment #${getTag()}',
      logLevel: MPVLogLevel.error,
    ),
  );
  late final _videoController = VideoController(_videoPlayer);

  @override
  void initState() {
    super.initState();
    if (widget.type != 1) {
      _videoPlayer.open(
        Media(widget.url),
        play: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const borderRadius = Radius.circular(8);
    final tag = widget.noTag ? const Uuid().v4() : getTag();

    Widget content;

    if (widget.type == 1) {
      final image = PlatformInfo.canCacheImage ? CachedNetworkImageProvider(widget.url) : NetworkImage(widget.url);
      content = GestureDetector(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(borderRadius),
          child: Hero(
            tag: tag,
            child: Stack(
              children: [
                Image(
                  image: image as ImageProvider,
                  key: Key(getTag()),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                widget.badge == null
                    ? Container()
                    : Positioned(
                        right: 12,
                        bottom: 8,
                        child: Material(
                          color: Colors.transparent,
                          child: Chip(label: Text(widget.badge!)),
                        ),
                      )
              ],
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) {
              return AttachmentScreen(
                tag: tag,
                url: widget.url,
              );
            }),
          );
        },
      );
    } else {
      content = ClipRRect(
        borderRadius: const BorderRadius.all(borderRadius),
        child: Video(
          controller: _videoController,
          key: Key(getTag()),
        ),
      );
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(borderRadius),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 0.9,
        ),
      ),
      child: content,
    );
  }

  @override
  void dispose() {
    _videoPlayer.dispose();
    super.dispose();
  }
}

class AttachmentList extends StatelessWidget {
  final List<Attachment> items;
  final String provider;
  final bool noTag;

  const AttachmentList({
    super.key,
    required this.items,
    required this.provider,
    this.noTag = false,
  });

  Uri getFileUri(String fileId) => getRequestUri(provider, '/api/attachments/o/$fileId');

  @override
  Widget build(BuildContext context) {
    var renderProgress = 0;
    return FlutterCarousel(
      options: CarouselOptions(
        aspectRatio: 16 / 9,
        viewportFraction: 1,
        showIndicator: false,
      ),
      items: items.map((item) {
        renderProgress++;
        final badge = '$renderProgress/${items.length}';
        return Builder(
          builder: (BuildContext context) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: AttachmentItem(
                type: item.type,
                tag: item.fileId,
                url: getFileUri(item.fileId).toString(),
                badge: items.length <= 1 ? null : badge,
                noTag: noTag,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
