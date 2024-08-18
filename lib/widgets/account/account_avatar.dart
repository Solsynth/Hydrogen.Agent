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
    }

    final url = direct
        ? content
        : ServiceFinder.buildUrl('files', '/attachments/$content');

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

    if (PlatformInfo.canCacheImage) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        progressIndicatorBuilder: (context, url, downloadProgress) => Center(
          child: CircularProgressIndicator(
            value: downloadProgress.progress,
          ),
        ),
      );
    } else {
      return Image.network(
        url,
        fit: fit,
        loadingBuilder: (BuildContext context, Widget child,
            ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
  }
}
