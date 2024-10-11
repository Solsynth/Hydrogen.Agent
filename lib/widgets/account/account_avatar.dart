import 'package:flutter/material.dart';
import 'package:solian/services.dart';
import 'package:solian/widgets/account/account_profile_popup.dart';
import 'package:solian/widgets/auto_cache_image.dart';

class AttachedCircleAvatar extends StatelessWidget {
  final dynamic content;
  final Color? bgColor;
  final Color? feColor;
  final double? radius;
  final Widget? fallbackWidget;

  const AttachedCircleAvatar({
    super.key,
    required this.content,
    this.bgColor,
    this.feColor,
    this.radius,
    this.fallbackWidget,
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
          ? (fallbackWidget ??
              Icon(
                Icons.image,
                size: radius != null ? radius! * 1.2 : 24,
                color: feColor,
              ))
          : null,
    );
  }
}

class AccountAvatar extends StatelessWidget {
  final dynamic content;
  final String username;
  final Color? bgColor;
  final Color? feColor;
  final double? radius;
  final Widget? fallbackWidget;

  const AccountAvatar({
    super.key,
    required this.content,
    required this.username,
    this.bgColor,
    this.feColor,
    this.radius,
    this.fallbackWidget,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: AttachedCircleAvatar(
        content: content,
        bgColor: bgColor,
        feColor: feColor,
        radius: radius,
        fallbackWidget: (fallbackWidget ??
            Icon(
              Icons.account_circle,
              size: radius != null ? radius! * 1.2 : 24,
              color: feColor,
            )),
      ),
      onTap: () {
        showModalBottomSheet(
          useRootNavigator: true,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          context: context,
          builder: (context) => AccountProfilePopup(
            name: username,
          ),
        );
      },
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
