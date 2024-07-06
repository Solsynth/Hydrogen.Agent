import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/message/adaptor.dart';
import 'package:solian/providers/message/events.dart';

class ChatEventController {
  late final MessageHistoryDb database;

  final RxList<LocalEvent> currentEvents = RxList.empty(growable: true);
  final RxInt totalEvents = 0.obs;

  final RxBool isLoading = false.obs;

  Channel? channel;
  String? scope;

  initialize() async {
    if (!PlatformInfo.isWeb) {
      database = await createHistoryDb();
    }
    currentEvents.clear();
  }

  Future<LocalEvent?> getEvent(int id) async {
    if (channel == null || scope == null) return null;

    if (PlatformInfo.isWeb) {
      final remoteRecord = await getRemoteEvent(id, channel!, scope!);
      if (remoteRecord == null) return null;
      return LocalEvent(
        remoteRecord.id,
        remoteRecord,
        remoteRecord.channelId,
        remoteRecord.createdAt,
      );
    } else {
      return await database.getEvent(id, channel!, scope: scope!);
    }
  }

  Future<void> getEvents(Channel channel, String scope) async {
    this.channel = channel;
    this.scope = scope;

    syncLocal(channel);

    isLoading.value = true;
    if (PlatformInfo.isWeb) {
      final result = await getRemoteEvents(
        channel,
        scope,
        remainDepth: 3,
        offset: 0,
      );
      totalEvents.value = result?.$2 ?? 0;
      if (result != null) {
        for (final x in result.$1.reversed) {
          final entry = LocalEvent(x.id, x, x.channelId, x.createdAt);
          insertEvent(entry);
          applyEvent(entry);
        }
      }
    } else {
      final result = await database.syncRemoteEvents(
        channel,
        scope: scope,
      );
      totalEvents.value = result?.$2 ?? 0;
      await syncLocal(channel);
    }
    isLoading.value = false;
  }

  Future<void> loadEvents(Channel channel, String scope) async {
    isLoading.value = true;
    if (PlatformInfo.isWeb) {
      final result = await getRemoteEvents(
        channel,
        scope,
        remainDepth: 3,
        offset: currentEvents.length,
      );
      if (result != null) {
        totalEvents.value = result.$2;
        for (final x in result.$1.reversed) {
          final entry = LocalEvent(x.id, x, x.channelId, x.createdAt);
          currentEvents.add(entry);
          applyEvent(entry);
        }
      }
    } else {
      final result = await database.syncRemoteEvents(
        channel,
        depth: 3,
        scope: scope,
        offset: currentEvents.length,
      );
      totalEvents.value = result?.$2 ?? 0;
      await syncLocal(channel);
    }
    isLoading.value = false;
  }

  Future<bool> syncLocal(Channel channel) async {
    if (PlatformInfo.isWeb) return false;
    final data = await database.localEvents.findAllByChannel(channel.id);
    currentEvents.replaceRange(0, currentEvents.length, data);
    for (final x in data.reversed) {
      applyEvent(x);
    }
    return true;
  }

  receiveEvent(Event remote) async {
    LocalEvent entry;
    if (PlatformInfo.isWeb) {
      entry = LocalEvent(
        remote.id,
        remote,
        remote.channelId,
        remote.createdAt,
      );
    } else {
      entry = await database.receiveEvent(remote);
    }

    insertEvent(entry);
    applyEvent(entry);
  }

  insertEvent(LocalEvent entry) {
    final idx = currentEvents.indexWhere((x) => x.data.uuid == entry.data.uuid);
    if (idx != -1) {
      currentEvents[idx] = entry;
    } else {
      currentEvents.insert(0, entry);
    }
  }

  applyEvent(LocalEvent entry) {
    if (entry.channelId != channel?.id) return;

    switch (entry.data.type) {
      case 'messages.edit':
        final body = EventMessageBody.fromJson(entry.data.body);
        if (body.relatedEvent != null) {
          final idx =
              currentEvents.indexWhere((x) => x.data.id == body.relatedEvent);
          if (idx != -1) {
            currentEvents[idx].data.body = entry.data.body;
            currentEvents[idx].data.updatedAt = entry.data.updatedAt;
          }
        }
      case 'messages.delete':
        final body = EventMessageBody.fromJson(entry.data.body);
        if (body.relatedEvent != null) {
          currentEvents.removeWhere((x) => x.id == body.relatedEvent);
        }
    }
  }

  addPendingEvent(Event info) async {
    currentEvents.insert(
      0,
      LocalEvent(
        info.id,
        info,
        info.channelId,
        DateTime.now(),
      ),
    );
  }
}
