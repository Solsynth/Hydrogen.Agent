import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:get/get.dart';
import 'package:solian/models/event.dart';
import 'package:solian/widgets/attachments/attachment_list.dart';
import 'package:timeago/timeago.dart' show format;
import 'package:url_launcher/url_launcher_string.dart';

class ChatEventMessageActionLog extends StatelessWidget {
  final Widget icon;
  final String text;
  final bool isMerged;
  final bool isHasMerged;

  const ChatEventMessageActionLog({
    super.key,
    required this.icon,
    required this.text,
    this.isMerged = false,
    this.isHasMerged = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.75,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 4),
          Text(text),
        ],
      ).paddingOnly(
        left: isMerged ? 64 : 12,
        top: 2,
        bottom: isHasMerged ? 2 : 0,
      ),
    );
  }
}
