import 'package:flutter/material.dart';
import 'package:solian/services.dart';

class AccountAvatar extends StatelessWidget {
  final dynamic content;
  final Color? color;
  final double? radius;

  const AccountAvatar(
      {super.key, required this.content, this.color, this.radius});

  @override
  Widget build(BuildContext context) {
    bool direct = false;
    bool isEmpty = content == null;
    if (content is String) {
      direct = content.startsWith('http');
      if (!isEmpty) isEmpty = content.isEmpty;
      if (!isEmpty) isEmpty = content.endsWith('/api/attachments/0');
    }

    return CircleAvatar(
      key: Key('a$content'),
      radius: radius,
      backgroundColor: color,
      backgroundImage: !isEmpty
          ? NetworkImage(
              direct
                  ? content
                  : '${ServiceFinder.services['paperclip']}/api/attachments/$content',
            )
          : null,
      child: isEmpty
          ? Icon(
              Icons.account_circle,
              size: radius != null ? radius! * 1.2 : 24,
            )
          : null,
    );
  }
}
