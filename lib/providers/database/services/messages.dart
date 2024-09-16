import 'package:drift/drift.dart';
import 'package:get/get.dart' hide Value;
import 'package:solian/exceptions/request.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/models/pagination.dart';
import 'package:solian/providers/auth.dart';
import 'package:solian/providers/database/database.dart';

class MessagesFetchingProvider extends GetxController {
  Future<(List<Event>, int)?> getWhatsNewEvents(int pivot, {take = 10}) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return null;

    final client = await auth.configureClient('messaging');

    final resp = await client.get(
      '/whats-new?pivot=$pivot&take=$take',
    );

    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    final PaginationResult response = PaginationResult.fromJson(resp.body);
    final result =
        response.data?.map((e) => Event.fromJson(e)).toList() ?? List.empty();

    return (result, response.count);
  }

  Future<Event?> fetchRemoteEvent(int id, Channel channel, String scope) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return null;

    final client = await auth.configureClient('messaging');

    final resp = await client.get(
      '/channels/$scope/${channel.alias}/events/$id',
    );

    if (resp.statusCode == 404) {
      return null;
    } else if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    return Event.fromJson(resp.body);
  }

  Future<(List<Event>, int)?> fetchRemoteEvents(
    Channel channel,
    String scope, {
    take = 10,
    offset = 0,
  }) async {
    final AuthProvider auth = Get.find();
    if (auth.isAuthorized.isFalse) return null;

    final client = await auth.configureClient('messaging');

    final resp = await client.get(
      '/channels/$scope/${channel.alias}/events?take=$take&offset=$offset',
    );

    if (resp.statusCode != 200) {
      throw RequestException(resp);
    }

    final PaginationResult response = PaginationResult.fromJson(resp.body);
    final result =
        response.data?.map((e) => Event.fromJson(e)).toList() ?? List.empty();

    return (result, response.count);
  }

  Future<LocalMessageEventTableData> receiveEvent(Event remote) async {
    // Insert record
    final database = Get.find<DatabaseProvider>().database;
    final entry = await database
        .into(database.localMessageEventTable)
        .insertReturning(LocalMessageEventTableCompanion.insert(
          id: Value(remote.id),
          channelId: remote.channelId,
          data: remote,
          createdAt: Value(remote.createdAt),
        ));

    // Handle side-effect like editing and deleting
    switch (remote.type) {
      case 'messages.edit':
        final body = EventMessageBody.fromJson(remote.body);
        if (body.relatedEvent != null) {
          final target = await (database.select(database.localMessageEventTable)
                ..where((x) => x.id.equals(body.relatedEvent!)))
              .getSingleOrNull();
          if (target != null) {
            target.data!.body = remote.body;
            target.data!.updatedAt = remote.updatedAt;
            await (database.update(database.localMessageEventTable)
                  ..where((x) => x.id.equals(target.id)))
                .write(
              LocalMessageEventTableCompanion(data: Value(target.data)),
            );
          }
        }
      case 'messages.delete':
        final body = EventMessageBody.fromJson(remote.body);
        if (body.relatedEvent != null) {
          await (database.delete(database.localMessageEventTable)
                ..where((x) => x.id.equals(body.relatedEvent!)))
              .go();
        }
    }
    return entry;
  }

  Future<LocalMessageEventTableData?> getEvent(int id, Channel channel,
      {String scope = 'global'}) async {
    final database = Get.find<DatabaseProvider>().database;
    final localRecord = await (database.select(database.localMessageEventTable)
          ..where((x) => x.id.equals(id)))
        .getSingleOrNull();
    if (localRecord != null) return localRecord;

    final remoteRecord = await fetchRemoteEvent(id, channel, scope);
    if (remoteRecord == null) return null;

    return await receiveEvent(remoteRecord);
  }

  /// Pull the remote events to local database
  Future<(List<Event>, int)?> pullRemoteEvents(Channel channel,
      {String scope = 'global', take = 10, offset = 0}) async {
    final database = Get.find<DatabaseProvider>().database;

    final data = await fetchRemoteEvents(
      channel,
      scope,
      offset: offset,
      take: take,
    );
    if (data != null) {
      await database.batch((batch) {
        batch.insertAllOnConflictUpdate(
          database.localMessageEventTable,
          data.$1.map((x) => LocalMessageEventTableCompanion(
                id: Value(x.id),
                channelId: Value(x.channelId),
                data: Value(x),
                createdAt: Value(x.createdAt),
              )),
        );
      });
    }

    return data;
  }

  Future<List<LocalMessageEventTableData>> listEvents(Channel channel,
      {required int take, int offset = 0}) async {
    final database = Get.find<DatabaseProvider>().database;
    return await (database.select(database.localMessageEventTable)
          ..where((x) => x.channelId.equals(channel.id))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(take, offset: offset))
        .get();
  }

  Future<LocalMessageEventTableData?> getLastInChannel(Channel channel) async {
    final database = Get.find<DatabaseProvider>().database;
    return await (database.select(database.localMessageEventTable)
          ..where((x) => x.channelId.equals(channel.id))
          ..orderBy([(t) => OrderingTerm.desc(t.id)]))
        .getSingleOrNull();
  }
}
