import 'package:flutter/material.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/services.dart';

class AttachmentItem extends StatelessWidget {
  final Attachment item;

  const AttachmentItem({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Key('a${item.uuid}'),
      child: Image.network(
        '${ServiceFinder.services['paperclip']}/api/attachments/${item.id}',
        fit: BoxFit.cover,
      ),
    );
  }
}