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

class _AppNavigationRegionState extends State<AppNavigationRegion>
    with SingleTickerProviderStateMixin {
  bool _isTryingExit = false;

  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  );
  late final Animation<Offset> _animationTween = Tween<Offset>(
    begin: Offset.zero,
    end: const Offset(1.0, 0.0),
  ).animate(CurvedAnimation(
    parent: _animationController,
    curve: Curves.fastOutSlowIn,
  ));

  void _focusRealm(Realm item) {
    _animationController.animateTo(1).then((_) {
      setState(
        () => Get.find<NavigationStateProvider>().focusedRealm.value = item,
      );
      _animationController.animateTo(0);
    });
  }

  void _unFocusRealm() {
    _animationController.animateTo(1).then((_) {
      setState(
        () => Get.find<NavigationStateProvider>().focusedRealm.value = null,
      );
      _animationController.animateTo(0);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildRealmFocusAvatar() {
    final focusedRealm = Get.find<NavigationStateProvider>().focusedRealm.value;
    return MouseRegion(
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
            ? GestureDetector(
                child: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 16,
                  ),
                ).paddingSymmetric(
                  vertical: 8,
                ),
                onTap: () => _unFocusRealm(),
              )
            : _buildEntryAvatar(focusedRealm!),
      ),
      onEnter: (_) => setState(() => _isTryingExit = true),
      onExit: (_) => setState(() => _isTryingExit = false),
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
    const padding = EdgeInsets.symmetric(horizontal: 20);

    if (widget.isCollapsed) {
      return InkWell(
        child: _buildEntryAvatar(item),
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
      () => AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return SlideTransition(
            position: _animationTween,
            child: child,
          );
        },
        child: navState.focusedRealm.value == null
            ? widget.isCollapsed
                ? CustomScrollView(
                    slivers: [
                      const SliverPadding(padding: EdgeInsets.only(top: 8)),
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
                      const SliverPadding(padding: EdgeInsets.only(top: 8)),
                      SliverList.builder(
                        itemCount: realms.availableRealms.length,
                        itemBuilder: (context, index) {
                          final element = realms.availableRealms[index];
                          return _buildEntry(context, element);
                        },
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
                    ],
                  )
            : Column(
                children: [
                  if (widget.isCollapsed)
                    Tooltip(
                      message: navState.focusedRealm.value!.name,
                      child: _buildRealmFocusAvatar().paddingSymmetric(
                        vertical: 8,
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
                        channels: channels.availableChannels
                            .where(
                              (x) =>
                                  x.realm?.id ==
                                  navState.focusedRealm.value?.id,
                            )
                            .toList(),
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
