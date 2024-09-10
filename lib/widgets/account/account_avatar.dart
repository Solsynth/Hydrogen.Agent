import 'package:flutter/material.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/auto_cache_image.dart';

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
    }

    final url = direct
        ? content
        : ServiceFinder.buildUrl('files', '/attachments/$content');

    return CircleAvatar(
      key: Key('a$content'),
      radius: radius,
      backgroundColor: bgColor,
      backgroundImage: !isEmpty ? AutoCacheImage.provider(url) : null,
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

class AccountProfileImage extends StatelessWidget {
  final dynamic content;
  final BoxFit fit;

  const AccountProfileImage({
    super.key,
    required this.content,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    bool direct = false;
    bool isEmpty = content == null;
    if (content is String) {
      direct = content.startsWith('http');
      if (!isEmpty) isEmpty = content.isEmpty;
      if (!isEmpty) isEmpty = content.endsWith('/attachments/0');
    }

    final url = direct
        ? content
        : ServiceFinder.buildUrl('files', '/attachments/$content');

    return AutoCacheImage(url, fit: fit, noErrorWidget: true);
  }
}
