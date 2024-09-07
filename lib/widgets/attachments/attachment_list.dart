import 'dart:math' as math;
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
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
  final List<String> attachmentsId;
  final bool isGrid;
  final bool isColumn;
  final bool isForceGrid;
  final bool autoload;
  final double flatMaxHeight;
  final double columnMaxWidth;

  final double? width;
  final double? viewport;

  const AttachmentList({
    super.key,
    required this.parentId,
    required this.attachmentsId,
    this.isGrid = false,
    this.isColumn = false,
    this.isForceGrid = false,
    this.autoload = false,
    this.flatMaxHeight = 720,
    this.columnMaxWidth = 480,
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

  List<Attachment?> _attachmentsMeta = List.empty();

  void _getMetadataList() {
    final AttachmentProvider attach = Get.find();

    if (widget.attachmentsId.isEmpty) {
      return;
    } else {
      _attachmentsMeta = List.filled(widget.attachmentsId.length, null);
    }

    attach.listMetadata(widget.attachmentsId).then((result) {
      if (mounted) {
        setState(() {
          _attachmentsMeta = result;
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
    for (var entry in _attachmentsMeta) {
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
      badgeContent: '${idx + 1}/${_attachmentsMeta.length}',
      showBadge:
          _attachmentsMeta.length > 1 && !widget.isGrid && !widget.isColumn,
      showBorder: widget.attachmentsId.length > 1,
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
    _getMetadataList();
  }

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentsId.isEmpty) {
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
            'attachmentHint'.trParams(
              {'count': widget.attachmentsId.length.toString()},
            ),
            style: TextStyle(color: _unFocusColor, fontSize: 12),
          )
        ],
      )
          .paddingSymmetric(horizontal: 8)
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fadeIn(duration: 1250.ms);
    }

    if (widget.isColumn) {
      var idx = 0;
      const radius = BorderRadius.all(Radius.circular(8));
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.attachmentsId.map((x) {
          final element = _attachmentsMeta[idx];
          idx++;
          if (element == null) return const SizedBox.shrink();
          double ratio = element.metadata?['ratio']?.toDouble() ?? 16 / 9;
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
            ),
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

    final isNotPureImage = _attachmentsMeta.any(
      (x) => x?.mimetype.split('/').firstOrNull != 'image',
    );
    if (widget.isGrid && (widget.isForceGrid || !isNotPureImage)) {
      const radius = BorderRadius.all(Radius.circular(8));
      return GridView.builder(
        padding: EdgeInsets.zero,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: math.min(3, widget.attachmentsId.length),
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        itemCount: widget.attachmentsId.length,
        itemBuilder: (context, idx) {
          final element = _attachmentsMeta[idx];
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
      ).paddingSymmetric(horizontal: 24);
    }

    return Container(
      width: MediaQuery.of(context).size.width,
      constraints: BoxConstraints(
        maxHeight: widget.flatMaxHeight,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        border: Border.symmetric(
          horizontal: BorderSide(
            width: 0.3,
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: CarouselSlider.builder(
        options: CarouselOptions(
          aspectRatio: _aspectRatio,
          viewportFraction:
              widget.viewport ?? (widget.attachmentsId.length > 1 ? 0.95 : 1),
          enableInfiniteScroll: false,
        ),
        itemCount: _attachmentsMeta.length,
        itemBuilder: (context, idx, _) {
          final element = _attachmentsMeta[idx];
          return _buildEntry(element, idx);
        },
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
