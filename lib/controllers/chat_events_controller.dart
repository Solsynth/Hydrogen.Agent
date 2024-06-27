import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/message/helper.dart';
import 'package:solian/providers/message/events.dart';

class ChatEventController {
  late final MessageHistoryDb database;

  final RxList<LocalEvent> currentEvents = RxList.empty(growable: true);
  final RxInt totalEvents = 0.obs;

  final RxBool isLoading = false.obs;

  Channel? channel;

  initialize() async {
    database = await createHistoryDb();
    currentEvents.clear();
  }

  Future<void> getEvents(Channel channel, String scope) async {
    syncLocal(channel);

    isLoading.value = true;
    final result = await database.syncEvents(
      channel,
      scope: scope,
    );
    totalEvents.value = result?.$2 ?? 0;
    if (!await syncLocal(channel) && result != null) {
      currentEvents.addAll(result.$1.map(
        (x) => LocalEvent(
          x.id,
          x,
          x.channelId,
          x.createdAt,
        ),
      ));
    }
    isLoading.value = false;
  }

  Future<void> loadEvents(Channel channel, String scope) async {
    isLoading.value = true;
    final result = await database.syncEvents(
      channel,
      depth: 3,
      scope: scope,
      offset: currentEvents.length,
    );
    totalEvents.value = result?.$2 ?? 0;
    if (!await syncLocal(channel) && result != null) {
      currentEvents.addAll(result.$1.map(
        (x) => LocalEvent(
          x.id,
          x,
          x.channelId,
          x.createdAt,
        ),
      ));
    }
    isLoading.value = false;
  }

  Future<bool> syncLocal(Channel channel) async {
    if (PlatformInfo.isWeb) return false;
    currentEvents.replaceRange(
      0,
      currentEvents.length,
      await database.localEvents.findAllByChannel(channel.id),
    );
    return true;
  }

  receiveEvent(Event remote) async {
    final entry = await database.receiveEvent(remote);

    if (remote.channelId != channel?.id) return;

    final idx = currentEvents.indexWhere((x) => x.data.uuid == remote.uuid);
    if (idx != -1) {
      currentEvents[idx] = entry;
    } else {
      currentEvents.insert(0, entry);
    }

    switch (remote.type) {
      case 'messages.edit':
        final body = EventMessageBody.fromJson(remote.body);
        if (body.relatedEvent != null) {
          final idx =
              currentEvents.indexWhere((x) => x.data.id == body.relatedEvent);
          if (idx != -1) {
            currentEvents[idx].data.body = remote.body;
            currentEvents[idx].data.updatedAt = remote.updatedAt;
          }
        }
      case 'messages.delete':
        final body = EventMessageBody.fromJson(remote.body);
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
