import 'dart:async';
import 'dart:convert';
import 'package:floor/floor.dart';
import 'package:solian/models/message.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'history.g.dart';

@entity
class LocalMessage {
  @primaryKey
  final int id;

  final Message data;
  final int channelId;

  LocalMessage(this.id, this.data, this.channelId);
}

class RemoteMessageConverter extends TypeConverter<Message, String> {
  @override
  Message decode(String databaseValue) {
    return Message.fromJson(jsonDecode(databaseValue));
  }

  @override
  String encode(Message value) {
    return jsonEncode(value.toJson());
  }
}

@dao
abstract class LocalMessageDao {
  @Query('SELECT COUNT(id) FROM LocalMessage WHERE channelId = :channelId')
  Future<int?> countByChannel(int channelId);

  @Query('SELECT * FROM LocalMessage WHERE channelId = :channelId ORDER BY id DESC')
  Future<List<LocalMessage>> findAllByChannel(int channelId);

  @Query('SELECT * FROM LocalMessage WHERE channelId = :channelId ORDER BY id DESC LIMIT 1')
  Future<LocalMessage?> findLastByChannel(int channelId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(LocalMessage m);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBulk(List<LocalMessage> m);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> update(LocalMessage person);

  @Query('DELETE FROM LocalMessage WHERE id = :id')
  Future<void> delete(int id);

  @Query('DELETE FROM LocalMessage WHERE channelId = :channelId')
  Future<List<LocalMessage>> deleteByChannel(int channelId);

  @Query('DELETE FROM LocalMessage')
  Future<void> wipeLocalMessages();
}

@TypeConverters([RemoteMessageConverter])
@Database(version: 1, entities: [LocalMessage])
abstract class MessageHistoryDb extends FloorDatabase {
  LocalMessageDao get localMessages;
}
