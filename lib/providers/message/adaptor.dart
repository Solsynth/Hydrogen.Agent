import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/message/events.dart';

Future<MessageHistoryDb> createHistoryDb() async {
  final migration1to2 = Migration(1, 2, (database) async {
    await database.execute('DROP TABLE IF EXISTS LocalMessage');
  });

  return await $FloorMessageHistoryDb
      .databaseBuilder('messaging_data.dart')
      .addMigrations([migration1to2]).build();
}

Future<Event?> getRemoteEvent(int id, Channel channel, String scope) async {
  final AuthProvider auth = Get.find();
  if (auth.isAuthorized.isFalse) return null;

  final client = auth.configureClient('messaging');

  final resp = await client.get(
    '/channels/$scope/${channel.alias}/events/$id',
  );

  if (resp.statusCode == 404) {
    return null;
  } else if (resp.statusCode != 200) {
    throw Exception(resp.bodyString);
  }

  return Event.fromJson(resp.body);
}

Future<(List<Event>, int)?> getRemoteEvents(
    Channel channel,
    String scope, {
      required int remainDepth,
      bool Function(List<Event> items)? onBrake,
      take = 10,
      offset = 0,
    }) async {
  if (remainDepth <= 0) {
    return null;
  }

  final AuthProvider auth = Get.find();
  if (auth.isAuthorized.isFalse) return null;

  final client = auth.configureClient('messaging');

  final resp = await client.get(
    '/channels/$scope/${channel.alias}/events?take=$take&offset=$offset',
  );

  if (resp.statusCode != 200) {
    throw Exception(resp.bodyString);
  }

  final PaginationResult response = PaginationResult.fromJson(resp.body);
  final result =
      response.data?.map((e) => Event.fromJson(e)).toList() ?? List.empty();

  if (onBrake != null && onBrake(result)) {
    return (result, response.count);
  }

  final expandResult = (await getRemoteEvents(
    channel,
    scope,
    remainDepth: remainDepth - 1,
    take: take,
    offset: offset + result.length,
  ))
      ?.$1 ??
      List.empty();

  return ([...result, ...expandResult], response.count);
}

extension MessageHistoryAdaptor on MessageHistoryDb {
  Future<LocalEvent> receiveEvent(Event remote) async {
    final entry = LocalEvent(
      remote.id,
      remote,
      remote.channelId,
      remote.createdAt,
    );
    await localEvents.insert(entry);
    switch (remote.type) {
      case 'messages.edit':
        final body = EventMessageBody.fromJson(remote.body);
        if (body.relatedEvent != null) {
          final target = await localEvents.findById(body.relatedEvent!);
          if (target != null) {
            target.data.body = remote.body;
            target.data.updatedAt = remote.updatedAt;
            await localEvents.update(target);
          }
        }
      case 'messages.delete':
        final body = EventMessageBody.fromJson(remote.body);
        if (body.relatedEvent != null) {
          await localEvents.delete(body.relatedEvent!);
        }
    }
    return entry;
  }

  Future<LocalEvent?> getEvent(int id, Channel channel,
      {String scope = 'global'}) async {
    final localRecord = await localEvents.findById(id);
    if (localRecord != null) return localRecord;

    final remoteRecord = await getRemoteEvent(id, channel, scope);
    if (remoteRecord == null) return null;

    return await receiveEvent(remoteRecord);
  }

  Future<(List<Event>, int)?> syncRemoteEvents(Channel channel,
      {String scope = 'global', depth = 10, offset = 0}) async {
    final lastOne = await localEvents.findLastByChannel(channel.id);

    final data = await getRemoteEvents(
      channel,
      scope,
      remainDepth: depth,
      offset: offset,
      onBrake: (items) {
        return items.any((x) => x.id == lastOne?.id);
      },
    );
    if (data != null) {
      await localEvents.insertBulk(
        data.$1
            .map((x) => LocalEvent(x.id, x, x.channelId, x.createdAt))
            .toList(),
      );
    }

    return data;
  }

  Future<List<LocalEvent>> listEvents(Channel channel) async {
    return await localEvents.findAllByChannel(channel.id);
  }
}
