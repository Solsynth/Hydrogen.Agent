import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/attachment.dart';
import 'package:solian/services.dart';

class AttachmentItem extends StatelessWidget {
  final String parentId;
  final Attachment item;
  final bool showBadge;
  final bool showHideButton;
  final BoxFit fit;
  final String? badge;
  final Function? onHide;

  const AttachmentItem({
    super.key,
    required this.parentId,
    required this.item,
    this.badge,
    this.fit = BoxFit.cover,
    this.showBadge = true,
    this.showHideButton = true,
    this.onHide,
  });

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: Key('a${item.uuid}p$parentId'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            '${ServiceFinder.services['paperclip']}/api/attachments/${item.id}',
            fit: fit,
          ),
          if (showBadge && badge != null)
            Positioned(
              right: 12,
              bottom: 8,
              child: Material(
                color: Colors.transparent,
                child: Chip(label: Text(badge!)),
              ),
            ),
          if (showHideButton && item.isMature)
            Positioned(
              top: 8,
              left: 12,
              child: Material(
                color: Colors.transparent,
                child: ActionChip(
                  visualDensity:
                      const VisualDensity(vertical: -4, horizontal: -4),
                  avatar: Icon(Icons.visibility_off,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  label: Text('hide'.tr),
                  onPressed: () {
                    if (onHide != null) onHide!();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
