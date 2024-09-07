import 'dart:convert';

import 'package:avatar_stack/avatar_stack.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/models/account.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/call.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/chat/call/call_prejoin.dart';

class ChannelCallIndicator extends StatelessWidget {
  final Channel channel;
  final Call ongoingCall;
  final Function onJoin;

  const ChannelCallIndicator({
    super.key,
    required this.channel,
    required this.ongoingCall,
    required this.onJoin,
  });

  void _showCallPrejoin(BuildContext context) {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) => ChatCallPrejoinPopup(
        ongoingCall: ongoingCall,
        channel: channel,
        onJoin: onJoin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ChatCallProvider call = Get.find();

    return MaterialBanner(
      padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
      leading: const Icon(Icons.call_received),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      dividerColor: Colors.transparent,
      content: Row(
        children: [
          Obx(() {
            if (call.isInitialized.value) {
              return Text('callOngoingJoined'.trParams({
                'duration': call.lastDuration.value,
              }));
            } else if (ongoingCall.participants.isEmpty) {
              return Text('callOngoingEmpty'.tr);
            } else {
              return Text('callOngoingParticipants'.trParams({
                'count': ongoingCall.participants.length.toString(),
              }));
            }
          }),
          const Gap(6),
          Obx(() {
            if (call.isInitialized.value) {
              return const SizedBox();
            }
            if (ongoingCall.participants.isNotEmpty) {
              return Container(
                height: 28,
                constraints: const BoxConstraints(maxWidth: 120),
                child: AvatarStack(
                  height: 28,
                  borderWidth: 0,
                  avatars: ongoingCall.participants.map((x) {
                    final userinfo =
                        Account.fromJson(jsonDecode(x['metadata']));
                    return PlatformInfo.canCacheImage
                        ? CachedNetworkImageProvider(userinfo.avatar)
                            as ImageProvider
                        : NetworkImage(userinfo.avatar) as ImageProvider;
                  }).toList(),
                ),
              );
            }
            return const SizedBox();
          })
        ],
      ),
      actions: [
        Obx(() {
          if (call.isBusy.value) {
            return const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 3),
            ).paddingAll(16);
          } else if (call.current.value == null) {
            return TextButton(
              onPressed: () => _showCallPrejoin(context),
              child: Text('callJoin'.tr),
            );
          } else if (call.channel.value?.id == channel.id &&
              !SolianTheme.isLargeScreen(context)) {
            return TextButton(
              onPressed: () => onJoin(),
              child: Text('callResume'.tr),
            );
          } else if (!SolianTheme.isLargeScreen(context)) {
            return TextButton(
              onPressed: null,
              child: Text('callJoin'.tr),
            );
          }
          return const SizedBox();
        })
      ],
    );
  }
}
