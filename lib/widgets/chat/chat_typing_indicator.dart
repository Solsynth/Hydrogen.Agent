import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';

class ChatTypingIndicator extends StatefulWidget {
  final List<ChannelMember> users;

  const ChatTypingIndicator({super.key, required this.users});

  @override
  State<ChatTypingIndicator> createState() => _ChatTypingIndicatorState();
}

class _ChatTypingIndicatorState extends State<ChatTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 250),
    vsync: this,
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatTypingIndicator oldWidget) {
    if (widget.users.isNotEmpty) {
      _controller.animateTo(1);
    } else {
      _controller.animateTo(0);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _animation,
      axis: Axis.vertical,
      axisAlignment: -1,
      child: Row(
        children: [
          const Icon(Icons.more_horiz),
          const SizedBox(width: 6),
          Text('typingMessage'.trParams({
            'user': widget.users.map((x) => x.account.nick).join(', '),
          })),
        ],
      ).paddingSymmetric(horizontal: 16),
    );
  }
}
