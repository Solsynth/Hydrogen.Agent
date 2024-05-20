import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/services.dart';

class AttachmentItem extends StatelessWidget {
  final Attachment item;
  final String? badge;
  final bool show;
  final Function onHide;

  const AttachmentItem({
    super.key,
    required this.item,
    required this.onHide,
    this.badge,
    this.show = true,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Key('a${item.uuid}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            '${ServiceFinder.services['paperclip']}/api/attachments/${item.id}',
            fit: BoxFit.cover,
          ),
          if (show && badge != null)
            Positioned(
              right: 12,
              bottom: 8,
              child: Material(
                color: Colors.transparent,
                child: Chip(label: Text(badge!)),
              ),
            ),
          if (show && item.isMature)
            Positioned(
              top: 8,
              left: 12,
              child: Material(
                color: Colors.transparent,
                child: ActionChip(
                  visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
                  avatar: Icon(Icons.visibility_off, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  label: Text('hide'.tr),
                  onPressed: () => onHide(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
