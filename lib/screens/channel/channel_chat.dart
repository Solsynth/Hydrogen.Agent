import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:solian/exts.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/packet.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/chat.dart';
import 'package:solian/providers/content/channel.dart';
import 'package:solian/router.dart';
import 'package:solian/services.dart';
import 'package:solian/theme.dart';
import 'package:solian/widgets/chat/chat_message.dart';
import 'package:solian/widgets/chat/chat_message_input.dart';

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
  String? _overrideAlias;

  Channel? _channel;
  StreamSubscription<NetworkPackage>? _subscription;

  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 0);

  getChannel({String? overrideAlias}) async {
    final ChannelProvider provider = Get.find();

    setState(() => _isBusy = true);

    if (overrideAlias != null) {
      _overrideAlias = overrideAlias;
    }

    try {
      final resp = await provider.getChannel(
        _overrideAlias ?? widget.alias,
        realm: widget.realm,
      );
      setState(() => _channel = Channel.fromJson(resp.body));
    } catch (e) {
      context.showErrorDialog(e);
    }

    setState(() => _isBusy = false);
  }

  Future<void> getMessages(int pageKey) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = GetConnect(maxAuthRetries: 3);
    client.httpClient.baseUrl = ServiceFinder.services['messaging'];
    client.httpClient.addAuthenticator(auth.requestAuthenticator);

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
            _pagingController.itemList
                ?.map((x) => x.id == payload.id ? payload : x)
                .toList();
          }
          break;
        case 'messages.burnt':
          final payload = Message.fromJson(event.payload!);
          if (payload.channelId == _channel?.id) {
            _pagingController.itemList = _pagingController.itemList
                ?.where((x) => x.id != payload.id)
                .toList();
          }
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

  Widget chatHistoryBuilder(context, item, index) {
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
    return InkWell(
      child: Container(
        padding: EdgeInsets.only(
          top: !isMerged ? 8 : 0,
          bottom: !hasMerged ? 8 : 0,
        ),
        child: ChatMessage(
          item: item,
          isMerged: isMerged,
        ),
      ),
      onLongPress: () {},
    ).animate(key: Key('m${item.id}'), autoPlay: true).slideY(
          curve: Curves.fastEaseInToSlowEaseOut,
          duration: 350.ms,
          begin: 0.25,
          end: 0,
        );
  }

  @override
  void initState() {
    super.initState();

    getChannel().then((_) {
      listenMessages();
      _pagingController.addPageRequestListener(getMessages);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isBusy) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_channel?.name ?? 'loading'.tr),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              AppRouter.instance
                  .pushNamed(
                'channelDetail',
                pathParameters: {'alias': widget.alias},
                queryParameters: {'realm': widget.realm},
                extra: _channel,
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
                  reverse: true,
                  clipBehavior: Clip.none,
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<Message>(
                    animateTransitions: true,
                    transitionDuration: 350.ms,
                    itemBuilder: chatHistoryBuilder,
                    noItemsFoundIndicatorBuilder: (_) => Container(),
                  ),
                ).paddingOnly(bottom: 64),
              ),
            ],
          ),
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom,
            left: 16,
            right: 16,
            child: ChatMessageInput(
              realm: widget.realm,
              channel: _channel!,
              onSent: (Message item) {
                setState(() {
                  _pagingController.itemList?.insert(0, item);
                });
              },
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