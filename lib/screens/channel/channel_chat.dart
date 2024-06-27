import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:solian/controllers/chat_events_controller.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/providers/content/call.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/channel/channel_detail.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/chat/call/call_prejoin.dart';
import 'package:solian/widgets/chat/call/chat_call_action.dart';
import 'package:solian/widgets/chat/chat_event.dart';
import 'package:solian/widgets/chat/chat_event_action.dart';
import 'package:solian/widgets/chat/chat_message_input.dart';
import 'package:solian/widgets/current_state_action.dart';

class ChannelChatScreen extends StatefulWidget {
  final String alias;
  final String realm;

  const ChannelChatScreen({
    super.key,
    required this.alias,
    this.realm = 'global',
  });

  @override
  State<ChannelChatScreen> createState() => _ChannelChatScreenState();
}

class _ChannelChatScreenState extends State<ChannelChatScreen> {
  bool _isBusy = false;
  int? _accountId;

  String? _overrideAlias;

  Channel? _channel;
  Call? _ongoingCall;
  ChannelMember? _channelProfile;
  StreamSubscription<NetworkPackage>? _subscription;

  late final ChatEventController _chatController;

  getProfile() async {
    final AuthProvider auth = Get.find();
    final prof = await auth.getProfile();
    _accountId = prof.body['id'];
  }

  getChannel({String? overrideAlias}) async {
    final ChannelProvider provider = Get.find();

    setState(() => _isBusy = true);

    if (overrideAlias != null) _overrideAlias = overrideAlias;

    try {
      final resp = await provider.getChannel(
        _overrideAlias ?? widget.alias,
        realm: widget.realm,
      );
      final respProfile = await provider.getMyChannelProfile(
        _overrideAlias ?? widget.alias,
        realm: widget.realm,
      );
      setState(() {
        _channel = Channel.fromJson(resp.body);
        _channelProfile = ChannelMember.fromJson(respProfile.body);
      });
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _isBusy = false);
  }

  getOngoingCall() async {
    final ChannelProvider provider = Get.find();

    setState(() => _isBusy = true);

    try {
      final resp = await provider.getChannelOngoingCall(
        _overrideAlias ?? widget.alias,
        realm: widget.realm,
      );
      if (resp != null) {
        setState(() => _ongoingCall = Call.fromJson(resp.body));
      }
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _isBusy = false);
  }

  void listenMessages() {
    final ChatProvider provider = Get.find();
    _subscription = provider.stream.stream.listen((event) {
      switch (event.method) {
        case 'events.new':
          final payload = Event.fromJson(event.payload!);
            _chatController.receiveEvent(payload);
          break;
        case 'calls.new':
          final payload = Call.fromJson(event.payload!);
          setState(() => _ongoingCall = payload);
          break;
        case 'calls.end':
          setState(() => _ongoingCall = null);
          break;
      }
    });
  }

  bool checkMessageMergeable(Event? a, Event? b) {
    if (a == null || b == null) return false;
    if (a.sender.account.id != b.sender.account.id) return false;
    return a.createdAt.difference(b.createdAt).inMinutes <= 3;
  }

  void showCallPrejoin() {
    showModalBottomSheet(
      useRootNavigator: true,
      context: context,
      builder: (context) => ChatCallPrejoinPopup(
        ongoingCall: _ongoingCall!,
        channel: _channel!,
      ),
    );
  }

  Event? _messageToReplying;
  Event? _messageToEditing;

  Widget buildHistoryBody(Event item, {bool isMerged = false}) {
    return ChatEvent(
      key: Key('m${item.uuid}'),
      item: item,
      isMerged: isMerged,
      chatController: _chatController,
    );
  }

  Widget buildHistory(context, index) {
    bool isMerged = false, hasMerged = false;
    if (index > 0) {
      hasMerged = checkMessageMergeable(
        _chatController.currentEvents[index - 1].data,
        _chatController.currentEvents[index].data,
      );
    }
    if (index + 1 < _chatController.currentEvents.length) {
      isMerged = checkMessageMergeable(
        _chatController.currentEvents[index].data,
        _chatController.currentEvents[index + 1].data,
      );
    }

    final item = _chatController.currentEvents[index].data;

    return InkWell(
      child: Container(
        child: buildHistoryBody(item, isMerged: isMerged).paddingOnly(
          top: !isMerged ? 8 : 0,
          bottom: !hasMerged ? 8 : 0,
        ),
      ),
      onLongPress: () {
        showModalBottomSheet(
          useRootNavigator: true,
          context: context,
          builder: (context) => ChatEventAction(
            channel: _channel!,
            realm: _channel!.realm,
            item: item,
            onEdit: () {
              setState(() => _messageToEditing = item);
            },
            onReply: () {
              setState(() => _messageToReplying = item);
            },
          ),
        );
      },
    );
  }

  @override
  void initState() {
    _chatController = ChatEventController();
    _chatController.initialize();

    getChannel().then((_) {
      _chatController.getEvents(_channel!, widget.realm);

      listenMessages();
    });

    getProfile();
    getOngoingCall();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy || _channel == null) {
      return Material(
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    String title = _channel?.name ?? 'loading'.tr;
    String? placeholder;

    if (_channel?.type == 1) {
      final otherside = _channel!.members!
          .where((e) => e.account.externalId != _accountId)
          .first;
      title = otherside.account.nick;
      placeholder = 'messageInputPlaceholder'.trParams(
        {'channel': '@${otherside.account.name}'},
      );
    }

    final ChatCallProvider call = Get.find();

    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(title),
        centerTitle: false,
        titleSpacing: SolianTheme.titleSpacing(context),
        toolbarHeight: SolianTheme.toolbarHeight(context),
        actions: [
          const BackgroundStateWidget(),
          Builder(builder: (context) {
            if (_isBusy) return const SizedBox();
            return ChatCallButton(
              realm: _channel!.realm,
              channel: _channel!,
              ongoingCall: _ongoingCall,
            );
          }),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              AppRouter.instance
                  .pushNamed(
                'channelDetail',
                pathParameters: {'alias': widget.alias},
                queryParameters: {'realm': widget.realm},
                extra: ChannelDetailArguments(
                  profile: _channelProfile!,
                  channel: _channel!,
                ),
              )
                  .then((value) {
                if (value == false) AppRouter.instance.pop();
                if (value != null) {
                  final resp = Channel.fromJson(value as Map<String, dynamic>);
                  getChannel(overrideAlias: resp.alias);
                }
              });
            },
          ),
          SizedBox(
            width: SolianTheme.isLargeScreen(context) ? 8 : 16,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  reverse: true,
                  slivers: [
                    Obx(() {
                      return SliverList.builder(
                        key: Key('chat-history#${_channel!.id}'),
                        itemCount: _chatController.currentEvents.length,
                        itemBuilder: buildHistory,
                      );
                    }),
                    Obx(() {
                      final amount = _chatController.totalEvents -
                          _chatController.currentEvents.length;

                      if (amount.value <= 0 ||
                          _chatController.isLoading.isTrue) {
                        return const SliverToBoxAdapter(child: SizedBox());
                      }

                      return SliverToBoxAdapter(
                        child: ListTile(
                          tileColor:
                              Theme.of(context).colorScheme.surfaceContainerLow,
                          leading: const Icon(Icons.sync_disabled),
                          title: Text('messageUnsync'.tr),
                          subtitle: Text('messageUnsyncCaption'.trParams({
                            'count': amount.string,
                          })),
                          onTap: () {
                            _chatController.loadEvents(
                              _channel!,
                              widget.realm,
                            );
                          },
                        ),
                      );
                    }),
                    Obx(() {
                      if (_chatController.isLoading.isFalse) {
                        return const SliverToBoxAdapter(child: SizedBox());
                      }

                      return SliverToBoxAdapter(
                        child: const LinearProgressIndicator().animate().slideY(),
                      );
                    }),
                  ],
                ),
              ),
              ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: SafeArea(
                    child: ChatMessageInput(
                      edit: _messageToEditing,
                      reply: _messageToReplying,
                      realm: widget.realm,
                      placeholder: placeholder,
                      channel: _channel!,
                      onSent: (Event item) {
                        setState(() {
                          _chatController.addPendingEvent(item);
                        });
                      },
                      onReset: () {
                        setState(() {
                          _messageToReplying = null;
                          _messageToEditing = null;
                        });
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_ongoingCall != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: MaterialBanner(
                padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
                leading: const Icon(Icons.call_received),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                dividerColor: Colors.transparent,
                content: Text('callOngoing'.tr),
                actions: [
                  Obx(() {
                    if (call.current.value == null) {
                      return TextButton(
                        onPressed: showCallPrejoin,
                        child: Text('callJoin'.tr),
                      );
                    } else if (call.channel.value?.id == _channel?.id) {
                      return TextButton(
                        onPressed: () => call.gotoScreen(context),
                        child: Text('callResume'.tr),
                      );
                    } else {
                      return TextButton(
                        onPressed: null,
                        child: Text('callJoin'.tr),
                      );
                    }
                  })
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
