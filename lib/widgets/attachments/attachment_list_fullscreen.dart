import 'package:flutter/material.dart';
import 'package:solian/models/attachment.dart';
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
              parentId: widget.parentId,
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
