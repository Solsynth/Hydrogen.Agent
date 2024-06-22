import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class ChannelListWidget extends StatefulWidget {
  final List<Channel> channels;
  final int selfId;
  final bool noCategory;

  const ChannelListWidget({
    super.key,
    required this.channels,
    required this.selfId,
    this.noCategory = false,
  });

  @override
  State<ChannelListWidget> createState() => _ChannelListWidgetState();
}

class _ChannelListWidgetState extends State<ChannelListWidget> {
  final List<Channel> _globalChannels = List.empty(growable: true);
  final Map<String, List<Channel>> _inRealms = {};

  void mapChannels() {
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
    setState(() => mapChannels());
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    mapChannels();
    super.initState();
  }

  Widget buildItem(Channel element) {
    if (element.type == 1) {
      final otherside = element.members!
          .where((e) => e.account.externalId != widget.selfId)
          .first;

      return ListTile(
        leading: AccountAvatar(
          content: otherside.account.avatar,
          bgColor: Colors.indigo,
          feColor: Colors.white,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        title: Text(otherside.account.nick),
        subtitle: Text(
          'channelDirectDescription'
              .trParams({'username': '@${otherside.account.name}'}),
        ),
        onTap: () {
          AppRouter.instance.pushNamed(
            'channelChat',
            pathParameters: {'alias': element.alias},
            queryParameters: {
              if (element.realmId != null) 'realm': element.realm!.alias,
            },
          );
        },
      );
    }

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.indigo,
        child: FaIcon(
          FontAwesomeIcons.hashtag,
          color: Colors.white,
          size: 16,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      title: Text(element.name),
      subtitle: Text(element.description),
      onTap: () {
        AppRouter.instance.pushNamed(
          'channelChat',
          pathParameters: {'alias': element.alias},
          queryParameters: {
            if (element.realmId != null) 'realm': element.realm!.alias,
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.noCategory) {
      return SliverList.builder(
        itemCount: _globalChannels.length,
        itemBuilder: (context, index) {
          final element = _globalChannels[index];
          return buildItem(element);
        },
      );
    }

    return SliverList.list(
      children: [
        ..._globalChannels.map((e) => buildItem(e)),
        ..._inRealms.entries.map((element) {
          return ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 24),
            title: Text(element.value.first.realm!.name),
            subtitle: Text(
              element.value.first.realm!.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            children: element.value.map((e) => buildItem(e)).toList(),
          );
        }),
      ],
    );
  }
}
