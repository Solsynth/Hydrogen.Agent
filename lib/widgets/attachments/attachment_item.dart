import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/platform.dart';
import 'package:solian/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

class AttachmentItem extends StatefulWidget {
  final String parentId;
  final Attachment item;
  final bool showBadge;
  final bool showHideButton;
  final BoxFit fit;
  final String? badge;
  final Function? onHide;

  const AttachmentItem({
    super.key,
    required this.parentId,
    required this.item,
    this.badge,
    this.fit = BoxFit.cover,
    this.showBadge = true,
    this.showHideButton = true,
    this.onHide,
  });

  @override
  State<AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends State<AttachmentItem> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  void ensureInitVideo() {
    if (_videoPlayerController != null) return;

    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(
      '${ServiceFinder.services['paperclip']}/api/attachments/${widget.item.id}',
    ));
    _videoPlayerController!.initialize();
    _chewieController = ChewieController(
      aspectRatio: widget.item.metadata?['ratio'] ?? 16 / 9,
      videoPlayerController: _videoPlayerController!,
      customControls: PlatformInfo.isMobile
          ? const MaterialControls()
          : const MaterialDesktopControls(),
      materialProgressColors: ChewieProgressColors(
        playedColor: Theme.of(context).colorScheme.primary,
        handleColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.item.mimetype.split('/').first) {
      case 'image':
        return Hero(
          tag: Key('a${widget.item.uuid}p${widget.parentId}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (PlatformInfo.canCacheImage)
                CachedNetworkImage(
                  fit: widget.fit,
                  imageUrl:
                      '${ServiceFinder.services['paperclip']}/api/attachments/${widget.item.id}',
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Center(
                    child: CircularProgressIndicator(
                      value: downloadProgress.progress,
                    ),
                  ),
                )
              else
                Image.network(
                  '${ServiceFinder.services['paperclip']}/api/attachments/${widget.item.id}',
                  fit: widget.fit,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                ),
              if (widget.showBadge && widget.badge != null)
                Positioned(
                  right: 12,
                  bottom: 8,
                  child: Material(
                    color: Colors.transparent,
                    child: Chip(label: Text(widget.badge!)),
                  ),
                ),
              if (widget.showHideButton && widget.item.isMature)
                Positioned(
                  top: 8,
                  left: 12,
                  child: Material(
                    color: Colors.transparent,
                    child: ActionChip(
                      visualDensity:
                          const VisualDensity(vertical: -4, horizontal: -4),
                      avatar: Icon(
                        Icons.visibility_off,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      label: Text('hide'.tr),
                      onPressed: () {
                        if (widget.onHide != null) widget.onHide!();
                      },
                    ),
                  ),
                ),
            ],
          ),
        );
      case 'video':
        ensureInitVideo();
        return Chewie(controller: _chewieController!);
      default:
        return Center(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 280,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.file_present, size: 32),
                const SizedBox(height: 6),
                Text(
                  widget.item.mimetype,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item.alt,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  icon: const Icon(Icons.launch),
                  label: Text('openInBrowser'.tr),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity(vertical: -2, horizontal: -4),
                  ),
                  onPressed: () {
                    launchUrlString(
                      '${ServiceFinder.services['paperclip']}/api/attachments/${widget.item.id}',
                    );
                  },
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }
}
