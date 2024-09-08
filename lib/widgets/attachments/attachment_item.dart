import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/durations.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:video_player/video_player.dart';

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
      case 'audio':
        return _AttachmentItemAudio(
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
                const Gap(6),
                Text(
                  widget.item.mimetype,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(2),
                Text(
                  widget.item.alt,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const Gap(12),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.close, size: 32)
                          .animate(onPlay: (e) => e.repeat(reverse: true))
                          .fade(duration: 500.ms),
                      Text(error.toString()),
                    ],
                  ),
                );
              },
            )
          else
            Image.network(
              ServiceFinder.buildUrl('files', '/attachments/${item.rid}'),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.close, size: 32)
                          .animate(onPlay: (e) => e.repeat(reverse: true))
                          .fade(duration: 500.ms),
                      Text(error.toString()),
                    ],
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
  bool _showContent = false;

  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  Future<void> _startLoad() async {
    setState(() => _showContent = true);
    final url =
        ServiceFinder.buildUrl('files', '/attachments/${widget.item.rid}');
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      aspectRatio: widget.item.metadata?['ratio'],
    );
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
                const Gap(8),
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
    } else if (_chewieController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Chewie(controller: _chewieController!);
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}

class _AttachmentItemAudio extends StatefulWidget {
  final Attachment item;
  final bool autoload;

  const _AttachmentItemAudio({
    required this.item,
    this.autoload = false,
  });

  @override
  State<_AttachmentItemAudio> createState() => _AttachmentItemAudioState();
}

class _AttachmentItemAudioState extends State<_AttachmentItemAudio> {
  bool _showContent = false;

  double? _draggingValue;

  AudioPlayer? _audioController;

  Future<void> _startLoad() async {
    setState(() => _showContent = true);
    final url =
        ServiceFinder.buildUrl('files', '/attachments/${widget.item.rid}');
    _audioController = AudioPlayer();
    // Platform that can cache image also capable to cache audio
    // https://pub.dev/packages/just_audio#experimental-features
    if (PlatformInfo.canCacheImage) {
      final source = LockCachingAudioSource(Uri.parse(url));
      await _audioController!.setAudioSource(source);
    } else {
      await _audioController!.setUrl(url);
    }
    _audioController!.playingStream.listen((_) => setState(() {}));
    _audioController!.positionStream.listen((_) => setState(() {}));
    _audioController!.durationStream.listen((_) => setState(() {}));
    _audioController!.bufferedPositionStream.listen((_) => setState(() {}));
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
    const ratio = 16 / 9;
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
                const Gap(8),
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
    } else if (_audioController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return AspectRatio(
      aspectRatio: ratio,
      child: CenteredContainer(
        maxWidth: 320,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.audio_file, size: 32),
            const Gap(8),
            Text(
              widget.item.alt,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const Gap(12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          trackShape: _PlayerProgressTrackShape(),
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 8,
                          ),
                          overlayShape: SliderComponentShape.noOverlay,
                        ),
                        child: Slider(
                          secondaryTrackValue: _audioController!
                              .bufferedPosition.inMilliseconds
                              .abs()
                              .toDouble(),
                          value: _draggingValue?.abs() ??
                              _audioController!.position.inMilliseconds
                                  .toDouble()
                                  .abs(),
                          min: 0,
                          max: max(
                            _audioController!.bufferedPosition.inMilliseconds
                                .abs(),
                            max(
                              _audioController!.position.inMilliseconds.abs(),
                              _audioController!.duration?.inMilliseconds
                                      .abs() ??
                                  1,
                            ),
                          ).toDouble(),
                          onChanged: (value) {
                            setState(() => _draggingValue = value);
                          },
                          onChangeEnd: (value) {
                            _audioController!
                                .seek(Duration(milliseconds: value.toInt()));
                            setState(() => _draggingValue = null);
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _audioController!.position.toHumanReadableString(),
                            style: GoogleFonts.robotoMono(fontSize: 12),
                          ),
                          Text(
                            _audioController!.duration
                                    ?.toHumanReadableString() ??
                                '00:00',
                            style: GoogleFonts.robotoMono(fontSize: 12),
                          ),
                        ],
                      ).paddingSymmetric(horizontal: 8, vertical: 4),
                    ],
                  ),
                ),
                const Gap(16),
                IconButton.filled(
                  icon: _audioController!.playing
                      ? const Icon(Icons.pause)
                      : const Icon(Icons.play_arrow),
                  onPressed: () {
                    if (_audioController!.playing) {
                      _audioController!.pause();
                    } else {
                      _audioController!.play();
                    }
                  },
                  visualDensity: const VisualDensity(
                    horizontal: -4,
                    vertical: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioController?.dispose();
    super.dispose();
  }
}

class _PlayerProgressTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight!) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
