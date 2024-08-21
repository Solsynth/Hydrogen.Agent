import 'dart:math' as math;

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
import 'package:solian/widgets/navigation/app_navigation_region.dart';

class AppNavigationDrawer extends StatefulWidget {
  final String? routeName;

  const AppNavigationDrawer({super.key, this.routeName});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer>
    with TickerProviderStateMixin {
  bool _isCollapsed = false;

  late final AnimationController _drawerAnimationController =
      AnimationController(
    duration: const Duration(milliseconds: 500),
    vsync: this,
  );
  late final Animation<double> _drawerAnimation = Tween<double>(
    begin: 80.0,
    end: 304.0,
  ).animate(CurvedAnimation(
    parent: _drawerAnimationController,
    curve: Curves.easeInOut,
  ));

  AccountStatus? _accountStatus;

  Future<void> _getStatus() async {
    final StatusProvider provider = Get.find();

    final resp = await provider.getCurrentStatus();
    final status = AccountStatus.fromJson(resp.body);

    if (mounted) {
      setState(() {
        _accountStatus = status;
      });
    }
  }

  Color get _unFocusColor =>
      Theme.of(context).colorScheme.onSurface.withOpacity(0.75);

  Widget _buildUserInfo() {
    return Obx(() {
      final AuthProvider auth = Get.find();
      if (auth.isAuthorized.isFalse || auth.userProfile.value == null) {
        if (_isCollapsed) {
          return InkWell(
            child: const Icon(Icons.account_circle).paddingSymmetric(
              horizontal: 28,
              vertical: 20,
            ),
            onTap: () {
              AppRouter.instance.goNamed('account');
              _closeDrawer();
            },
          );
        }

        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 28),
          leading: const Icon(Icons.account_circle),
          title: !_isCollapsed ? Text('guest'.tr) : null,
          subtitle: !_isCollapsed ? Text('unsignedIn'.tr) : null,
          onTap: () {
            AppRouter.instance.goNamed('account');
            _closeDrawer();
          },
        );
      }

      final leading = Obx(() {
        final statusBadgeColor = _accountStatus != null
            ? StatusProvider.determineStatus(_accountStatus!).$2
            : Colors.grey;

        final RelationshipProvider relations = Get.find();
        final accountNotifications = relations.friendRequestCount.value;

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
            badgeStyle: badges.BadgeStyle(badgeColor: statusBadgeColor),
            position: badges.BadgePosition.bottomEnd(
              bottom: 0,
              end: -2,
            ),
            child: AccountAvatar(
              content: auth.userProfile.value!['avatar'],
            ),
          ),
        );
      });

      return InkWell(
        child: !_isCollapsed
            ? Row(
                children: [
                  leading,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userProfile.value!['nick'],
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ).paddingOnly(left: 16),
                        Builder(
                          builder: (context) {
                            if (_accountStatus == null) {
                              return Text('loading'.tr).paddingOnly(left: 16);
                            }
                            final info = StatusProvider.determineStatus(
                              _accountStatus!,
                            );
                            return Text(
                              info.$3,
                              maxLines: 1,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                color: _unFocusColor,
                              ),
                            ).paddingOnly(left: 16);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ).paddingSymmetric(horizontal: 20, vertical: 16)
            : leading.paddingSymmetric(horizontal: 20, vertical: 16),
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
    });
  }

  void _expandDrawer() {
    _drawerAnimationController.animateTo(1);
  }

  void _collapseDrawer() {
    _drawerAnimationController.animateTo(0);
  }

  void _closeDrawer() {
    _autoResize();
    rootScaffoldKey.currentState!.closeDrawer();
  }

  void _autoResize() {
    if (SolianTheme.isExtraLargeScreen(context)) {
      _expandDrawer();
    } else if (SolianTheme.isLargeScreen(context)) {
      _collapseDrawer();
    }
  }

  @override
  void initState() {
    super.initState();
    _getStatus();
    Future.delayed(Duration.zero, () => _autoResize());
    _drawerAnimationController.addListener(() {
      if (_drawerAnimation.value > 180 && _isCollapsed) {
        setState(() => _isCollapsed = false);
      } else if (_drawerAnimation.value < 180 && !_isCollapsed) {
        setState(() => _isCollapsed = true);
      }
    });
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _drawerAnimation,
      builder: (context, child) {
        return Drawer(
          width: _drawerAnimation.value,
          backgroundColor:
              SolianTheme.isLargeScreen(context) ? Colors.transparent : null,
          child: child,
        );
      },
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildUserInfo().paddingSymmetric(vertical: 8),
            const Divider(thickness: 0.3, height: 1),
            Column(
              children: AppNavigation.destinations
                  .map(
                    (e) => _isCollapsed
                        ? Tooltip(
                            message: e.label,
                            child: InkWell(
                              child: Icon(e.icon, size: 20).paddingSymmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              onTap: () {
                                AppRouter.instance.goNamed(e.page);
                                _closeDrawer();
                              },
                            ),
                          )
                        : ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            leading: Icon(e.icon, size: 20).paddingAll(2),
                            title: !_isCollapsed ? Text(e.label) : null,
                            enabled: true,
                            onTap: () {
                              AppRouter.instance.goNamed(e.page);
                              _closeDrawer();
                            },
                          ),
                  )
                  .toList(),
            ),
            const Divider(thickness: 0.3, height: 1),
            Expanded(
              child: AppNavigationRegion(
                isCollapsed: _isCollapsed,
                onSelected: (item) {
                  _closeDrawer();
                },
              ),
            ),
            const Divider(thickness: 0.3, height: 1),
            Column(
              children: [
                if (_isCollapsed)
                  Tooltip(
                    message: 'settings'.tr,
                    child: InkWell(
                      child: const Icon(
                        Icons.settings,
                        size: 20,
                      ).paddingSymmetric(
                        horizontal: 28,
                        vertical: 10,
                      ),
                      onTap: () {
                        AppRouter.instance.pushNamed('settings');
                        _closeDrawer();
                      },
                    ),
                  )
                else
                  ListTile(
                    minTileHeight: 0,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    leading: const Icon(Icons.settings, size: 20).paddingAll(2),
                    title: Text('settings'.tr),
                    onTap: () {
                      AppRouter.instance.pushNamed('settings');
                      _closeDrawer();
                    },
                  ),
                if (_isCollapsed)
                  Tooltip(
                    message: 'expand'.tr,
                    child: InkWell(
                      child: const Icon(Icons.chevron_right, size: 20)
                          .paddingSymmetric(
                        horizontal: 28,
                        vertical: 10,
                      ),
                      onTap: () {
                        _expandDrawer();
                      },
                    ),
                  )
                else
                  ListTile(
                    minTileHeight: 0,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                    ),
                    leading:
                        const Icon(Icons.chevron_left, size: 20).paddingAll(2),
                    title: Text('collapse'.tr),
                    onTap: () {
                      _collapseDrawer();
                    },
                  ),
              ],
            ).paddingOnly(
              top: 8,
              bottom: math.max(8, MediaQuery.of(context).padding.bottom),
            ),
          ],
        ),
      ),
    );
  }
}
