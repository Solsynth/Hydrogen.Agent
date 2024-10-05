import 'dart:math';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class ChannelListWidget extends StatefulWidget {
  final List<Channel> channels;
  final int selfId;
  final bool isDense;
  final bool isCollapsed;
  final bool noCategory;
  final bool useReplace;
  final Function(Channel)? onSelected;

  const ChannelListWidget({
    super.key,
    required this.channels,
    required this.selfId,
    this.isDense = false,
    this.isCollapsed = false,
    this.noCategory = false,
    this.useReplace = false,
    this.onSelected,
  });

  @override
  State<ChannelListWidget> createState() => _ChannelListWidgetState();
}

class _ChannelListWidgetState extends State<ChannelListWidget> {
  final List<Channel> _globalChannels = List.empty(growable: true);
  final Map<String, List<Channel>> _inRealms = {};

  Map<int, LocalMessageEventTableData>? _lastMessages;

  final ChatEventController _eventController = ChatEventController();

  Future<void> _loadLastMessages() async {
    final messages = await _eventController.src.getLastInAllChannels();
    setState(() {
      _lastMessages = messages
          .map((k, v) => MapEntry(k, v.firstOrNull))
          .cast<int, LocalMessageEventTableData>();
    });
  }

  void _mapChannels() {
    _inRealms.clear();
    _globalChannels.clear();

    if (widget.noCategory) {
      _globalChannels.addAll(widget.channels);
      return;
    }

    for (final channel in widget.channels) {
      if (channel.realmId != null) {
        if (_inRealms[channel.realm!.alias] == null) {
          _inRealms[channel.realm!.alias] = List.empty(growable: true);
        }
        _inRealms[channel.realm!.alias]!.add(channel);
      } else {
        _globalChannels.add(channel);
      }
    }
  }

  @override
  void didUpdateWidget(covariant ChannelListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() => _mapChannels());
  }

  @override
  void initState() {
    super.initState();
    _mapChannels();
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

  Widget _buildChannelDescription(Channel item, ChannelMember? otherside) {
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
          ? Builder(builder: (context) {
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
            })
          : Builder(
              builder: (context) {
                final data = _lastMessages![item.id]!.data!;
                return Text(
                  '${data.sender.account.nick}: ${data.body['text'] ?? 'Unsupported message to preview'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
    final padding = widget.isDense
        ? const EdgeInsets.symmetric(horizontal: 20)
        : const EdgeInsets.symmetric(horizontal: 16);

    final otherside =
        item.members!.where((e) => e.account.id != widget.selfId).firstOrNull;

    if (item.type == 1 && otherside != null) {
      final avatar = AccountAvatar(
        content: otherside.account.avatar,
        radius: widget.isDense ? 12 : 20,
        bgColor: Theme.of(context).colorScheme.primary,
        feColor: Theme.of(context).colorScheme.onPrimary,
      );

      if (widget.isCollapsed) {
        return Tooltip(
          message: otherside.account.nick,
          child: InkWell(
            child: avatar.paddingSymmetric(vertical: 12),
            onTap: () => _gotoChannel(item),
          ),
        );
      }

      return ListTile(
        leading: avatar,
        contentPadding: padding,
        title: Text(otherside.account.nick),
        subtitle:
            !widget.isDense ? _buildChannelDescription(item, otherside) : null,
        onTap: () => _gotoChannel(item),
      );
    } else {
      final avatar = CircleAvatar(
        backgroundColor: item.realmId == null
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
        radius: widget.isDense ? 12 : 20,
        child: FaIcon(
          FontAwesomeIcons.hashtag,
          color: item.realmId == null
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.primary,
          size: widget.isDense ? 12 : 16,
        ),
      );

      if (widget.isCollapsed) {
        return Tooltip(
          message: item.name,
          child: InkWell(
            child: avatar.paddingSymmetric(vertical: 12),
            onTap: () => _gotoChannel(item),
          ),
        );
      }

      return ListTile(
        minTileHeight: widget.isDense ? 48 : null,
        leading: avatar,
        contentPadding: padding,
        title: Text(item.name),
        subtitle: !widget.isDense ? _buildChannelDescription(item, null) : null,
        onTap: () => _gotoChannel(item),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noCategory) {
      return CustomScrollView(
        slivers: [
          SliverList.builder(
            itemCount: _globalChannels.length,
            itemBuilder: (context, index) {
              final element = _globalChannels[index];
              return _buildEntry(element);
            },
          ),
          SliverGap(max(16, MediaQuery.of(context).padding.bottom)),
        ],
      );
    }

    return CustomScrollView(
      slivers: [
        SliverList.builder(
          itemCount: _globalChannels.length,
          itemBuilder: (context, index) {
            final element = _globalChannels[index];
            return _buildEntry(element);
          },
        ),
        SliverList.list(
          children: _inRealms.entries.map((element) {
            return ExpansionTile(
              tilePadding: const EdgeInsets.only(left: 20, right: 24),
              minTileHeight: 48,
              title: Text(element.value.first.realm!.name),
              leading: CircleAvatar(
                backgroundColor: Colors.teal,
                radius: widget.isDense ? 12 : 24,
                child: Icon(
                  Icons.workspaces,
                  color: Colors.white,
                  size: widget.isDense ? 12 : 16,
                ),
              ),
              children: element.value.map((x) => _buildEntry(x)).toList(),
            );
          }).toList(),
        ),
      ],
    );
  }
}
