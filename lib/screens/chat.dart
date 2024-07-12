import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/signin_required_overlay.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/channel/channel_list.dart';
import 'package:solian/widgets/chat/call/chat_call_indicator.dart';
import 'package:solian/widgets/current_state_action.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  bool _isBusy = true;
  int? _accountId;

  final List<Channel> _channels = List.empty(growable: true);

  getProfile() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final prof = await auth.getProfile();
    _accountId = prof.body['id'];
  }

  getChannels() async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

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

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverOverlapAbsorber(
                    handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                        context),
                    sliver: SliverAppBar(
                      title: AppBarTitle('chat'.tr),
                      centerTitle: false,
                      floating: true,
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
                      bottom: TabBar(
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.tag),
                            text: 'channels'.tr,
                          ),
                          Tab(
                            icon: const Icon(Icons.chat),
                            text: 'channelCategoryDirect'.tr,
                          ),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: Builder(builder: (context) {
                if (_isBusy) {
                  return const Center(child: CircularProgressIndicator());
                }

                return TabBarView(
                  children: [
                    Column(
                      children: [
                        const ChatCallCurrentIndicator(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => getChannels(),
                            child: ChannelListWidget(
                              channels:
                                  _channels.where((x) => x.type == 0).toList(),
                              selfId: _accountId ?? 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const ChatCallCurrentIndicator(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: () => getChannels(),
                            child: ChannelListWidget(
                              channels:
                                  _channels.where((x) => x.type == 1).toList(),
                              selfId: _accountId ?? 0,
                              noCategory: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
