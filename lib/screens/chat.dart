import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/exts.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/signin_required_overlay.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/channel/channel_list.dart';
import 'package:solian/widgets/chat/call/chat_call_indicator.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/sized_container.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final ChannelProvider _channels;

  @override
  void initState() {
    super.initState();
    try {
      _channels = Get.find();
      _channels.refreshAvailableChannel();
    } catch (e) {
      context.showErrorDialog(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Scaffold(
        appBar: AppBar(
          leading: AppBarLeadingButton.adaptive(context),
          title: AppBarTitle('chat'.tr),
          centerTitle: true,
          toolbarHeight: SolianTheme.toolbarHeight(context),
          actions: [
            const BackgroundStateWidget(),
            const NotificationButton(),
            PopupMenuButton(
              icon: const Icon(Icons.add_circle),
              itemBuilder: (BuildContext context) => [
                PopupMenuItem(
                  child: ListTile(
                    title: Text('channelOrganizeCommon'.tr),
                    leading: const Icon(Icons.tag),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onTap: () {
                    AppRouter.instance.pushNamed('channelOrganizing').then(
                      (value) {
                        if (value != null) {
                          _channels.refreshAvailableChannel();
                        }
                      },
                    );
                  },
                ),
                PopupMenuItem(
                  child: ListTile(
                    title: Text('channelOrganizeDirect'.tr),
                    leading: const FaIcon(
                      FontAwesomeIcons.userGroup,
                      size: 16,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onTap: () {
                    final ChannelProvider channels = Get.find();
                    channels
                        .createDirectChannel(context, 'global')
                        .then((resp) {
                      if (resp != null) {
                        _channels.refreshAvailableChannel();
                      }
                    }).catchError((e) {
                      context.showErrorDialog(e);
                    });
                  },
                ),
              ],
            ),
            SizedBox(
              width: SolianTheme.isLargeScreen(context) ? 8 : 16,
            ),
          ],
        ),
        body: Obx(() {
          if (auth.isAuthorized.isFalse) {
            return SigninRequiredOverlay(
              onSignedIn: () => _channels.refreshAvailableChannel(),
            );
          }

          final selfId = auth.userProfile.value!['id'];

          return Column(
            children: [
              Obx(() {
                if (_channels.isLoading.isFalse) {
                  return const SizedBox();
                } else {
                  return const LinearProgressIndicator();
                }
              }),
              const ChatCallCurrentIndicator(),
              Expanded(
                child: CenteredContainer(
                  child: RefreshIndicator(
                    onRefresh: _channels.refreshAvailableChannel,
                    child: Obx(
                      () => ChannelListWidget(
                        noCategory: true,
                        channels: _channels.directChannels,
                        selfId: selfId,
                        useReplace: true,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
