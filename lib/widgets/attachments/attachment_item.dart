import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/durations.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/auto_cache_image.dart';
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
          AutoCacheImage(
            ServiceFinder.buildUrl(
              'files',
              '/attachments/${item.rid}',
            ),
            fit: fit,
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

  Player? _videoPlayer;
  VideoController? _videoController;

  Future<void> _startLoad() async {
    setState(() => _showContent = true);
    MediaKit.ensureInitialized();
    final url = ServiceFinder.buildUrl(
      'files',
      '/attachments/${widget.item.rid}',
    );
    _videoPlayer = Player();
    _videoController = VideoController(_videoPlayer!);
    _videoPlayer!.open(Media(url), play: !widget.autoload);
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
    const labelShadows = <Shadow>[
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 5.0,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
    ];
    final ratio = widget.item.metadata?['ratio'] ?? 16 / 9;
    if (!_showContent) {
      return GestureDetector(
        child: Stack(
          children: [
            if (widget.item.metadata?['thumbnail'] != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AutoCacheImage(
                  ServiceFinder.buildUrl(
                    'uc',
                    '/attachments/${widget.item.metadata?['thumbnail']}',
                  ),
                  fit: BoxFit.cover,
                ),
              )
            else
              const Center(
                child: Icon(Icons.movie, size: 64),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 45,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.alt,
                            style: const TextStyle(shadows: labelShadows),
                          ),
                          Text(
                            Duration(
                              milliseconds:
                                  (widget.item.metadata?['duration'] ?? 0)
                                          .toInt() *
                                      1000,
                            ).toHumanReadableString(),
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              shadows: labelShadows,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.play_arrow, shadows: labelShadows)
                        .paddingOnly(bottom: 4, right: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          _startLoad();
        },
      );
    } else if (_videoController == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Video(
      controller: _videoController!,
      aspectRatio: ratio,
    );
  }

  @override
  void dispose() {
    _videoPlayer?.dispose();
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
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  Duration _bufferedPosition = Duration.zero;

  Player? _audioPlayer;

  Future<void> _startLoad() async {
    setState(() => _showContent = true);
    MediaKit.ensureInitialized();
    final url = ServiceFinder.buildUrl(
      'files',
      '/attachments/${widget.item.rid}',
    );
    _audioPlayer = Player();
    await _audioPlayer!.open(Media(url), play: !widget.autoload);
    _audioPlayer!.stream.playing.listen((v) => setState(() => _isPlaying = v));
    _audioPlayer!.stream.position.listen((v) => setState(() => _position = v));
    _audioPlayer!.stream.duration.listen((v) => setState(() => _duration = v));
    _audioPlayer!.stream.buffer.listen(
      (v) => setState(() => _bufferedPosition = v),
    );
  }

  String _formatBytes(int bytes, {int decimals = 2}) {
    if (bytes == 0) return '0 Bytes';
    const k = 1024;
    final dm = decimals < 0 ? 0 : decimals;
    final sizes = [
      'Bytes',
      'KiB',
      'MiB',
      'GiB',
      'TiB',
      'PiB',
      'EiB',
      'ZiB',
      'YiB'
    ];
    final i = (math.log(bytes) / math.log(k)).floor().toInt();
    return '${(bytes / math.pow(k, i)).toStringAsFixed(dm)} ${sizes[i]}';
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
    const labelShadows = <Shadow>[
      Shadow(
        offset: Offset(1, 1),
        blurRadius: 5.0,
        color: Color.fromARGB(255, 0, 0, 0),
      ),
    ];
    const ratio = 16 / 9;
    if (!_showContent) {
      return GestureDetector(
        child: Stack(
          children: [
            if (widget.item.metadata?['thumbnail'] != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: AutoCacheImage(
                  ServiceFinder.buildUrl(
                    'uc',
                    '/attachments/${widget.item.metadata?['thumbnail']}',
                  ),
                  fit: BoxFit.cover,
                ),
              )
            else
              const Center(
                child: Icon(Icons.radio, size: 64),
              ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 4,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 45,
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.alt,
                            style: const TextStyle(shadows: labelShadows),
                          ),
                          Text(
                            _formatBytes(widget.item.size),
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              shadows: labelShadows,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.play_arrow, shadows: labelShadows)
                        .paddingOnly(bottom: 4, right: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
        onTap: () {
          _startLoad();
        },
      );
    } else if (_audioPlayer == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Stack(
      children: [
        if (widget.item.metadata?['thumbnail'] != null)
          AspectRatio(
            aspectRatio: 16 / 9,
            child: AutoCacheImage(
              ServiceFinder.buildUrl(
                'uc',
                '/attachments/${widget.item.metadata?['thumbnail']}',
              ),
              fit: BoxFit.cover,
            ),
          ).animate().blur(
                duration: 300.ms,
                end: const Offset(10, 10),
                curve: Curves.easeInOut,
              ),
        AspectRatio(
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
                              secondaryTrackValue: _bufferedPosition
                                  .inMilliseconds
                                  .abs()
                                  .toDouble(),
                              value: _draggingValue?.abs() ??
                                  _position.inMilliseconds.toDouble().abs(),
                              min: 0,
                              max: math
                                  .max(
                                    _bufferedPosition.inMilliseconds.abs(),
                                    math.max(
                                      _position.inMilliseconds.abs(),
                                      _duration.inMilliseconds.abs(),
                                    ),
                                  )
                                  .toDouble(),
                              onChanged: (value) {
                                setState(() => _draggingValue = value);
                              },
                              onChangeEnd: (value) {
                                _audioPlayer!.seek(
                                  Duration(milliseconds: value.toInt()),
                                );
                                setState(() => _draggingValue = null);
                              },
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _position.toHumanReadableString(),
                                style: GoogleFonts.robotoMono(fontSize: 12),
                              ),
                              Text(
                                _duration.toHumanReadableString(),
                                style: GoogleFonts.robotoMono(fontSize: 12),
                              ),
                            ],
                          ).paddingSymmetric(horizontal: 8, vertical: 4),
                        ],
                      ),
                    ),
                    const Gap(16),
                    IconButton.filled(
                      icon: _isPlaying
                          ? const Icon(Icons.pause)
                          : const Icon(Icons.play_arrow),
                      onPressed: () {
                        _audioPlayer!.playOrPause();
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
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
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
