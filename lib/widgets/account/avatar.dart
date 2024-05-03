import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:solian/utils/platform.dart';
import 'package:solian/utils/service_url.dart';

class AccountAvatar extends StatelessWidget {
  final String source;
  final double? radius;
  final bool? direct;
  final Color? backgroundColor;

  const AccountAvatar({
    super.key,
    required this.source,
    this.radius,
    this.direct,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final detectRegex = RegExp(r'https://.*/api/avatar/');

    if (source.isEmpty || source.replaceAll(detectRegex, '').isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: const Icon(Icons.account_circle),
      );
    }
    if (direct == true) {
      final image = PlatformInfo.canCacheImage ? CachedNetworkImageProvider(source) : NetworkImage(source);
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: image as ImageProvider,
      );
    } else {
      final url = getRequestUri('passport', '/api/avatar/$source').toString();
      final image = PlatformInfo.canCacheImage ? CachedNetworkImageProvider(url) : NetworkImage(url);
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: image as ImageProvider,
      );
    }
  }
}
