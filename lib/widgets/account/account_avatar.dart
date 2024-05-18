import 'package:flutter/material.dart';
import 'package:solian/services.dart';

class AccountAvatar extends StatelessWidget {
  final String content;
  final Color? color;
  final double? radius;

  const AccountAvatar({super.key, required this.content, this.color, this.radius});

  @override
  Widget build(BuildContext context) {
    final direct = content.startsWith('http');

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      backgroundImage: NetworkImage(direct ? content : '${ServiceFinder.services['paperclip']}/api/attachments/$content'),
    );
  }
}