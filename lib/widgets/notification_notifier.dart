import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/notify.dart';
import 'package:solian/router.dart';
import 'package:badges/badges.dart' as badge;

class NotificationButton extends StatelessWidget {
  const NotificationButton({super.key});

  @override
  Widget build(BuildContext context) {
    final nty = context.watch<NotifyProvider>();

    return badge.Badge(
      showBadge: nty.unreadAmount > 0,
      position: badge.BadgePosition.custom(top: -2, end: 8),
      badgeContent: Text(
        nty.unreadAmount.toString(),
        style: const TextStyle(color: Colors.white),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          SolianRouter.router.pushNamed('notification');
        },
      ),
    );
  }
}
