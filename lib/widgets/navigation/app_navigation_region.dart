import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/realm.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/providers/navigation.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/channel/channel_list.dart';

class AppNavigationRegion extends StatefulWidget {
  final bool isCollapsed;

  const AppNavigationRegion({
    super.key,
    this.isCollapsed = false,
  });

  @override
  State<AppNavigationRegion> createState() => _AppNavigationRegionState();
}

class _AppNavigationRegionState extends State<AppNavigationRegion> {
  bool _isTryingExit = false;

  void _focusRealm(Realm item) {
    setState(
      () => Get.find<NavigationStateProvider>().focusedRealm.value = item,
    );
  }

  void _unFocusRealm() {
    setState(
      () => Get.find<NavigationStateProvider>().focusedRealm.value = null,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildRealmFocusAvatar() {
    final focusedRealm = Get.find<NavigationStateProvider>().focusedRealm.value;
    return GestureDetector(
      child: MouseRegion(
        child: AnimatedSwitcher(
          switchInCurve: Curves.fastOutSlowIn,
          switchOutCurve: Curves.fastOutSlowIn,
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(
              scale: animation,
              child: child,
            );
          },
          child: _isTryingExit
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 16,
                  ),
                ).paddingSymmetric(
                  vertical: 8,
                )
              : _buildEntryAvatar(focusedRealm!),
        ),
        onEnter: (_) => setState(() => _isTryingExit = true),
        onExit: (_) => setState(() => _isTryingExit = false),
      ),
      onTap: () => _unFocusRealm(),
    );
  }

  Widget _buildEntryAvatar(Realm item) {
    return Hero(
      tag: Key('region-realm-avatar-${item.id}'),
      child: (item.avatar?.isNotEmpty ?? false)
          ? AccountAvatar(content: item.avatar)
          : CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.workspaces,
                color: Colors.white,
                size: 16,
              ),
            ).paddingSymmetric(
              vertical: 8,
            ),
    );
  }

  Widget _buildEntry(BuildContext context, Realm item) {
    const padding = EdgeInsets.symmetric(horizontal: 20, vertical: 8);

    if (widget.isCollapsed) {
      return InkWell(
        child: _buildEntryAvatar(item).paddingSymmetric(vertical: 8),
        onTap: () => _focusRealm(item),
      );
    }

    return ListTile(
      minTileHeight: 0,
      leading: _buildEntryAvatar(item),
      contentPadding: padding,
      title: Text(item.name),
      subtitle: Text(
        item.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _focusRealm(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final RealmProvider realms = Get.find();
    final ChannelProvider channels = Get.find();
    final AuthProvider auth = Get.find();
    final NavigationStateProvider navState = Get.find();

    return Obx(
      () => AnimatedSwitcher(
        switchInCurve: Curves.fastOutSlowIn,
        switchOutCurve: Curves.fastOutSlowIn,
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: child,
            ),
          );
        },
        child: navState.focusedRealm.value == null
            ? widget.isCollapsed
                ? CustomScrollView(
                    slivers: [
                      const SliverPadding(padding: EdgeInsets.only(top: 16)),
                      SliverList.builder(
                        itemCount: realms.availableRealms.length,
                        itemBuilder: (context, index) {
                          final element = realms.availableRealms[index];
                          return Tooltip(
                            message: element.name,
                            child: _buildEntry(context, element),
                          );
                        },
                      ),
                    ],
                  )
                : CustomScrollView(
                    slivers: [
                      SliverList.builder(
                        itemCount: realms.availableRealms.length,
                        itemBuilder: (context, index) {
                          final element = realms.availableRealms[index];
                          return _buildEntry(context, element);
                        },
                      ),
                    ],
                  )
            : Column(
                children: [
                  if (widget.isCollapsed)
                    Tooltip(
                      message: navState.focusedRealm.value!.name,
                      child: _buildRealmFocusAvatar().paddingOnly(
                        top: 24,
                        bottom: 8,
                      ),
                    )
                  else
                    ListTile(
                      minTileHeight: 0,
                      tileColor:
                          Theme.of(context).colorScheme.surfaceContainerLow,
                      leading: _buildRealmFocusAvatar(),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      title: Text(navState.focusedRealm.value!.name),
                      subtitle: Text(
                        navState.focusedRealm.value!.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Expanded(
                    child: Obx(
                      () => ChannelListWidget(
                        useReplace: true,
                        channels: channels.availableChannels
                            .where((x) =>
                                x.realm?.id == navState.focusedRealm.value?.id)
                            .toList(),
                        isCollapsed: widget.isCollapsed,
                        selfId: auth.userProfile.value!['id'],
                        noCategory: true,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
