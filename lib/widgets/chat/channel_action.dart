import 'package:flutter/material.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/router.dart';

class ChannelAction extends StatelessWidget {
  final Channel channel;
  final Function onUpdate;

  ChannelAction({super.key, required this.channel, required this.onUpdate});

  final FocusNode _focusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        router.pushNamed(
          'chat.channel.manage',
          extra: channel,
          pathParameters: {'channel': channel.alias},
        );
      },
      focusNode: _focusNode,
      style: TextButton.styleFrom(shape: const CircleBorder()),
      icon: const Icon(Icons.more_horiz),
    );
  }
}
