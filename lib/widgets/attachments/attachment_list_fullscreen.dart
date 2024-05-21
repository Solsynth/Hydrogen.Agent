import 'package:flutter/material.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/providers/content/attachment_item.dart';

class AttachmentListFullscreen extends StatefulWidget {
  final Attachment attachment;

  const AttachmentListFullscreen({super.key, required this.attachment});

  @override
  State<AttachmentListFullscreen> createState() =>
      _AttachmentListFullscreenState();
}

class _AttachmentListFullscreenState extends State<AttachmentListFullscreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: GestureDetector(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(128),
            minScale: 0.1,
            maxScale: 16,
            panEnabled: true,
            scaleEnabled: true,
            child: AttachmentItem(
              showHideButton: false,
              item: widget.attachment,
              fit: BoxFit.contain,
            ),
          ),
        ),
        onTap: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
