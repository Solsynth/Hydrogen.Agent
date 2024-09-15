import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/event.dart';
import 'package:solian/providers/database/database.dart';
import 'package:solian/providers/database/services/messages.dart';

class ChatEventController {
  late final MessagesFetchingProvider src;

  final RxList<LocalMessageEventTableData> currentEvents =
      RxList.empty(growable: true);
  final RxInt totalEvents = 0.obs;

  final RxBool isLoading = true.obs;

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

  Future<void> getInitialEvents(Channel channel, String scope) async {
    this.channel = channel;
    this.scope = scope;

    isLoading.value = true;
    await syncLocal(channel, take: 10);

    src.pullRemoteEvents(channel, scope: scope, take: 10).then((result) {
      totalEvents.value = result?.$2 ?? 0;
      syncLocal(channel, take: 10);
    });
    isLoading.value = false;
  }

  Future<void> loadEvents(Channel channel, String scope) async {
    const take = 20;
    final offset = currentEvents.length;

    isLoading.value = true;
    await syncLocal(channel, take: take, offset: offset);
    src.pullRemoteEvents(channel, scope: scope, offset: offset).then((result) {
      totalEvents.value = result?.$2 ?? 0;
      syncLocal(channel, take: take, offset: offset);
    });
    isLoading.value = false;
  }

  Future<bool> syncLocal(Channel channel,
      {required int take, int offset = 0}) async {
    final data = await src.listEvents(channel, take: take, offset: offset);
    currentEvents.replaceRange(0, currentEvents.length, data);
    for (final x in data.reversed) {
      applyEvent(x);
    }
    return true;
  }

  receiveEvent(Event remote) async {
    LocalMessageEventTableData entry;
    entry = await src.receiveEvent(remote);

    totalEvents.value++;
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
