import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/account_status.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/status.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_badge.dart';
import 'package:solian/widgets/account/account_status_action.dart';

class AccountHeadingWidget extends StatelessWidget {
  final dynamic avatar;
  final dynamic banner;
  final String name;
  final String nick;
  final String? desc;
  final List<AccountBadge>? badges;

  final Future<Response>? status;
  final Function? onEditStatus;

  const AccountHeadingWidget({
    super.key,
    this.avatar,
    this.banner,
    required this.name,
    required this.nick,
    required this.desc,
    required this.badges,
    this.status,
    this.onEditStatus,
  });

  void showStatusAction(BuildContext context, bool hasStatus) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) => AccountStatusAction(hasStatus: hasStatus),
    );
  }

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
          Column(
            children: [
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
              ),
              if (status != null)
                SizedBox(
                  width: double.infinity,
                  child: FutureBuilder(
                    future: status,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.body == null) {
                        return Text('loading'.tr);
                      }

                      final info = StatusController.determineStatus(
                        AccountStatus.fromJson(snapshot.data!.body),
                      );

                      return GestureDetector(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(info.$2),
                            info.$1.paddingSymmetric(horizontal: 6),
                          ],
                        ),
                        onTap: () {
                          showStatusAction(
                            context,
                            snapshot.data!.body['status'] != null,
                          );
                        },
                      );
                    },
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
                ).paddingSymmetric(
                  horizontal: 8,
                  vertical: PlatformInfo.isMobile ? 0 : 6,
                ),
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
