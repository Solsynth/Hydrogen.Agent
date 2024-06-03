import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_badge.dart';

class AccountHeadingWidget extends StatelessWidget {
  final dynamic avatar;
  final dynamic banner;
  final String name;
  final String nick;
  final String? desc;
  final List<AccountBadge>? badges;

  const AccountHeadingWidget({
    super.key,
    this.avatar,
    this.banner,
    required this.name,
    required this.nick,
    required this.desc,
    required this.badges,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 7,
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: banner != null
                        ? AccountProfileImage(
                            content: banner,
                            fit: BoxFit.cover,
                          )
                        : const SizedBox(),
                  ),
                ),
              ).paddingSymmetric(horizontal: 16),
              Positioned(
                bottom: -30,
                left: 32,
                child: AccountAvatar(content: avatar, radius: 40),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                nick,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ).paddingOnly(right: 4),
              Text(
                '@$name',
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ],
          ).paddingOnly(left: 116, top: 6),
          const SizedBox(height: 4),
          if (badges?.isNotEmpty ?? false)
            SizedBox(
              width: double.infinity,
              child: Card(
                child: Wrap(
                  runSpacing: 2,
                  spacing: 4,
                  children: badges!.map((e) {
                    return AccountBadgeWidget(item: e);
                  }).toList(),
                ).paddingSymmetric(horizontal: 8),
              ),
            ).paddingOnly(left: 16, right: 16),
          SizedBox(
            width: double.infinity,
            child: Card(
              child: ListTile(
                title: Text('description'.tr),
                subtitle: Text(
                  (desc?.isNotEmpty ?? false) ? desc! : 'No description yet.',
                ),
              ),
            ),
          ).paddingOnly(left: 16, right: 16),
        ],
      ),
    );
  }
}
