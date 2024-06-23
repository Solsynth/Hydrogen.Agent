import 'package:get/get.dart';
import 'package:solian/models/channel.dart';
import 'package:solian/models/message.dart';
import 'package:solian/providers/message/helper.dart';
import 'package:solian/providers/message/history.dart';

class ChatHistoryController {
  late final MessageHistoryDb database;

  final RxList<LocalMessage> currentHistory = RxList.empty(growable: true);
  final RxInt totalHistoryCount = 0.obs;

  initialize() async {
    database = await createHistoryDb();
    currentHistory.clear();
  }

  Future<void> getMessages(Channel channel, String scope) async {
    totalHistoryCount.value = await database.syncMessages(channel, scope: scope);
    await syncHistory(channel);
  }

  Future<void> syncHistory(Channel channel) async {
    currentHistory.replaceRange(0, currentHistory.length,
        await database.localMessages.findAllByChannel(channel.id));
  }

  receiveMessage(Message remote) async {
    final entry = await database.receiveMessage(remote);
    totalHistoryCount.value++;
    currentHistory.add(entry);
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
    totalHistoryCount.value--;
    currentHistory.removeWhere((x) => x.id == id);
  }
}
