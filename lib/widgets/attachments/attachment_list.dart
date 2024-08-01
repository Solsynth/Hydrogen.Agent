import 'dart:math' show min;
import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/widgets/attachments/attachment_item.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/widgets/attachments/attachment_fullscreen.dart';

class AttachmentList extends StatefulWidget {
  final String parentId;
  final List<int> attachmentsId;
  final bool isGrid;
  final bool isForceGrid;
  final double flatMaxHeight;

  final double? width;
  final double? viewport;

  const AttachmentList({
    super.key,
    required this.parentId,
    required this.attachmentsId,
    this.isGrid = false,
    this.isForceGrid = false,
    this.flatMaxHeight = 720,
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
    final AttachmentProvider provider = Get.find();

    if (widget.attachmentsId.isEmpty) {
      return;
    } else {
      _attachmentsMeta = List.filled(widget.attachmentsId.length, null);
    }

    int progress = 0;
    for (var idx = 0; idx < widget.attachmentsId.length; idx++) {
      provider.getMetadata(widget.attachmentsId[idx]).then((resp) {
        progress++;
        if (resp != null) {
          _attachmentsMeta[idx] = resp;
        }
        if (progress == widget.attachmentsId.length) {
          calculateAspectRatio();

          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      });
    }
  }

  void calculateAspectRatio() {
    bool isConsistent = true;
    double? consistentValue;
    int portrait = 0, square = 0, landscape = 0;
    for (var entry in _attachmentsMeta) {
      if (entry!.metadata?['ratio'] != null) {
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

  Widget _buildEntry(Attachment? element, int idx) {
    return AttachmentListEntry(
      item: element,
      parentId: widget.parentId,
      width: widget.width,
      badgeContent: '${idx + 1}/${_attachmentsMeta.length}',
      showBadge: _attachmentsMeta.length > 1 && !widget.isGrid,
      showBorder: widget.attachmentsId.length > 1,
      showMature: _showMature,
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

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentsId.isEmpty) {
      return const SizedBox();
    }

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        child: const LinearProgressIndicator(),
      );
    }

    final isNotPureImage = _attachmentsMeta
        .any((x) => x?.mimetype.split('/').firstOrNull != 'image');
    if (widget.isGrid && (widget.isForceGrid || !isNotPureImage)) {
      const radius = BorderRadius.all(Radius.circular(8));
      return GridView.builder(
        padding: EdgeInsets.zero,
        primary: false,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: min(3, widget.attachmentsId.length),
          mainAxisSpacing: 8.0,
          crossAxisSpacing: 8.0,
        ),
        itemCount: widget.attachmentsId.length,
        itemBuilder: (context, idx) {
          final element = _attachmentsMeta[idx];
          return Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: Theme.of(context).dividerColor, width: 1),
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
  final bool showBorder;
  final bool showBadge;
  final bool showMature;
  final bool isDense;
  final Function(bool) onReveal;

  const AttachmentListEntry({
    super.key,
    required this.parentId,
    required this.onReveal,
    this.item,
    this.badgeContent,
    this.width,
    this.showBorder = false,
    this.showBadge = false,
    this.showMature = false,
    this.isDense = false,
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
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.visibility_off,
                        color: Colors.white,
                        size: 32,
                      ),
                      if (!isDense) const SizedBox(height: 8),
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
