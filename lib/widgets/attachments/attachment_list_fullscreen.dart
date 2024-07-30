import 'dart:math' as math;

import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/attachments/attachment_item.dart';

class AttachmentListFullScreen extends StatefulWidget {
  final String parentId;
  final Attachment attachment;

  const AttachmentListFullScreen(
      {super.key, required this.parentId, required this.attachment});

  @override
  State<AttachmentListFullScreen> createState() =>
      _AttachmentListFullScreenState();
}

class _AttachmentListFullScreenState extends State<AttachmentListFullScreen> {
  bool _showDetails = true;

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

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
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      key: Key('attachment-dismissible${widget.attachment.id}'),
      direction: DismissiblePageDismissDirection.vertical,
      onDismissed: () => Navigator.pop(context),
      dismissThresholds: const {
        DismissiblePageDismissDirection.vertical: 0.0,
      },
      onDragStart: () {
        setState(() => _showDetails = false);
      },
      onDragEnd: () {
        setState(() => _showDetails = true);
      },
      child: GestureDetector(
        child: Stack(
          fit: StackFit.loose,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: InteractiveViewer(
                boundaryMargin: EdgeInsets.zero,
                minScale: 1,
                maxScale: 16,
                panEnabled: true,
                scaleEnabled: true,
                child: AttachmentItem(
                  parentId: widget.parentId,
                  showHideButton: false,
                  item: widget.attachment,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: Container(
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.surface.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
            )
                .animate(target: _showDetails ? 1 : 0)
                .fadeIn(curve: Curves.fastEaseInToSlowEaseOut),
            Positioned(
              bottom: math.max(MediaQuery.of(context).padding.bottom, 16),
              left: 16,
              right: 16,
              child: IgnorePointer(
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.attachment.account != null)
                        Row(
                          children: [
                            AccountAvatar(
                              content: widget.attachment.account!.avatar,
                              radius: 19,
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'attachmentUploadBy'.tr,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                Text(
                                  widget.attachment.account!.nick,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        widget.attachment.alt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Wrap(
                        spacing: 6,
                        children: [
                          if (widget.attachment.metadata?['width'] != null &&
                              widget.attachment.metadata?['height'] != null)
                            Text(
                              '${widget.attachment.metadata?['width']}x${widget.attachment.metadata?['height']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _unFocusColor,
                              ),
                            ),
                          if (widget.attachment.metadata?['ratio'] != null)
                            Text(
                              '${(widget.attachment.metadata?['ratio'] as double).toPrecision(2)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: _unFocusColor,
                              ),
                            ),
                          Text(
                            _formatBytes(widget.attachment.size),
                            style: TextStyle(
                              fontSize: 12,
                              color: _unFocusColor,
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
                .animate(target: _showDetails ? 1 : 0)
                .fadeIn(curve: Curves.fastEaseInToSlowEaseOut),
          ],
        ),
        onTap: () {
          setState(() => _showDetails = !_showDetails);
        },
      ),
    );
  }
}
