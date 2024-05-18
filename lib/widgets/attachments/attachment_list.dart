import 'dart:ui';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/content/attachment_item.dart';
import 'package:solian/providers/content/attachment_list.dart';

class AttachmentList extends StatefulWidget {
  final List<String> attachmentsId;

  const AttachmentList({super.key, required this.attachmentsId});

  @override
  State<AttachmentList> createState() => _AttachmentListState();
}

class _AttachmentListState extends State<AttachmentList> {
  bool _isLoading = true;
  bool _showMature = false;

  double _aspectRatio = 1;

  List<Attachment?> _attachmentsMeta = List.empty();

  void getMetadataList() {
    final AttachmentListProvider provider = Get.find();

    if (widget.attachmentsId.isEmpty) {
      return;
    } else {
      _attachmentsMeta = List.filled(widget.attachmentsId.length, null);
    }

    int progress = 0;
    for (var idx = 0; idx < widget.attachmentsId.length; idx++) {
      provider.getMetadata(widget.attachmentsId[idx]).then((resp) {
        progress++;
        _attachmentsMeta[idx] = Attachment.fromJson(resp.body);
        if (progress == widget.attachmentsId.length) {
          setState(() {
            calculateAspectRatio();
            _isLoading = false;
          });
        }
      });
    }
  }

  void calculateAspectRatio() {
    int portrait = 0, square = 0, landscape = 0;
    for (var entry in _attachmentsMeta) {
      if (entry!.metadata?['ratio'] != null) {
        if (entry.metadata!['ratio'] > 1) {
          landscape++;
        } else if (entry.metadata!['ratio'] == 1) {
          square++;
        } else {
          portrait++;
        }
      }
    }
    if (portrait > square && portrait > landscape) {
      _aspectRatio = 9 / 16;
    }
    if (landscape > square && landscape > portrait) {
      _aspectRatio = 16 / 9;
    } else {
      _aspectRatio = 1;
    }
  }

  @override
  void initState() {
    Get.lazyPut(() => AttachmentListProvider());
    super.initState();

    getMetadataList();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.attachmentsId.isEmpty) {
      return Container();
    }

    if (_isLoading) {
      return AspectRatio(
        aspectRatio: _aspectRatio,
        child: Container(
          decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant),
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return CarouselSlider.builder(
      options: CarouselOptions(
        aspectRatio: _aspectRatio,
        viewportFraction: 1,
        enableInfiniteScroll: false,
      ),
      itemCount: _attachmentsMeta.length,
      itemBuilder: (context, idx, _) {
        final element = _attachmentsMeta[idx];
        return GestureDetector(
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AttachmentItem(key: Key('a${element!.uuid}'), item: element),
                if (element.isMature && !_showMature)
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                          const Icon(Icons.visibility_off, color: Colors.white, size: 32),
                          const SizedBox(height: 8),
                          Text(
                            'matureContent'.tr,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
            } else {
              // Open detail box
            }
          },
        );
      },
    );
  }
}
