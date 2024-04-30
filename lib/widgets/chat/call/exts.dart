import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension SolianCallExt on BuildContext {
  Future<bool?> showPlayAudioManuallyDialog() => showDialog<bool>(
        context: this,
        builder: (ctx) => AlertDialog(
          title: const Text('Play Audio'),
          content: const Text(
            'You need to manually activate audio PlayBack for iOS Safari!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Ignore'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Play Audio'),
            ),
          ],
        ),
      );

  Future<bool?> showDisconnectDialog() => showDialog<bool>(
        context: this,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(this)!.chatCallDisconnect),
          content: Text(AppLocalizations.of(this)!.chatCallDisconnectConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppLocalizations.of(this)!.confirmCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(AppLocalizations.of(this)!.confirmOkay),
            ),
          ],
        ),
      );

  Future<bool?> showReconnectDialog() => showDialog<bool>(
        context: this,
        builder: (ctx) => AlertDialog(
          title: const Text('Reconnect'),
          content: const Text('This will force a reconnection'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Reconnect'),
            ),
          ],
        ),
      );

  Future<void> showReconnectSuccessDialog() => showDialog<void>(
        context: this,
        builder: (ctx) => AlertDialog(
          title: const Text('Reconnect'),
          content: const Text('Reconnection was successful.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
}
