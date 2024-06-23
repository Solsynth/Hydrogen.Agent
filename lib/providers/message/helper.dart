import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/message/history.dart';

Future<MessageHistoryDb> createHistoryDb() async {
  return await $FloorMessageHistoryDb
      .databaseBuilder('messaging_data.dart')
      .build();
}

extension MessageHistoryHelper on MessageHistoryDb {
  receiveMessage(Message remote) async {
    await localMessages.insert(LocalMessage(
      remote.id,
      remote,
      remote.channelId,
    ));
  }

  replaceMessage(Message remote) async {
    await localMessages.update(LocalMessage(
      remote.id,
      remote,
      remote.channelId,
    ));
  }

  burnMessage(int id) async {
    await localMessages.delete(id);
  }

  syncMessages(Channel channel, {String scope = 'global', offset = 0}) async {
    final lastOne = await localMessages.findLastByChannel(channel.id);

    final data = await _getRemoteMessages(
      channel,
      scope,
      remainBreath: 3,
      offset: offset,
      onBrake: (items) {
        return items.any((x) => x.id == lastOne?.id);
      },
    );
    await localMessages.insertBulk(
      data.map((x) => LocalMessage(x.id, x, x.channelId)).toList(),
    );
  }

  Future<List<Message>> _getRemoteMessages(
    Channel channel,
    String scope, {
    required int remainBreath,
    bool Function(List<Message> items)? onBrake,
    take = 10,
    offset = 0,
  }) async {
    if (remainBreath <= 0) {
      return List.empty();
    }

    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return List.empty();

    final client = auth.configureClient('messaging');

    final resp = await client.get(
        '/api/channels/$scope/${channel.alias}/messages?take=$take&offset=$offset');

    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    final PaginationResult response = PaginationResult.fromJson(resp.body);
    final result =
        response.data?.map((e) => Message.fromJson(e)).toList() ?? List.empty();

    if (onBrake != null && onBrake(result)) {
      return result;
    }

    final expandResult = await _getRemoteMessages(
      channel,
      scope,
      remainBreath: remainBreath - 1,
      take: take,
      offset: offset + result.length,
    );

    return [...result, ...expandResult];
  }

  Future<List<LocalMessage>> listMessages(Channel channel) async {
    return await localMessages.findAllByChannel(channel.id);
  }
}
