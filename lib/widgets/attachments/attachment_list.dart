import 'dart:math' as math;
import 'dart:ui';

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/widgets/attachments/attachment_item.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/widgets/attachments/attachment_fullscreen.dart';
import 'package:solian/widgets/sized_container.dart';

class AttachmentList extends StatefulWidget {
  final String parentId;
  final List<String>? attachmentIds;
  final List<Attachment>? attachments;
  final bool isGrid;
  final bool isColumn;
  final bool isFullWidth;
  final bool autoload;
  final double columnMaxWidth;

  final EdgeInsets? padding;
  final double? width;
  final double? viewport;

  const AttachmentList({
    super.key,
    required this.parentId,
    this.attachmentIds,
    this.attachments,
    this.isGrid = false,
    this.isColumn = false,
    this.isFullWidth = false,
    this.autoload = false,
    this.columnMaxWidth = 480,
    this.padding,
    this.width,
    this.viewport,
  });

  @override
  State<AttachmentList> createState() => _AttachmentListState();
}

class _AttachmentListState extends State<AttachmentList> {
  bool _isLoading = true;
  bool _showMature = false;

  double _aspectRatio = 1;

  List<Attachment?> _attachments = List.empty();

  void _getMetadataList() {
    final AttachmentProvider attach = Get.find();

    if (widget.attachmentIds?.isEmpty ?? false) {
      return;
    } else {
      _attachments = List.filled(widget.attachmentIds!.length, null);
    }

    attach.listMetadata(widget.attachmentIds!).then((result) {
      if (mounted) {
        setState(() {
          _attachments = result;
          _isLoading = false;
        });
      }
      _calculateAspectRatio();
    });
  }

  void _calculateAspectRatio() {
    bool isConsistent = true;
    double? consistentValue;
    int portrait = 0, square = 0, landscape = 0;
    for (var entry in _attachments) {
      if (entry == null) continue;
      if (entry.metadata?['ratio'] != null) {
        if (entry.metadata?['ratio'] is int) {
          consistentValue ??= entry.metadata?['ratio'].toDouble();
        } else {
          consistentValue ??= entry.metadata?['ratio'];
        }
        if (isConsistent && entry.metadata?['ratio'] != consistentValue) {
          isConsistent = false;
        }
        if (entry.metadata!['ratio'] > 1) {
          landscape++;
        } else if (entry.metadata!['ratio'] == 1) {
          square++;
        } else {
          portrait++;
        }
      } else if (entry.mimetype.split('/').firstOrNull == 'audio') {
        landscape++;
      }
    }
    if (isConsistent && consistentValue != null) {
      _aspectRatio = consistentValue;
    } else {
      if (portrait > square && portrait > landscape) {
        _aspectRatio = 9 / 16;
      }
      if (landscape > square && landscape > portrait) {
        _aspectRatio = 16 / 9;
      } else {
        _aspectRatio = 1;
      }
    }
  }

  Widget _buildEntry(Attachment? element, int idx, {double? width}) {
    return AttachmentListEntry(
      item: element,
      parentId: widget.parentId,
      width: width ?? widget.width,
      badgeContent: '${idx + 1}/${_attachments.length}',
      showBadge: _attachments.length > 1 && !widget.isGrid && !widget.isColumn,
      showBorder: _attachments.length > 1,
      showMature: _showMature,
      autoload: widget.autoload,
      onReveal: (value) {
        setState(() => _showMature = value);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    assert(widget.attachmentIds != null || widget.attachments != null);
    if (widget.attachments == null) {
      final AttachmentProvider attach = Get.find();
      final cachedResult = attach.listMetadataFromCache(widget.attachmentIds!);
      if (cachedResult.every((x) => x != null)) {
        setState(() {
          _attachments = cachedResult;
          _isLoading = false;
        });
        _calculateAspectRatio();
      } else {
        _getMetadataList();
      }
    } else {
      setState(() {
        _attachments = widget.attachments!;
        _isLoading = false;
      });
      _calculateAspectRatio();
    }
  }

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentIds?.isEmpty ?? widget.attachments!.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_isLoading) {
      return Row(
        children: [
          Icon(
            Icons.file_copy,
            size: 12,
            color: _unFocusColor,
          ).paddingOnly(right: 5),
          Text(
            'attachmentHint'.trParams({'count': _attachments.toString()}),
            style: TextStyle(color: _unFocusColor, fontSize: 12),
          )
        ],
      )
          .paddingSymmetric(horizontal: 8)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 1250.ms);
    }

    const radius = BorderRadius.all(Radius.circular(8));

    if (widget.isFullWidth && _attachments.length == 1) {
      final element = _attachments.first;
      double ratio = math.max(
        element!.metadata?['ratio']?.toDouble() ?? 16 / 9,
        0.5,
      );
      return Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
          maxHeight: 640,
        ),
        child: AspectRatio(
          aspectRatio: ratio,
          child: Container(
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: _buildEntry(element, 0),
          ),
        ),
      );
    }

    final isNotPureImage = _attachments.any(
      (x) => x?.mimetype.split('/').firstOrNull != 'image',
    );
    if (widget.isGrid && !isNotPureImage) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: math.min(3, _attachments.length),
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        itemCount: _attachments.length,
        itemBuilder: (context, idx) {
          final element = _attachments[idx];
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              border: Border.all(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
              borderRadius: radius,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: _buildEntry(element, idx),
            ),
          );
        },
      );
    }

    if (widget.isColumn) {
      var idx = 0;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _attachments.map((x) {
          final element = _attachments[idx];
          idx++;
          if (element == null) return const SizedBox.shrink();
          double ratio = math.max(
            element.metadata?['ratio']?.toDouble() ?? 16 / 9,
            0.5,
          );
          return Container(
            constraints: BoxConstraints(
              maxWidth: widget.columnMaxWidth,
              maxHeight: 640,
            ),
            child: AspectRatio(
              aspectRatio: ratio,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  borderRadius: radius,
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: _buildEntry(element, idx),
                ),
              ),
            ),
          );
        }).toList(),
      );
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: 320,
      ),
      child: ListView.separated(
        padding: widget.padding,
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        itemCount: _attachments.length,
        itemBuilder: (context, idx) {
          final element = _attachments[idx];
          if (element == null) const SizedBox.shrink();
          double ratio = math.max(
            element!.metadata?['ratio']?.toDouble() ?? 16 / 9,
            0.5,
          );
          return Container(
            constraints: BoxConstraints(
              maxWidth: math.min(
                widget.columnMaxWidth,
                MediaQuery.of(context).size.width -
                    (widget.padding?.horizontal ?? 0),
              ),
            ),
            child: AspectRatio(
              aspectRatio: ratio,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                  borderRadius: radius,
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: _buildEntry(element, idx),
                ),
              ),
            ),
          );
        },
        separatorBuilder: (context, _) => const Gap(8),
      ),
    );
  }
}

class AttachmentListEntry extends StatelessWidget {
  final String parentId;
  final Attachment? item;
  final String? badgeContent;
  final double? width;
  final double? height;
  final bool showBorder;
  final bool showBadge;
  final bool showMature;
  final bool isDense;
  final bool autoload;
  final Function(bool) onReveal;

  const AttachmentListEntry({
    super.key,
    required this.parentId,
    required this.onReveal,
    this.item,
    this.badgeContent,
    this.width,
    this.height,
    this.showBorder = false,
    this.showBadge = false,
    this.showMature = false,
    this.isDense = false,
    this.autoload = false,
  });

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return Center(
        child: Icon(
          Icons.close,
          size: 32,
          color: Theme.of(context).colorScheme.onSurface,
        )
            .animate(onPlay: (e) => e.repeat(reverse: true))
            .fade(duration: 500.ms),
      );
    }

    return GestureDetector(
      child: Container(
        width: width ?? MediaQuery.of(context).size.width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: showBorder
              ? Border.symmetric(
                  vertical: BorderSide(
                    width: 0.3,
                    color: Theme.of(context).dividerColor,
                  ),
                )
              : null,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AttachmentItem(
              parentId: parentId,
              key: Key('a${item!.uuid}'),
              item: item!,
              badge: showBadge ? badgeContent : null,
              showHideButton: !item!.isMature || showMature,
              autoload: autoload,
              isDense: isDense,
              onHide: () {
                onReveal(false);
              },
            ),
            if (item!.isMature && !showMature)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            if (item!.isMature && !showMature)
              CenteredContainer(
                maxWidth: 280,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.visibility_off,
                      color: Colors.white,
                      size: 32,
                    ),
                    if (!isDense) const Gap(8),
                    if (!isDense)
                      Text(
                        'matureContent'.tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    if (!isDense)
                      Text(
                        'matureContentCaption'.tr,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
      onTap: () {
        if (!showMature && item!.isMature) {
          onReveal(true);
        } else if (['image'].contains(item!.mimetype.split('/').first)) {
          context.pushTransparentRoute(
            AttachmentFullScreen(
              parentId: parentId,
              item: item!,
            ),
            rootNavigator: true,
          );
        }
      },
    );
  }
}

class AttachmentSelfContainedEntry extends StatefulWidget {
  final String rid;
  final String parentId;
  final bool isDense;

  const AttachmentSelfContainedEntry({
    super.key,
    required this.rid,
    required this.parentId,
    this.isDense = false,
  });

  @override
  State<AttachmentSelfContainedEntry> createState() =>
      _AttachmentSelfContainedEntryState();
}

class _AttachmentSelfContainedEntryState
    extends State<AttachmentSelfContainedEntry> {
  bool _showMature = false;

  @override
  Widget build(BuildContext context) {
    final AttachmentProvider attachments = Get.find();

    return FutureBuilder(
      future: attachments.getMetadata(widget.rid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        return AttachmentListEntry(
          item: snapshot.data,
          isDense: widget.isDense,
          parentId: widget.parentId,
          showMature: _showMature,
          onReveal: (value) {
            setState(() => _showMature = value);
          },
        );
      },
    );
  }
}
