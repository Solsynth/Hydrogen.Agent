import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/account_status.dart';
import 'package:solian/providers/account_status.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/shells/root_shell.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/account_status_action.dart';
import 'package:solian/widgets/channel/channel_list.dart';
import 'package:solian/widgets/navigation/app_navigation.dart';
import 'package:badges/badges.dart' as badges;

class AppNavigationDrawer extends StatefulWidget {
  final String? routeName;

  const AppNavigationDrawer({super.key, this.routeName});

  @override
  State<AppNavigationDrawer> createState() => _AppNavigationDrawerState();
}

class _AppNavigationDrawerState extends State<AppNavigationDrawer> {
  int? _selectedIndex = 0;

  AccountStatus? _accountStatus;

  late final AuthProvider _auth;
  late final ChannelProvider _channels;

  void getStatus() async {
    final StatusProvider provider = Get.find();

    final resp = await provider.getCurrentStatus();
    final status = AccountStatus.fromJson(resp.body);

    setState(() {
      _accountStatus = status;
    });
  }

  void detectSelectedIndex() {
    if (widget.routeName == null) return;

    final nameList = AppNavigation.destinations.map((x) => x.page).toList();
    final idx = nameList.indexOf(widget.routeName!);

    _selectedIndex = idx != -1 ? idx : null;
  }

  void closeDrawer() {
    rootScaffoldKey.currentState!.closeDrawer();
  }

  @override
  void initState() {
    super.initState();
    _auth = Get.find();
    _channels = Get.find();
    detectSelectedIndex();
    getStatus();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    detectSelectedIndex();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return NavigationDrawer(
      backgroundColor:
          SolianTheme.isLargeScreen(context) ? Colors.transparent : null,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (idx) {
        setState(() => _selectedIndex = idx);
        AppRouter.instance.goNamed(AppNavigation.destinations[idx].page);
        closeDrawer();
      },
      children: [
        FutureBuilder(
          future: auth.getProfileWithCheck(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox();
            }

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              title: Text(
                snapshot.data!.body['nick'],
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
              leading: Builder(builder: (context) {
                final badgeColor = _accountStatus != null
                    ? StatusProvider.determineStatus(
                        _accountStatus!,
                      ).$2
                    : Colors.grey;

                return badges.Badge(
                  showBadge: _accountStatus != null,
                  badgeStyle: badges.BadgeStyle(badgeColor: badgeColor),
                  position: badges.BadgePosition.bottomEnd(
                    bottom: 0,
                    end: -2,
                  ),
                  child: AccountAvatar(
                    content: snapshot.data!.body['avatar'],
                  ),
                );
              }),
              trailing: IconButton(
                icon: const Icon(Icons.face_retouching_natural),
                onPressed: () {
                  showModalBottomSheet(
                    useRootNavigator: true,
                    context: context,
                    builder: (context) => AccountStatusAction(
                      currentStatus: _accountStatus!.status,
                    ),
                  ).then((val) {
                    if (val == true) getStatus();
                  });
                },
              ),
              onTap: () {
                AppRouter.instance.goNamed('account');
                closeDrawer();
              },
            ).paddingOnly(top: 8);
          },
        ),
        const Divider(thickness: 0.3, height: 1).paddingOnly(
          bottom: 12,
          top: 8,
        ),
        ...AppNavigation.destinations.map(
          (e) => NavigationDrawerDestination(
            icon: e.icon,
            label: Text(e.label),
          ),
        ),
        const Divider(thickness: 0.3, height: 1).paddingOnly(
          top: 12,
        ),
        FutureBuilder(
          future: _auth.getProfileWithCheck(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox();
            }

            final selfId = snapshot.data!.body['id'];

            return Column(
              children: [
                ExpansionTile(
                  title: Text('chat'.tr),
                  tilePadding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    Obx(
                      () => SizedBox(
                        height: 360,
                        child: ChannelListWidget(
                          channels: _channels.groupChannels,
                          selfId: selfId,
                          isDense: true,
                          useReplace: true,
                          onSelected: (_) {
                            closeDrawer();
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
