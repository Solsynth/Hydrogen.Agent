import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/widgets/attachments/attachment_item.dart';
import 'package:solian/providers/content/attachment.dart';
import 'package:solian/widgets/attachments/attachment_list_fullscreen.dart';

class AttachmentList extends StatefulWidget {
  final String parentId;
  final List<int> attachmentsId;
  final bool divided;

  final double? width;
  final double? viewport;

  const AttachmentList({
    super.key,
    required this.parentId,
    required this.attachmentsId,
    this.divided = false,
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

  void getMetadataList() {
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
        if (resp.body != null) {
          _attachmentsMeta[idx] = Attachment.fromJson(resp.body);
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

  Widget buildEntry(Attachment element, int idx) {
    return GestureDetector(
      child: Container(
        width: widget.width ?? MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AttachmentItem(
              parentId: widget.parentId,
              key: Key('a${element.uuid}'),
              item: element,
              badge: _attachmentsMeta.length > 1
                  ? '${idx + 1}/${_attachmentsMeta.length}'
                  : null,
              showHideButton: !element.isMature || _showMature,
              onHide: () {
                setState(() => _showMature = false);
              },
            ),
            if (element.isMature && !_showMature)
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
            if (element.isMature && !_showMature)
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.visibility_off,
                          color: Colors.white, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'matureContent'.tr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
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
        if (!_showMature && _attachmentsMeta.any((e) => e!.isMature)) {
          setState(() => _showMature = true);
        } else if (['image'].contains(element.mimetype.split('/').first)) {
          Navigator.of(context, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => AttachmentListFullScreen(
                parentId: widget.parentId,
                attachment: element,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getMetadataList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentsId.isEmpty) {
      return const SizedBox();
    }

    if (_isLoading) {
      return Container(
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh),
        child: const LinearProgressIndicator(),
      );
    }

    return CarouselSlider.builder(
      options: CarouselOptions(
        aspectRatio: _aspectRatio,
        viewportFraction: widget.viewport ?? (widget.divided ? 0.9 : 1),
        enableInfiniteScroll: false,
      ),
      itemCount: _attachmentsMeta.length,
      itemBuilder: (context, idx, _) {
        final element = _attachmentsMeta[idx];

        if (element == null) {
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'attachmentLoadFailed'.tr,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'attachmentLoadFailedCaption'.tr,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (widget.divided) {
          const radius = BorderRadius.all(Radius.circular(16));
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor, width: 1),
              borderRadius: radius,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: buildEntry(element, idx),
            ),
          ).paddingSymmetric(horizontal: widget.divided ? 4 : 0);
        } else {
          return buildEntry(element, idx);
        }
      },
    );
  }
}
