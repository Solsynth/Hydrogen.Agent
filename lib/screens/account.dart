import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/models/account.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/account/account_heading.dart';
import 'package:solian/widgets/sized_container.dart';
import 'package:badges/badges.dart' as badges;

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  Widget build(BuildContext context) {
    final actionItems = [
      (
        const Icon(Icons.face),
        'accountProfile'.tr,
        'accountProfile',
      ),
      (
        Obx(() {
          final RelationshipProvider relations = Get.find();
          return badges.Badge(
            badgeContent: Text(
              relations.friendRequestCount.value.toString(),
              style: const TextStyle(color: Colors.white),
            ),
            showBadge: relations.friendRequestCount.value > 0,
            position: badges.BadgePosition.topEnd(
              top: -12,
              end: -8,
            ),
            child: const Icon(Icons.diversity_1),
          );
        }),
        'accountFriend'.tr,
        'accountFriend',
      ),
    ];

    final AuthProvider auth = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Obx(() {
          if (auth.isAuthorized.isFalse) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionCard(
                    icon: Icon(
                      Icons.login,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    title: 'signin'.tr,
                    caption: 'signinCaption'.tr,
                    onTap: () {
                      AppRouter.instance.pushNamed('signin').then((val) async {
                        if (val == true) {
                          await auth.refreshUserProfile();
                        }
                      });
                    },
                  ),
                  _ActionCard(
                    icon: Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    title: 'signup'.tr,
                    caption: 'signupCaption'.tr,
                    onTap: () {
                      AppRouter.instance.pushNamed('signup').then((_) {
                        setState(() {});
                      });
                    },
                  ),
                  const Gap(4),
                  TextButton(
                    style: const ButtonStyle(
                      visualDensity: VisualDensity(
                        horizontal: -4,
                        vertical: -2,
                      ),
                    ),
                    onPressed: () {
                      AppRouter.instance.pushNamed('settings');
                    },
                    child: Text('settings'.tr),
                  ),
                ],
              ),
            );
          }

          return CenteredContainer(
            child: ListView(
              children: [
                if (auth.userProfile.value != null)
                  const AccountHeading().paddingOnly(bottom: 8, top: 8),
                ...(actionItems.map(
                  (x) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 34),
                    leading: x.$1,
                    title: Text(x.$2),
                    onTap: () {
                      AppRouter.instance
                          .pushNamed(x.$3)
                          .then((_) => setState(() {}));
                    },
                  ),
                )),
                const Divider(thickness: 0.3, height: 1)
                    .paddingSymmetric(vertical: 4),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 34),
                  leading: const Icon(Icons.settings),
                  title: Text('settings'.tr),
                  onTap: () {
                    AppRouter.instance.pushNamed('settings');
                  },
                ),
                const Divider(thickness: 0.3, height: 1)
                    .paddingSymmetric(vertical: 4),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 34),
                  leading: const Icon(Icons.logout),
                  title: Text('signout'.tr),
                  onTap: () {
                    auth.signout();
                    setState(() {});
                  },
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class AccountHeading extends StatefulWidget {
  const AccountHeading({super.key});

  @override
  State<AccountHeading> createState() => _AccountHeadingState();
}

class _AccountHeadingState extends State<AccountHeading> {
  late Future<Response> _status;

  @override
  void initState() {
    _status = Get.find<StatusProvider>().getCurrentStatus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    final prof = auth.userProfile.value!;

    return AccountHeadingWidget(
      avatar: prof['avatar'],
      banner: prof['banner'],
      name: prof['name'],
      nick: prof['nick'],
      desc: prof['description'],
      status: _status,
      badges: prof['badges']
          ?.map((e) => AccountBadge.fromJson(e))
          .toList()
          .cast<AccountBadge>(),
      onEditStatus: () {
        setState(() {
          _status = Get.find<StatusProvider>().getCurrentStatus();
        });
      },
    );
  }
}

class _ActionCard extends StatelessWidget {
  final Widget icon;
  final String title;
  final String caption;
  final Function onTap;

  const _ActionCard({
    required this.onTap,
    required this.title,
    required this.caption,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => onTap(),
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: icon,
              ).paddingOnly(bottom: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  overflow: TextOverflow.clip,
                ),
              ),
              Text(
                caption,
                style: const TextStyle(overflow: TextOverflow.clip),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
