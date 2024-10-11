import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/account_status.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/providers/experience.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_badge.dart';
import 'package:solian/widgets/account/account_status_action.dart';
import 'package:timeago/timeago.dart';

class AccountHeadingWidget extends StatelessWidget {
  final dynamic avatar;
  final dynamic banner;
  final String name;
  final String nick;
  final String? desc;
  final Account? detail;
  final AccountProfile? profile;
  final List<AccountBadge>? badges;
  final List<Widget>? extraWidgets;
  final List<Widget>? appendWidgets;

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
    this.detail,
    this.profile,
    this.status,
    this.extraWidgets,
    this.appendWidgets,
    this.onEditStatus,
  });

  void showStatusAction(BuildContext context, Status? current) {
    if (onEditStatus == null) return;

    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) => AccountStatusAction(currentStatus: current),
    ).then((val) {
      if (val == true) onEditStatus!();
    });
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
                        : const SizedBox.shrink(),
                  ),
                ),
              ).paddingSymmetric(horizontal: 16),
              Positioned(
                bottom: -30,
                left: 32,
                child: AttachedCircleAvatar(content: avatar, radius: 40),
              ),
            ],
          ),
          Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      nick,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ).paddingOnly(right: 4),
                  ),
                  Flexible(
                    child: Text(
                      '@$name',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                      ),
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

                      final status = AccountStatus.fromJson(
                        snapshot.data!.body,
                      );
                      final info = StatusProvider.determineStatus(status);

                      return GestureDetector(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              info.$3,
                              style: const TextStyle(height: 1),
                            ).paddingOnly(bottom: 3),
                            if (!status.isOnline && status.lastSeenAt != null)
                              Opacity(
                                opacity: 0.75,
                                child: Text('accountLastSeenAt'.trParams({
                                  'date': format(status.lastSeenAt!.toLocal(),
                                      locale: 'en_short')
                                })).paddingOnly(left: 4),
                              ),
                            info.$1.paddingSymmetric(horizontal: 6),
                          ],
                        ),
                        onTap: () {
                          showStatusAction(context, status.status);
                        },
                      );
                    },
                  ),
                ),
            ],
          ).paddingOnly(left: 116, top: 6),
          const Gap(4),
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
            ).paddingSymmetric(horizontal: 16),
          ...?extraWidgets?.map((x) => x.paddingSymmetric(horizontal: 16)),
          if (detail?.suspendedAt != null)
            SizedBox(
              width: double.infinity,
              child: Card(
                child: ListTile(
                  title: Text('accountSuspended'.tr),
                  subtitle: Text('accountSuspendedAt'.trParams({
                    'date': DateFormat('y/M/d').format(detail!.suspendedAt!),
                  })),
                  trailing: const Icon(Icons.block),
                ),
              ),
            ).paddingSymmetric(horizontal: 16),
          if (profile != null)
            Card(
              child: ListTile(
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ),
                visualDensity:
                    const VisualDensity(horizontal: -4, vertical: -2),
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      ExperienceProvider.getLevelFromExp(
                        profile!.experience ?? 0,
                      ).$2.tr,
                    ),
                    const Gap(4),
                    Badge(
                      label: Text(
                        'Lv${ExperienceProvider.getLevelFromExp(
                          profile!.experience ?? 0,
                        ).$1}',
                        style: GoogleFonts.dosis(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).paddingOnly(top: 1),
                  ],
                ),
                subtitle: SizedBox(
                  height: 20,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          borderRadius: const BorderRadius.all(
                            Radius.circular(8),
                          ),
                          value: ExperienceProvider.calcLevelUpProgress(
                            profile!.experience ?? 0,
                          ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        '${ExperienceProvider.calcLevelUpProgressLevel(profile!.experience ?? 0)} EXP',
                        style: GoogleFonts.robotoMono(
                          fontSize: 10,
                          height: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).paddingSymmetric(horizontal: 16),
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
          ).paddingSymmetric(horizontal: 16),
          ...?appendWidgets?.map((x) => x.paddingSymmetric(horizontal: 16)),
        ],
      ),
    );
  }
}
