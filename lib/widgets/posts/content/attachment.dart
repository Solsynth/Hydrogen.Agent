import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chewie/chewie.dart';
import 'package:solian/models/post.dart';
import 'package:solian/utils/service_url.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:solian/widgets/posts/attachment_screen.dart';
import 'package:video_player/video_player.dart';

class AttachmentItem extends StatefulWidget {
  final Attachment item;
  final String? badge;

  const AttachmentItem({super.key, required this.item, this.badge});

  @override
  State<AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends State<AttachmentItem> {
  String getTag() => 'attachment-${widget.item.fileId}';

  Uri getFileUri() =>
      getRequestUri('interactive', '/api/attachments/o/${widget.item.fileId}');

  VideoPlayerController? _vpController;
  ChewieController? _chewieController;

  @override
  Widget build(BuildContext context) {
    const borderRadius = Radius.circular(16);

    Widget content;

    if (widget.item.type == 1) {
      content = GestureDetector(
        child: ClipRRect(
          borderRadius: const BorderRadius.all(borderRadius),
          child: Hero(
            tag: getTag(),
            child: Stack(
              children: [
                Image.network(
                  getFileUri().toString(),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
                widget.badge == null
                    ? Container()
                    : Positioned(
                        right: 12,
                        bottom: 8,
                        child: Chip(label: Text(widget.badge!)),
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
                tag: getTag(),
                url: getFileUri().toString(),
              );
            }),
          );
        },
      );
    } else {
      _vpController = VideoPlayerController.networkUrl(getFileUri());
      _chewieController = ChewieController(
        videoPlayerController: _vpController!,
      );

      content = FutureBuilder(
        future: () async {
          await _vpController?.initialize();
          return true;
        }(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ClipRRect(
              borderRadius: const BorderRadius.all(borderRadius),
              child: Chewie(
                controller: _chewieController!,
              ),
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
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
    _vpController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}

class AttachmentList extends StatelessWidget {
  final List<Attachment> items;

  const AttachmentList({super.key, required this.items});

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
                  item: item, badge: items.length <= 1 ? null : badge),
            );
          },
        );
      }).toList(),
    );
  }
}
