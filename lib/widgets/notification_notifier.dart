import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/keypair.dart';
import 'package:solian/providers/notify.dart';
import 'package:solian/router.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:badges/badges.dart' as badge;

class NotificationButton extends StatefulWidget {
  const NotificationButton({super.key});

  @override
  State<NotificationButton> createState() => _NotificationButtonState();
}

class _NotificationButtonState extends State<NotificationButton> {
  void connect() async {
    final auth = context.read<AuthProvider>();
    final nty = context.read<NotifyProvider>();
    final keypair = context.read<KeypairProvider>();

    if (nty.isOpened) return;

    final notify = ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.connectingServer),
        duration: const Duration(minutes: 1),
      ),
    );

    if (await auth.isAuthorized()) {
      if (auth.client == null) {
        await auth.loadClient();
      }

      nty.fetch(auth);
      keypair.channel = await nty.connect(
        auth,
        onKexRequest: keypair.provideKeypair,
        onKexProvide: keypair.receiveKeypair,
      );
    }

    notify.close();
  }

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () => connect());
  }

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
