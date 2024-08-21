import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:collection/collection.dart';

class AppNavigationRegion extends StatelessWidget {
  final bool isCollapsed;
  final Function(Channel item) onSelected;

  const AppNavigationRegion({
    super.key,
    required this.onSelected,
    this.isCollapsed = false,
  });

  void _gotoChannel(Channel item) {
    AppRouter.instance.pushReplacementNamed(
      'channelChat',
      pathParameters: {'alias': item.alias},
      queryParameters: {
        if (item.realmId != null) 'realm': item.realm!.alias,
      },
    );

    onSelected(item);
  }

  Widget _buildEntry(BuildContext context, Channel item) {
    const padding = EdgeInsets.symmetric(horizontal: 20);

    if (isCollapsed) {
      return InkWell(
        child: const Icon(Icons.tag_outlined, size: 20).paddingSymmetric(
          horizontal: 20,
          vertical: 16,
        ),
        onTap: () => _gotoChannel(item),
      );
    }

    return ListTile(
      minTileHeight: 0,
      leading: const Icon(Icons.tag_outlined),
      contentPadding: padding,
      title: Text(item.name),
      subtitle: Text(
        item.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _gotoChannel(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChannelProvider channels = Get.find();

    return Obx(() {
      final List<Channel> noRealmGroupChannels = channels.availableChannels
          .where((x) => x.type == 0 && x.realmId == null)
          .toList();
      final List<Channel> hasRealmGroupChannels = channels.availableChannels
          .where((x) => x.type == 0 && x.realmId != null)
          .toList();

      if (isCollapsed) {
        return CustomScrollView(
          slivers: [
            const SliverPadding(padding: EdgeInsets.only(top: 8)),
            SliverList.builder(
              itemCount:
                  noRealmGroupChannels.length + hasRealmGroupChannels.length,
              itemBuilder: (context, index) {
                final element = index >= noRealmGroupChannels.length
                    ? hasRealmGroupChannels[index - noRealmGroupChannels.length]
                    : noRealmGroupChannels[index];
                return Tooltip(
                  message: element.name,
                  child: _buildEntry(context, element),
                );
              },
            ),
          ],
        );
      }

      return CustomScrollView(
        slivers: [
          const SliverPadding(padding: EdgeInsets.only(top: 8)),
          SliverList.builder(
            itemCount: noRealmGroupChannels.length,
            itemBuilder: (context, index) {
              final element = noRealmGroupChannels[index];
              return _buildEntry(context, element);
            },
          ),
          SliverList.list(
            children: hasRealmGroupChannels
                .groupListsBy((x) => x.realm)
                .entries
                .map((element) {
              return ExpansionTile(
                minTileHeight: 0,
                initiallyExpanded: true,
                tilePadding: const EdgeInsets.only(left: 20, right: 24),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                collapsedBackgroundColor:
                    Theme.of(context).colorScheme.surfaceContainer,
                title: Text(element.value.first.realm!.name),
                leading: const Icon(Icons.workspaces, size: 16)
                    .paddingSymmetric(horizontal: 4),
                children:
                    element.value.map((x) => _buildEntry(context, x)).toList(),
              );
            }).toList(),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 8)),
        ],
      );
    });
  }
}
