import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:badges/badges.dart' as badges;

class ChannelListWidget extends StatefulWidget {
  final List<Channel> channels;
  final int selfId;
  final bool useReplace;
  final Function(Channel)? onSelected;

  const ChannelListWidget({
    super.key,
    required this.channels,
    required this.selfId,
    this.useReplace = false,
    this.onSelected,
  });

  @override
  State<ChannelListWidget> createState() => _ChannelListWidgetState();
}

class _ChannelListWidgetState extends State<ChannelListWidget> {
  Map<int, LocalMessageEventTableData>? _lastMessages;

  final ChatEventController _eventController = ChatEventController();

  Future<void> _loadLastMessages() async {
    final messages = await _eventController.src.getLastInAllChannels();
    if (mounted) {
      setState(() {
        _lastMessages = messages
            .map((k, v) => MapEntry(k, v.firstOrNull))
            .cast<int, LocalMessageEventTableData>();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _eventController.initialize().then((_) {
      _loadLastMessages();
    });
  }

  void _gotoChannel(Channel item) {
    if (widget.useReplace) {
      AppRouter.instance.pushReplacementNamed(
        'channelChat',
        pathParameters: {'alias': item.alias},
        queryParameters: {
          if (item.realmId != null) 'realm': item.realm!.alias,
        },
      );
    } else {
      AppRouter.instance.pushNamed(
        'channelChat',
        pathParameters: {'alias': item.alias},
        queryParameters: {
          if (item.realmId != null) 'realm': item.realm!.alias,
        },
      );
    }

    if (widget.onSelected != null) {
      widget.onSelected!(item);
    }
  }

  Widget _buildTitle(Channel item, ChannelMember? otherside) {
    if (otherside != null) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(otherside.account.nick)),
          if (_lastMessages != null && _lastMessages![item.id] != null)
            Text(
              DateFormat('MM/dd').format(
                _lastMessages![item.id]!.createdAt.toLocal(),
              ),
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
              ),
            ),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(item.name)),
        if (_lastMessages != null && _lastMessages![item.id] != null)
          Text(
            DateFormat('MM/dd').format(
              _lastMessages![item.id]!.createdAt.toLocal(),
            ),
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(Channel item, ChannelMember? otherside) {
    if (PlatformInfo.isWeb) {
      return otherside != null
          ? Text(
              'channelDirectDescription'.trParams(
                {'username': '@${otherside.account.name}'},
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : Text(
              item.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
    }

    return AnimatedSwitcher(
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      duration: const Duration(milliseconds: 300),
      child: (_lastMessages == null || _lastMessages![item.id] == null)
          ? Builder(
              builder: (context) {
                return otherside != null
                    ? Text(
                        'channelDirectDescription'.trParams(
                          {'username': '@${otherside.account.name}'},
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        item.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
              },
            )
          : Builder(
              builder: (context) {
                final data = _lastMessages![item.id]!.data!;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (item.type == 0)
                      Badge(
                        label: Text(data.sender.account.nick),
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        textColor:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    if (item.type == 0) const Gap(6),
                    if (data.body['text'] != null)
                      Expanded(
                        child: Text(
                          data.body['text'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      Badge(label: Text('unablePreview'.tr)),
                  ],
                );
              },
            ),
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.centerLeft,
          children: <Widget>[
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
    );
  }

  Widget _buildEntry(Channel item) {
    const padding = EdgeInsets.symmetric(horizontal: 20);

    final otherside =
        item.members!.where((e) => e.account.id != widget.selfId).firstOrNull;

    if (item.type == 1 && otherside != null) {
      final avatar = AttachedCircleAvatar(
        content: otherside.account.avatar,
        radius: 20,
        bgColor: Theme.of(context).colorScheme.primary,
        feColor: Theme.of(context).colorScheme.onPrimary,
      );

      return ListTile(
        leading: avatar,
        contentPadding: padding,
        title: _buildTitle(item, otherside),
        subtitle: _buildSubtitle(item, otherside),
        onTap: () => _gotoChannel(item),
      );
    } else {
      final avatar = CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        radius: 20,
        child: FaIcon(
          FontAwesomeIcons.hashtag,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 16,
        ),
      );

      return ListTile(
        minTileHeight: null,
        leading: item.realmId == null
            ? avatar
            : badges.Badge(
                position: badges.BadgePosition.bottomEnd(bottom: -4, end: -6),
                badgeStyle: badges.BadgeStyle(
                  badgeColor: Theme.of(context).colorScheme.secondaryContainer,
                  padding: const EdgeInsets.all(2),
                  elevation: 8,
                ),
                badgeContent: AttachedCircleAvatar(
                  content: item.realm?.avatar,
                  radius: 10,
                  fallbackWidget: const Icon(
                    Icons.workspaces,
                    size: 16,
                  ),
                ),
                child: avatar,
              ),
        contentPadding: padding,
        title: _buildTitle(item, null),
        subtitle: _buildSubtitle(item, null),
        onTap: () => _gotoChannel(item),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList.builder(
          itemCount: widget.channels.length,
          itemBuilder: (context, index) {
            final element = widget.channels[index];
            return _buildEntry(element);
          },
        ),
        SliverGap(max(16, MediaQuery.of(context).padding.bottom)),
      ],
    );
  }
}
