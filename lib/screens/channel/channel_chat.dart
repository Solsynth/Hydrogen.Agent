import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/call.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/models/pagination.dart';
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
import 'package:solian/widgets/chat/chat_message.dart';
import 'package:solian/widgets/chat/chat_message_action.dart';
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
  ChannelMember? _channelProfile;
  Call? _ongoingCall;
  StreamSubscription<NetworkPackage>? _subscription;

  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 0);

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

  Future<void> getMessages(int pageKey) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = auth.configureClient('messaging');

    final resp = await client.get(
        '/api/channels/${widget.realm}/${widget.alias}/messages?take=10&offset=$pageKey');

    if (resp.statusCode == 200) {
      final PaginationResult result = PaginationResult.fromJson(resp.body);
      final parsed = result.data?.map((e) => Message.fromJson(e)).toList();

      if (parsed != null && parsed.length >= 10) {
        _pagingController.appendPage(parsed, pageKey + parsed.length);
      } else if (parsed != null) {
        _pagingController.appendLastPage(parsed);
      }
    } else if (resp.statusCode == 403) {
      _pagingController.appendLastPage([]);
    } else {
      _pagingController.error = resp.bodyString;
    }
  }

  void listenMessages() {
    final ChatProvider provider = Get.find();
    _subscription = provider.stream.stream.listen((event) {
      switch (event.method) {
        case 'messages.new':
          final payload = Message.fromJson(event.payload!);
          if (payload.channelId == _channel?.id) {
            final idx = _pagingController.itemList
                ?.indexWhere((e) => e.uuid == payload.uuid);
            if ((idx ?? -1) >= 0) {
              _pagingController.itemList?[idx!] = payload;
            } else {
              _pagingController.itemList?.insert(0, payload);
            }
          }
          break;
        case 'messages.update':
          final payload = Message.fromJson(event.payload!);
          if (payload.channelId == _channel?.id) {
            final idx = _pagingController.itemList
                ?.indexWhere((x) => x.uuid == payload.uuid);
            if (idx != null) {
              _pagingController.itemList?[idx] = payload;
            }
          }
          break;
        case 'messages.burnt':
          final payload = Message.fromJson(event.payload!);
          if (payload.channelId == _channel?.id) {
            final idx = _pagingController.itemList
                ?.indexWhere((x) => x.uuid != payload.uuid);
            if (idx != null) {
              _pagingController.itemList?.removeAt(idx - 1);
            }
          }
          break;
        case 'calls.new':
          final payload = Call.fromJson(event.payload!);
          _ongoingCall = payload;
          break;
        case 'calls.end':
          _ongoingCall = null;
          break;
      }
      setState(() {});
    });
  }

  bool checkMessageMergeable(Message? a, Message? b) {
    if (a?.replyTo != null) return false;
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

  Message? _messageToReplying;
  Message? _messageToEditing;

  Widget buildHistory(context, Message item, index) {
    bool isMerged = false, hasMerged = false;
    if (index > 0) {
      hasMerged = checkMessageMergeable(
        _pagingController.itemList?[index - 1],
        item,
      );
    }
    if (index + 1 < (_pagingController.itemList?.length ?? 0)) {
      isMerged = checkMessageMergeable(
        item,
        _pagingController.itemList?[index + 1],
      );
    }

    Widget content;
    if (item.replyTo != null) {
      content = Column(
        children: [
          ChatMessage(
            key: Key('m${item.replyTo!.uuid}'),
            item: item.replyTo!,
            isReply: true,
          ).paddingOnly(left: 24, right: 4, bottom: 2),
          ChatMessage(
            key: Key('m${item.uuid}'),
            item: item,
            isMerged: isMerged,
          ),
        ],
      );
    } else {
      content = ChatMessage(
        key: Key('m${item.uuid}'),
        item: item,
        isMerged: isMerged,
      );
    }

    return InkWell(
      child: Container(
        child: content.paddingOnly(
          top: !isMerged ? 8 : 0,
          bottom: !hasMerged ? 8 : 0,
        ),
      ),
      onLongPress: () {
        showModalBottomSheet(
          useRootNavigator: true,
          context: context,
          builder: (context) => ChatMessageAction(
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
    super.initState();

    getProfile();
    getChannel().then((_) {
      listenMessages();
      _pagingController.addPageRequestListener(getMessages);
    });
    getOngoingCall();
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
                child: PagedListView<int, Message>(
                  clipBehavior: Clip.none,
                  reverse: true,
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<Message>(
                    itemBuilder: buildHistory,
                    noItemsFoundIndicatorBuilder: (_) => Container(),
                  ),
                ).paddingOnly(bottom: 56),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: SafeArea(
                  child: ChatMessageInput(
                    edit: _messageToEditing,
                    reply: _messageToReplying,
                    realm: widget.realm,
                    placeholder: placeholder,
                    channel: _channel!,
                    onSent: (Message item) {
                      setState(() {
                        _pagingController.itemList?.insert(0, item);
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
