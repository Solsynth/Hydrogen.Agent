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
    final entry = LocalMessage(
      remote.id,
      remote,
      remote.channelId,
    );
    await localMessages.insert(entry);
    return entry;
  }

  replaceMessage(Message remote) async {
    final entry = LocalMessage(
      remote.id,
      remote,
      remote.channelId,
    );
    await localMessages.update(entry);
    return entry;
  }

  burnMessage(int id) async {
    await localMessages.delete(id);
  }

  syncMessages(Channel channel, {String scope = 'global', offset = 0}) async {
    final lastOne = await localMessages.findLastByChannel(channel.id);

    final data = await _getRemoteMessages(
      channel,
      scope,
      remainBreath: 10,
      offset: offset,
      onBrake: (items) {
        return items.any((x) => x.id == lastOne?.id);
      },
    );
    if (data != null) {
      await localMessages.insertBulk(
        data.$1.map((x) => LocalMessage(x.id, x, x.channelId)).toList(),
      );
    }

    return data?.$2 ?? 0;
  }

  Future<(List<Message>, int)?> _getRemoteMessages(
    Channel channel,
    String scope, {
    required int remainBreath,
    bool Function(List<Message> items)? onBrake,
    take = 10,
    offset = 0,
  }) async {
    if (remainBreath <= 0) {
      return null;
    }

    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return null;

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
      return (result, response.count);
    }

    final expandResult = (await _getRemoteMessages(
          channel,
          scope,
          remainBreath: remainBreath - 1,
          take: take,
          offset: offset + result.length,
        ))
            ?.$1 ??
        List.empty();

    return ([...result, ...expandResult], response.count);
  }

  Future<List<LocalMessage>> listMessages(Channel channel) async {
    return await localMessages.findAllByChannel(channel.id);
  }
}
