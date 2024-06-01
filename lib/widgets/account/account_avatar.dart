import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:solian/platform.dart';
import 'package:solian/services.dart';

class AccountAvatar extends StatelessWidget {
  final dynamic content;
  final Color? bgColor;
  final Color? feColor;
  final double? radius;

  const AccountAvatar({
    super.key,
    required this.content,
    this.bgColor,
    this.feColor,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    bool direct = false;
    bool isEmpty = content == null;
    if (content is String) {
      direct = content.startsWith('http');
      if (!isEmpty) isEmpty = content.isEmpty;
      if (!isEmpty) isEmpty = content.endsWith('/api/attachments/0');
    }

    final url = direct
        ? content
        : '${ServiceFinder.services['paperclip']}/api/attachments/$content';

    return CircleAvatar(
      key: Key('a$content'),
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: !isEmpty
          ? (PlatformInfo.canCacheImage
              ? CachedNetworkImageProvider(url)
              : NetworkImage(url)) as ImageProvider<Object>?
          : null,
      child: isEmpty
          ? Icon(
              Icons.account_circle,
              size: radius != null ? radius! * 1.2 : 24,
              color: feColor,
            )
          : null,
    );
  }
}
