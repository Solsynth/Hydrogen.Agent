import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/content/realm.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/account/notification.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/account/account_avatar.dart';
import 'package:solian/widgets/account/signin_required_overlay.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/channel/channel_list.dart';
import 'package:solian/widgets/chat/call/chat_call_indicator.dart';
import 'package:solian/widgets/current_state_action.dart';
import 'package:solian/widgets/root_container.dart';
import 'package:solian/widgets/sidebar/empty_placeholder.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveRootContainer(
      child: ChatList(),
    );
  }
}

class ChatListShell extends StatelessWidget {
  final Widget? child;

  const ChatListShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return RootContainer(
      child: Row(
        children: [
          const SizedBox(
            width: 360,
            child: ChatList(),
          ),
          const VerticalDivider(thickness: 0.3, width: 0.3),
          Expanded(child: child ?? const EmptyPagePlaceholder()),
        ],
      ),
    );
  }
}

class ChatList extends StatefulWidget {
  const ChatList({super.key});

  @override
  State<ChatList> createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  List<Channel> _normalChannels = List.empty();
  List<Channel> _directChannels = List.empty();
  final Map<String, List<Channel>> _realmChannels = {};

  late final ChannelProvider _channels = Get.find();

  bool _isBusy = true;

  List<Channel> _sortChannels(List<Channel> channels) {
    channels.sort(
      (a, b) =>
          _lastMessages?[b.id]?.createdAt.compareTo(
                _lastMessages?[a.id]?.createdAt ??
                    DateTime.fromMillisecondsSinceEpoch(0),
              ) ??
          0,
    );
    return channels;
  }

  Future<void> _loadNormalChannels() async {
    final resp = await _channels.listAvailableChannel(isDirect: false);
    setState(() {
      _normalChannels = _sortChannels(resp);
    });
  }

  Future<void> _loadDirectChannels() async {
    final resp = await _channels.listAvailableChannel(isDirect: true);
    setState(() {
      _directChannels = _sortChannels(resp);
    });
  }

  Future<void> _loadRealmChannels(String realm) async {
    final resp = await _channels.listAvailableChannel(scope: realm);
    setState(() {
      _realmChannels[realm] = _sortChannels(List.from(resp));
    });
  }

  Future<void> _loadAllChannels() async {
    final RealmProvider realms = Get.find();
    Future.wait([
      _loadNormalChannels(),
      _loadDirectChannels(),
      ...realms.availableRealms.map((x) => _loadRealmChannels(x.alias)),
    ]);
  }

  Map<int, LocalMessageEventTableData>? _lastMessages;

  Future<void> _loadLastMessages() async {
    final ctrl = ChatEventController();
    await ctrl.initialize();
    final messages = await ctrl.src.getLastInAllChannels();
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
    _loadLastMessages().then((_) {
      if (!mounted) return;
      _loadAllChannels().then((_) {
        if (mounted) {
          setState(() => _isBusy = false);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final AuthProvider auth = Get.find();
    final RealmProvider realms = Get.find();

    return Obx(
      () => DefaultTabController(
        length: 2 + realms.availableRealms.length,
        child: ResponsiveRootContainer(
          child: Scaffold(
            appBar: AppBar(
              leading: AppBarLeadingButton.adaptive(context),
              title: AppBarTitle('chat'.tr),
              centerTitle: true,
              toolbarHeight: AppTheme.toolbarHeight(context),
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
                        AppRouter.instance.pushNamed('channelOrganizing').then(
                          (value) {
                            if (value != null) {
                              _loadAllChannels();
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
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onTap: () {
                        final ChannelProvider channels = Get.find();
                        channels
                            .createDirectChannel(context, 'global')
                            .then((resp) {
                          if (resp != null) {
                            _loadAllChannels();
                          }
                        }).catchError((e) {
                          context.showErrorDialog(e);
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(
                  width: AppTheme.isLargeScreen(context) ? 8 : 16,
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                dividerHeight: 0.3,
                tabAlignment: TabAlignment.startOffset,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          child: const Icon(
                            Icons.forum,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const Gap(8),
                        Text('all'.tr),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 14,
                          child: Icon(
                            Icons.chat_bubble,
                            size: 16,
                          ),
                        ),
                        const Gap(8),
                        Text('channelTypeDirect'.tr),
                      ],
                    ),
                  ),
                  ...realms.availableRealms.map((x) => Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AttachedCircleAvatar(
                              content: x.avatar,
                              radius: 14,
                              fallbackWidget: const Icon(
                                Icons.workspaces,
                                size: 16,
                              ),
                            ),
                            const Gap(8),
                            Text(x.name),
                          ],
                        ),
                      )),
                ],
              ),
            ),
            body: Obx(() {
              if (auth.isAuthorized.isFalse) {
                return SigninRequiredOverlay(
                  onDone: () => _loadAllChannels(),
                );
              }

              final selfId = auth.userProfile.value!['id'];

              return Column(
                children: [
                  const ChatCallCurrentIndicator(),
                  if (_isBusy)
                    Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerLow
                          .withOpacity(0.8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          ),
                          const Gap(8),
                          Text('loading'.tr)
                        ],
                      ).paddingSymmetric(vertical: 8),
                    ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        RefreshIndicator(
                          onRefresh: _loadNormalChannels,
                          child: ChannelListWidget(
                            channels: _sortChannels([
                              ..._normalChannels,
                              ..._directChannels,
                              ..._realmChannels.values.expand((x) => x),
                            ]),
                            selfId: selfId,
                            useReplace: AppTheme.isLargeScreen(context),
                          ),
                        ),
                        RefreshIndicator(
                          onRefresh: _loadDirectChannels,
                          child: ChannelListWidget(
                            channels: _directChannels,
                            selfId: selfId,
                            useReplace: AppTheme.isLargeScreen(context),
                          ),
                        ),
                        ...realms.availableRealms.map(
                          (x) => RefreshIndicator(
                            onRefresh: () => _loadRealmChannels(x.alias),
                            child: ChannelListWidget(
                              channels: _realmChannels[x.alias] ?? [],
                              selfId: selfId,
                              useReplace: AppTheme.isLargeScreen(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
