import 'dart:async';
import 'dart:convert';
import 'package:floor/floor.dart';
import 'package:solian/models/event.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

part 'events.g.dart';

@entity
class LocalEvent {
  @primaryKey
  final int id;

  final Event data;
  final int channelId;

  final DateTime createdAt;

  LocalEvent(this.id, this.data, this.channelId, this.createdAt);
}

class DateTimeConverter extends TypeConverter<DateTime, int> {
  @override
  DateTime decode(int databaseValue) {
    return DateTime.fromMillisecondsSinceEpoch(databaseValue);
  }

  @override
  int encode(DateTime value) {
    return value.millisecondsSinceEpoch;
  }
}

class RemoteEventConverter extends TypeConverter<Event, String> {
  @override
  Event decode(String databaseValue) {
    return Event.fromJson(jsonDecode(databaseValue));
  }

  @override
  String encode(Event value) {
    return jsonEncode(value.toJson());
  }
}

@dao
abstract class LocalEventDao {
  @Query('SELECT COUNT(id) FROM LocalEvent WHERE channelId = :channelId')
  Future<int?> countByChannel(int channelId);

  @Query('SELECT * FROM LocalEvent WHERE id = :id')
  Future<LocalEvent?> findById(int id);

  @Query('SELECT * FROM LocalEvent WHERE channelId = :channelId ORDER BY createdAt DESC')
  Future<List<LocalEvent>> findAllByChannel(int channelId);

  @Query('SELECT * FROM LocalEvent WHERE channelId = :channelId ORDER BY createdAt DESC LIMIT 1')
  Future<LocalEvent?> findLastByChannel(int channelId);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insert(LocalEvent m);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertBulk(List<LocalEvent> m);

  @Update(onConflict: OnConflictStrategy.replace)
  Future<void> update(LocalEvent m);

  @Query('DELETE FROM LocalEvent WHERE id = :id')
  Future<void> delete(int id);

  @Query('DELETE FROM LocalEvent WHERE channelId = :channelId')
  Future<List<LocalEvent>> deleteByChannel(int channelId);

  @Query('DELETE FROM LocalEvent')
  Future<void> wipeLocalEvents();
}

@TypeConverters([DateTimeConverter, RemoteEventConverter])
@Database(version: 2, entities: [LocalEvent])
abstract class MessageHistoryDb extends FloorDatabase {
  LocalEventDao get localEvents;
}
