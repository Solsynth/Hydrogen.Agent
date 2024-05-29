import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/widgets/account/account_avatar.dart';

class ChannelListWidget extends StatelessWidget {
  final List<Channel> channels;
  final int selfId;

  const ChannelListWidget(
      {super.key, required this.channels, required this.selfId});

  @override
  Widget build(BuildContext context) {
    return SliverList.builder(
      itemCount: channels.length,
      itemBuilder: (context, index) {
        final element = channels[index];

        if (element.type == 1) {
          final otherside = element.members!
              .where((e) => e.account.externalId != selfId)
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
      },
    );
  }
}
