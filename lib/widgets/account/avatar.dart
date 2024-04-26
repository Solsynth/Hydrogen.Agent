import 'package:flutter/material.dart';
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
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(source),
      );
    } else {
      final url = getRequestUri('passport', '/api/avatar/$source').toString();
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        backgroundImage: NetworkImage(url),
      );
    }
  }
}
