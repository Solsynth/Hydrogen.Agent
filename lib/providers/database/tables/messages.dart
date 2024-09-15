import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:solian/models/event.dart';

class LocalMessageEventTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get channelId => integer()();
  TextColumn get data => text().map(const MessageEventConverter())();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(Constant(DateTime.now()))();
}

class MessageEventConverter extends TypeConverter<Event?, String> {
  const MessageEventConverter();

  @override
  Event? fromSql(String fromDb) => Event.fromJson(jsonDecode(fromDb));

  @override
  String toSql(Event? value) => jsonEncode(value?.toJson());
}
