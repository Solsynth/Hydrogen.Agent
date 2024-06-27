import 'package:floor/floor.dart';
import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/platform.dart';
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

extension MessageHistoryHelper on MessageHistoryDb {
  receiveEvent(Event remote) async {
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

  Future<(List<Event>, int)?> syncEvents(Channel channel,
      {String scope = 'global', depth = 10, offset = 0}) async {
    final lastOne = await localEvents.findLastByChannel(channel.id);

    final data = await _getRemoteEvents(
      channel,
      scope,
      remainDepth: depth,
      offset: offset,
      onBrake: (items) {
        return items.any((x) => x.id == lastOne?.id);
      },
    );
    if (data != null && !PlatformInfo.isWeb) {
      await localEvents.insertBulk(
        data.$1
            .map((x) => LocalEvent(x.id, x, x.channelId, x.createdAt))
            .toList(),
      );
    }

    return data;
  }

  Future<(List<Event>, int)?> _getRemoteEvents(
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
    if (!await auth.isAuthorized) return null;

    final client = auth.configureClient('messaging');

    final resp = await client.get(
      '/api/channels/$scope/${channel.alias}/events?take=$take&offset=$offset',
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

    final expandResult = (await _getRemoteEvents(
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

  Future<List<LocalEvent>> listMessages(Channel channel) async {
    return await localEvents.findAllByChannel(channel.id);
  }
}
