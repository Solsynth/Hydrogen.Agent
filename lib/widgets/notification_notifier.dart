import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/notify.dart';
import 'package:solian/router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/models/notification.dart' as model;
import 'package:badges/badges.dart' as badge;

class NotificationNotifier extends StatefulWidget {
  final Widget child;

  const NotificationNotifier({super.key, required this.child});

  @override
  State<NotificationNotifier> createState() => _NotificationNotifierState();
}

class _NotificationNotifierState extends State<NotificationNotifier> {
  void connect() async {
    final notify = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.connectingServer),
        duration: const Duration(minutes: 1),
      ),
    );

    final auth = context.read<AuthProvider>();
    final nty = context.read<NotifyProvider>();

    if (await auth.isAuthorized()) {
      nty.fetch(auth);
      nty.connect(auth).then((snapshot) {
        snapshot!.stream.listen(
          (event) {
            final result = model.Notification.fromJson(jsonDecode(event));
            nty.onRemoteMessage(result);
          },
          onError: (_, __) => connect(),
          onDone: () => connect(),
        );
      });
    }

    notify.close();
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      connect();
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  @override
  Widget build(BuildContext context) {
    final nty = context.watch<NotifyProvider>();

    return badge.Badge(
      showBadge: nty.notifications.isNotEmpty,
      position: badge.BadgePosition.custom(top: -2, end: 8),
      badgeContent: Text(
        nty.notifications.length.toString(),
        style: const TextStyle(color: Colors.white),
      ),
      child: IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: () {
          router.pushNamed("notification");
        },
      ),
    );
  }
}
