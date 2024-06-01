import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/call.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/signin_required_overlay.dart';
import 'package:solian/widgets/channel/channel_list.dart';
import 'package:solian/widgets/chat/call/chat_call_indicator.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool _isBusy = true;
  int? _accountId;

  final List<Channel> _channels = List.empty(growable: true);

  getProfile() async {
    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    _accountId = prof.body['id'];
  }

  getChannels() async {
    setState(() => _isBusy = true);

    final ChannelProvider provider = Get.find();
    final resp = await provider.listAvailableChannel();

    setState(() {
      _channels.clear();
      _channels.addAll(
        resp.body.map((e) => Channel.fromJson(e)).toList().cast<Channel>(),
      );
    });

    setState(() => _isBusy = false);
  }

  @override
  void initState() {
    super.initState();

    getProfile();
    getChannels();
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();
    final ChatCallProvider call = Get.find();

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: FutureBuilder(
        future: auth.isAuthorized,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.data == false) {
            return SigninRequiredOverlay(
              onSignedIn: () {
                getChannels();
              },
            );
          }

          return RefreshIndicator(
            onRefresh: () => getChannels(),
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  title: Text('contact'.tr),
                  centerTitle: false,
                  titleSpacing: SolianTheme.isLargeScreen(context) ? null : 24,
                  actions: [
                    const NotificationButton(),
                    PopupMenuButton(
                      icon: const Icon(Icons.add_circle),
                      itemBuilder: (BuildContext context) => [
                        PopupMenuItem(
                          child: ListTile(
                            title: Text('channelOrganizeCommon'.tr),
                            leading: const Icon(Icons.tag),
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onTap: () {
                            AppRouter.instance
                                .pushNamed('channelOrganizing')
                                .then(
                              (value) {
                                if (value != null) getChannels();
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
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onTap: () {
                            final ChannelProvider provider = Get.find();
                            provider
                                .createDirectChannel(context, 'global')
                                .then((resp) {
                              if (resp != null) {
                                getChannels();
                              }
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
                Obx(() {
                  if (call.current.value != null) {
                    return const SliverToBoxAdapter(
                      child: ChatCallCurrentIndicator(),
                    );
                  } else {
                    return const SliverToBoxAdapter();
                  }
                }),
                if (_isBusy)
                  SliverToBoxAdapter(
                    child: const LinearProgressIndicator().animate().scaleX(),
                  ),
                ChannelListWidget(channels: _channels, selfId: _accountId ?? 0),
              ],
            ),
          );
        },
      ),
    );
  }
}
