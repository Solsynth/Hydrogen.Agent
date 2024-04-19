import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/router.dart';

class ChannelAction extends StatelessWidget {
  final Channel channel;
  final Function onUpdate;

  ChannelAction({super.key, required this.channel, required this.onUpdate});

  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        MenuAnchor(
          menuChildren: [
            MenuItemButton(
              child: Row(
                children: [
                  const Icon(Icons.settings),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context)!.settings),
                ],
              ),
              onPressed: () {
                router.pushNamed('chat.channel.editor', extra: channel).then((did) {
                  if(did == true) onUpdate();
                });
              },
            ),
          ],
          builder: (BuildContext context, MenuController controller, Widget? child) {
            return IconButton(
              onPressed: () {
                if (controller.isOpen) {
                  controller.close();
                } else {
                  controller.open();
                }
              },
              focusNode: _focusNode,
              style: TextButton.styleFrom(shape: const CircleBorder()),
              icon: const Icon(Icons.more_horiz),
            );
          },
        ),
      ],
    );
  }
}
