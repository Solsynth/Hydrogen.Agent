import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/platform.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class ChannelListWidget extends StatefulWidget {
  final List<Channel> channels;
  final int selfId;
  final bool isDense;
  final bool noCategory;
  final bool useReplace;
  final Function(Channel)? onSelected;

  const ChannelListWidget({
    super.key,
    required this.channels,
    required this.selfId,
    this.isDense = false,
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

  final ChatEventController _eventController = ChatEventController();

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
    _eventController.initialize();
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

  Widget _buildDirectMessageDescription(Channel item, ChannelMember otherside) {
    if (PlatformInfo.isWeb) {
      return Text('channelDirectDescription'.trParams(
        {'username': '@${otherside.account.name}'},
      ));
    }

    return FutureBuilder(
      future: Future.delayed(
        const Duration(milliseconds: 500),
        () => _eventController.database.localEvents.findLastByChannel(item.id),
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.data == null) {
          return Text('channelDirectDescription'.trParams(
            {'username': '@${otherside.account.name}'},
          ));
        }

        return Text(
          '${snapshot.data!.data.sender.account.nick}: ${snapshot.data!.data.body['text'] ?? 'Unsupported message to preview'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }

  Widget _buildEntry(Channel item) {
    final padding = widget.isDense
        ? const EdgeInsets.symmetric(horizontal: 20)
        : const EdgeInsets.symmetric(horizontal: 16);

    if (item.type == 1) {
      final otherside = item.members!
          .where((e) => e.account.externalId != widget.selfId)
          .first;

      return ListTile(
        leading: AccountAvatar(
          content: otherside.account.avatar,
          radius: widget.isDense ? 12 : 20,
          bgColor: Theme.of(context).colorScheme.primary,
          feColor: Theme.of(context).colorScheme.onPrimary,
        ),
        contentPadding: padding,
        title: Text(otherside.account.nick),
        subtitle: !widget.isDense
            ? _buildDirectMessageDescription(item, otherside)
            : null,
        onTap: () => _gotoChannel(item),
      );
    } else {
      return ListTile(
        minTileHeight: widget.isDense ? 48 : null,
        leading: CircleAvatar(
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
        ),
        contentPadding: padding,
        title: Text(item.name),
        subtitle: !widget.isDense ? Text(item.description) : null,
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
