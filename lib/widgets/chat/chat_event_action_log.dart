import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';

class ChatEventMessageActionLog extends StatelessWidget {
  final Widget icon;
  final String text;
  final bool isQuote;
  final bool isMerged;
  final bool isHasMerged;

  const ChatEventMessageActionLog({
    super.key,
    required this.icon,
    required this.text,
    this.isMerged = false,
    this.isHasMerged = false,
    this.isQuote = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.75,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          const Gap(4),
          Text(text),
        ],
      ).paddingOnly(
        left: isQuote ? 0 : (isMerged ? 64 : 12),
        top: 2,
        bottom: isQuote
            ? 0
            : isHasMerged
                ? 2
                : 0,
      ),
    );
  }
}
