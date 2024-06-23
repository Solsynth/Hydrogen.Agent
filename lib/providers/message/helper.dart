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
    await localMessages.insert(LocalMessage(
      remote.id,
      remote,
      remote.channelId,
    ));
  }

  syncMessages(Channel channel, {String? scope}) async {
    final AuthProvider auth = Get.find();
    if (!await auth.isAuthorized) return;

    final client = auth.configureClient('messaging');

    final resp = await client
        .get('/api/channels/$scope/${channel.alias}/messages?take=10&offset=0');

    if (resp.statusCode != 200) {
      throw Exception(resp.bodyString);
    }

    // TODO Continue sync until the last message / the message exists / sync limitation

    final PaginationResult result = PaginationResult.fromJson(resp.body);
    final parsed = result.data?.map((e) => Message.fromJson(e)).toList();
    if (parsed != null) {
      await localMessages.insertBulk(
        parsed.map((x) => LocalMessage(x.id, x, x.channelId)).toList(),
      );
    }
  }

  Future<List<LocalMessage>> listMessages(Channel channel) async {
    return await localMessages.findAllByChannel(channel.id);
  }
}
