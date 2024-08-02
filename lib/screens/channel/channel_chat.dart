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
import 'package:solian/providers/content/channel.dart';
import 'package:solian/providers/websocket.dart';
import 'package:solian/router.dart';
import 'package:solian/screens/channel/channel_detail.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/app_bar_leading.dart';
import 'package:solian/widgets/app_bar_title.dart';
import 'package:solian/widgets/channel/channel_call_indicator.dart';
import 'package:solian/widgets/chat/call/chat_call_action.dart';
import 'package:solian/widgets/chat/chat_event.dart';
import 'package:solian/widgets/chat/chat_event_list.dart';
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

  String? _newAlias;

  Channel? _channel;
  Call? _ongoingCall;
  ChannelMember? _channelProfile;
  StreamSubscription<NetworkPackage>? _subscription;

  late final ChatEventController _chatController;

  _getChannel({String? alias}) async {
    final ChannelProvider provider = Get.find();

    setState(() => _isBusy = true);

    if (alias != null) _newAlias = alias;

    try {
      final resp = await provider.getChannel(
        _newAlias ?? widget.alias,
        realm: widget.realm,
      );
      final respProfile = await provider.getMyChannelProfile(
        _newAlias ?? widget.alias,
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

  _getOngoingCall() async {
    final ChannelProvider provider = Get.find();

    setState(() => _isBusy = true);

    try {
      final resp = await provider.getChannelOngoingCall(
        _newAlias ?? widget.alias,
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

  void _listenMessages() {
    final WebSocketProvider provider = Get.find();
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

  @override
  void initState() {
    _accountId = Get.find<AuthProvider>().userProfile.value!['id'];

    _chatController = ChatEventController();
    _chatController.initialize();

    _getOngoingCall();
    _getChannel().then((_) {
      _chatController.getEvents(_channel!, widget.realm);
      _listenMessages();
    });

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

    return Scaffold(
      appBar: AppBar(
        leading: AppBarLeadingButton.adaptive(context),
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
                  _getChannel(alias: resp.alias);
                }
              });
            },
          ),
          SizedBox(
            width: SolianTheme.isLargeScreen(context) ? 8 : 16,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_ongoingCall != null)
            ChannelCallIndicator(
              channel: _channel!,
              ongoingCall: _ongoingCall!,
            ),
          Expanded(
            child: ChatEventList(
              scope: widget.realm,
              channel: _channel!,
              chatController: _chatController,
              onEdit: (item) {
                setState(() => _messageToEditing = item);
              },
              onReply: (item) {
                setState(() => _messageToReplying = item);
              },
            ),
          ),
          Obx(() {
            if (_chatController.isLoading.isTrue) {
              return const LinearProgressIndicator().animate().slideY();
            } else {
              return const SizedBox();
            }
          }),
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
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
