import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account_status.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/relation.dart';
import 'package:solian/router.dart';
import 'package:solian/shells/root_shell.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_status_action.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';
import 'package:badges/badges.dart' as badges;
import 'package:solian/widgets/navigation/app_navigation_regions.dart';

class AppNavigationDrawer extends StatefulWidget {
  final String? routeName;

  const AppNavigationDrawer({super.key, this.routeName});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  AccountStatus? _accountStatus;

  Future<void> _getStatus() async {
    final StatusProvider provider = Get.find();

    final resp = await provider.getCurrentStatus();
    final status = AccountStatus.fromJson(resp.body);

    setState(() {
      _accountStatus = status;
    });
  }

  void _closeDrawer() {
    rootScaffoldKey.currentState!.closeDrawer();
  }

  Widget _buildSettingButton() {
    return IconButton(
        icon: const Icon(Icons.settings),
        onPressed: () {
          AppRouter.instance.pushNamed('settings');
          _closeDrawer();
        });
  }

  @override
  void initState() {
    super.initState();
    _getStatus();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return Drawer(
      backgroundColor:
          SolianTheme.isLargeScreen(context) ? Colors.transparent : null,
      child: SafeArea(
        child: Column(
          children: [
            Obx(() {
              if (auth.isAuthorized.isFalse || auth.userProfile.value == null) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 28),
                  leading: const Icon(Icons.account_circle),
                  title: Text('guest'.tr),
                  subtitle: Text('unsignedIn'.tr),
                  trailing: _buildSettingButton(),
                  onTap: () {
                    AppRouter.instance.goNamed('account');
                    _closeDrawer();
                  },
                );
              }

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                title: Text(
                  auth.userProfile.value!['nick'],
                  maxLines: 1,
                  overflow: TextOverflow.fade,
                ),
                subtitle: Builder(
                  builder: (context) {
                    if (_accountStatus == null) {
                      return Text('loading'.tr);
                    }
                    final info = StatusProvider.determineStatus(
                      _accountStatus!,
                    );
                    return Text(
                      info.$3,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                    );
                  },
                ),
                leading: Obx(() {
                  final statusBadgeColor = _accountStatus != null
                      ? StatusProvider.determineStatus(
                          _accountStatus!,
                        ).$2
                      : Colors.grey;

                  final RelationshipProvider relations = Get.find();
                  final accountNotifications =
                      relations.friendRequestCount.value;

                  return badges.Badge(
                    badgeContent: Text(
                      accountNotifications.toString(),
                      style: const TextStyle(color: Colors.white),
                    ),
                    showBadge: accountNotifications > 0,
                    position: badges.BadgePosition.topEnd(
                      top: -10,
                      end: -6,
                    ),
                    child: badges.Badge(
                      showBadge: _accountStatus != null,
                      badgeStyle:
                          badges.BadgeStyle(badgeColor: statusBadgeColor),
                      position: badges.BadgePosition.bottomEnd(
                        bottom: 0,
                        end: -2,
                      ),
                      child: AccountAvatar(
                        content: auth.userProfile.value!['avatar'],
                      ),
                    ),
                  );
                }),
                trailing: _buildSettingButton(),
                onTap: () {
                  AppRouter.instance.goNamed('account');
                  _closeDrawer();
                },
                onLongPress: () {
                  showModalBottomSheet(
                    useRootNavigator: true,
                    context: context,
                    builder: (context) => AccountStatusAction(
                      currentStatus: _accountStatus!.status,
                    ),
                  ).then((val) {
                    if (val == true) _getStatus();
                  });
                },
              );
            }).paddingOnly(top: 8),
            const Divider(thickness: 0.3, height: 1),
            Column(
              children: AppNavigation.destinations
                  .map(
                    (e) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      leading: e.icon,
                      title: Text(e.label),
                      enabled: true,
                      onTap: () {
                        AppRouter.instance.goNamed(e.page);
                        _closeDrawer();
                      },
                    ),
                  )
                  .toList(),
            ).paddingSymmetric(vertical: 8),
            const Divider(thickness: 0.3, height: 1),
            Expanded(
              child: AppNavigationRegions(
                onSelected: (item) {
                  _closeDrawer();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
