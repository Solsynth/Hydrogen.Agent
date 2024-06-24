import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/message/helper.dart';
import 'package:solian/providers/message/history.dart';

class ChatHistoryController {
  late final MessageHistoryDb database;

  final RxList<LocalMessage> currentHistory = RxList.empty(growable: true);
  final RxInt totalHistoryCount = 0.obs;

  final RxBool isLoading = false.obs;

  initialize() async {
    database = await createHistoryDb();
    currentHistory.clear();
  }

  Future<void> getMessages(Channel channel, String scope) async {
    syncHistory(channel);

    isLoading.value = true;
    totalHistoryCount.value = await database.syncMessages(
      channel,
      scope: scope,
    );
    await syncHistory(channel);
    isLoading.value = false;
  }

  Future<void> getMoreMessages(Channel channel, String scope) async {
    isLoading.value = true;
    totalHistoryCount.value = await database.syncMessages(
      channel,
      breath: 3,
      scope: scope,
      offset: currentHistory.length,
    );
    await syncHistory(channel);
    isLoading.value = false;
  }

  Future<void> syncHistory(Channel channel) async {
    currentHistory.replaceRange(0, currentHistory.length,
        await database.localMessages.findAllByChannel(channel.id));
  }

  receiveMessage(Message remote) async {
    final entry = await database.receiveMessage(remote);
    final idx = currentHistory.indexWhere((x) => x.data.uuid == remote.uuid);
    if (idx != -1) {
      currentHistory[idx] = entry;
    } else {
      currentHistory.insert(0, entry);
    }
  }

  addTemporaryMessage(Message info) async {
    currentHistory.insert(
      0,
      LocalMessage(
        info.id,
        info,
        info.channelId,
      ),
    );
  }

  void replaceMessage(Message remote) async {
    final entry = await database.replaceMessage(remote);
    currentHistory.replaceRange(
      0,
      currentHistory.length,
      currentHistory.map((x) => x.id == entry.id ? entry : x),
    );
  }

  void burnMessage(int id) async {
    await database.burnMessage(id);
    currentHistory.removeWhere((x) => x.id == id);
  }
}
