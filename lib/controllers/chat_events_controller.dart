import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/providers/database/services/messages.dart';

class ChatEventController {
  late final MessagesFetchingProvider src;

  final RxList<LocalMessageEventTableData> currentEvents =
      RxList.empty(growable: true);
  final RxInt totalEvents = 0.obs;

  final RxBool isLoading = false.obs;

  Channel? channel;
  String? scope;

  Future<void> initialize() async {
    src = Get.find();
    currentEvents.clear();
  }

  Future<LocalMessageEventTableData?> getEvent(int id) async {
    if (channel == null || scope == null) return null;
    return await src.getEvent(id, channel!, scope: scope!);
  }

  Future<void> getEvents(Channel channel, String scope) async {
    this.channel = channel;
    this.scope = scope;

    syncLocal(channel);

    isLoading.value = true;
    if (PlatformInfo.isWeb) {
      final result = await src.fetchRemoteEvents(
        channel,
        scope,
        remainDepth: 3,
        offset: 0,
      );
      totalEvents.value = result?.$2 ?? 0;
      if (result != null) {
        for (final x in result.$1.reversed) {
          final entry = LocalMessageEventTableData(
            id: x.id,
            channelId: x.channelId,
            createdAt: x.createdAt,
            data: x,
          );
          insertEvent(entry);
          applyEvent(entry);
        }
      }
    } else {
      final result = await src.pullRemoteEvents(
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
      final result = await src.fetchRemoteEvents(
        channel,
        scope,
        remainDepth: 3,
        offset: currentEvents.length,
      );
      if (result != null) {
        totalEvents.value = result.$2;
        for (final x in result.$1.reversed) {
          final entry = LocalMessageEventTableData(
            id: x.id,
            channelId: x.channelId,
            createdAt: x.createdAt,
            data: x,
          );
          currentEvents.add(entry);
          applyEvent(entry);
        }
      }
    } else {
      final result = await src.pullRemoteEvents(
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
    final data = await src.listEvents(channel);
    currentEvents.replaceRange(0, currentEvents.length, data);
    for (final x in data.reversed) {
      applyEvent(x);
    }
    return true;
  }

  receiveEvent(Event remote) async {
    LocalMessageEventTableData entry;
    if (PlatformInfo.isWeb) {
      entry = LocalMessageEventTableData(
        id: remote.id,
        channelId: remote.channelId,
        createdAt: remote.createdAt,
        data: remote,
      );
    } else {
      entry = await src.receiveEvent(remote);
    }

    insertEvent(entry);
    applyEvent(entry);
  }

  void insertEvent(LocalMessageEventTableData entry) {
    if (entry.channelId != channel?.id) return;

    final idx = currentEvents.indexWhere(
      (x) => x.data!.uuid == entry.data!.uuid,
    );
    if (idx != -1) {
      currentEvents[idx] = entry;
    } else {
      currentEvents.insert(0, entry);
    }
  }

  void applyEvent(LocalMessageEventTableData entry) {
    if (entry.channelId != channel?.id) return;

    switch (entry.data!.type) {
      case 'messages.edit':
        final body = EventMessageBody.fromJson(entry.data!.body);
        if (body.relatedEvent != null) {
          final idx =
              currentEvents.indexWhere((x) => x.data!.id == body.relatedEvent);
          if (idx != -1) {
            currentEvents[idx].data!.body = entry.data!.body;
            currentEvents[idx].data!.updatedAt = entry.data!.updatedAt;
          }
        }
      case 'messages.delete':
        final body = EventMessageBody.fromJson(entry.data!.body);
        if (body.relatedEvent != null) {
          currentEvents.removeWhere((x) => x.id == body.relatedEvent);
        }
    }
  }

  Future<void> addPendingEvent(Event info) async {
    currentEvents.insert(
      0,
      LocalMessageEventTableData(
        id: info.id,
        channelId: info.channelId,
        createdAt: DateTime.now(),
        data: info,
      ),
    );
  }
}
