import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/platform.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:url_launcher/url_launcher_string.dart';

class AttachmentItem extends StatefulWidget {
  final String parentId;
  final Attachment item;
  final bool showBadge;
  final bool showHideButton;
  final bool autoload;
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
    this.autoload = false,
    this.onHide,
  });

  @override
  State<AttachmentItem> createState() => _AttachmentItemState();
}

class _AttachmentItemState extends State<AttachmentItem> {
  @override
  Widget build(BuildContext context) {
    switch (widget.item.mimetype.split('/').first) {
      case 'image':
        return _AttachmentItemImage(
          parentId: widget.parentId,
          item: widget.item,
          badge: widget.badge,
          fit: widget.fit,
          showBadge: widget.showBadge,
          showHideButton: widget.showHideButton,
          onHide: widget.onHide,
        );
      case 'video':
        return _AttachmentItemVideo(
          item: widget.item,
          autoload: widget.autoload,
        );
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
                      ServiceFinder.buildUrl(
                        'files',
                        '/attachments/${widget.item.rid}',
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
    }
  }
}

class _AttachmentItemImage extends StatelessWidget {
  final String parentId;
  final Attachment item;
  final bool showBadge;
  final bool showHideButton;
  final BoxFit fit;
  final String? badge;
  final Function? onHide;

  const _AttachmentItemImage({
    required this.parentId,
    required this.item,
    required this.showBadge,
    required this.showHideButton,
    required this.fit,
    this.badge,
    this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Key('a${item.uuid}p$parentId'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (PlatformInfo.canCacheImage)
            CachedNetworkImage(
              fit: fit,
              imageUrl: ServiceFinder.buildUrl(
                'files',
                '/attachments/${item.rid}',
              ),
              progressIndicatorBuilder: (context, url, downloadProgress) {
                return Center(
                  child: CircularProgressIndicator(
                    value: downloadProgress.progress,
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: const Icon(Icons.close, size: 32)
                        .animate(onPlay: (e) => e.repeat(reverse: true))
                        .fade(duration: 500.ms),
                  ),
                );
              },
            )
          else
            Image.network(
              ServiceFinder.buildUrl('files', '/attachments/${item.id}'),
              fit: fit,
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
              errorBuilder: (context, error, stackTrace) {
                return Material(
                  color: Theme.of(context).colorScheme.surface,
                  child: Center(
                    child: const Icon(Icons.close, size: 32)
                        .animate(onPlay: (e) => e.repeat(reverse: true))
                        .fade(duration: 500.ms),
                  ),
                );
              },
            ),
          if (showBadge && badge != null)
            Positioned(
              right: 12,
              bottom: 8,
              child: Material(
                color: Colors.transparent,
                child: Chip(label: Text(badge!)),
              ),
            ),
          if (showHideButton && item.isMature)
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
                    if (onHide != null) onHide!();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AttachmentItemVideo extends StatefulWidget {
  final Attachment item;
  final bool autoload;

  const _AttachmentItemVideo({
    required this.item,
    this.autoload = false,
  });

  @override
  State<_AttachmentItemVideo> createState() => _AttachmentItemVideoState();
}

class _AttachmentItemVideoState extends State<_AttachmentItemVideo> {
  late final _player = Player(
    configuration: const PlayerConfiguration(
      logLevel: MPVLogLevel.error,
    ),
  );

  late final _controller = VideoController(_player);

  bool _showContent = false;

  Future<void> _startLoad() async {
    await _player.open(
      Media(ServiceFinder.buildUrl('files', '/attachments/${widget.item.rid}')),
      play: false,
    );
    setState(() => _showContent = true);
  }

  @override
  void initState() {
    super.initState();
    if (widget.autoload) {
      _startLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.item.metadata?['ratio'] ?? 16 / 9;
    if (!_showContent) {
      return GestureDetector(
        child: AspectRatio(
          aspectRatio: ratio,
          child: CenteredContainer(
            maxWidth: 280,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.not_started,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'attachmentUnload'.tr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'attachmentUnloadCaption'.tr,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        onTap: () {
          _startLoad();
        },
      );
    }

    return Video(
      aspectRatio: ratio,
      controller: _controller,
    );
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
