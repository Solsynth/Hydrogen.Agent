import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account_status.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/relation.dart';
import 'package:badges/badges.dart' as badges;
import 'package:solian/widgets/account/account_avatar.dart';

class AppAccountWidget extends StatefulWidget {
  const AppAccountWidget({super.key});

  @override
  State<AppAccountWidget> createState() => _AppAccountWidgetState();
}

class _AppAccountWidgetState extends State<AppAccountWidget> {
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

  @override
  void initState() {
    super.initState();
    _getStatus();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return Obx(() {
      if (auth.isAuthorized.isFalse || auth.userProfile.value == null) {
        return const Icon(Icons.account_circle);
      }

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
            radius: 14,
            content: auth.userProfile.value!['avatar'],
          ),
        ),
      );
    });
  }
}
