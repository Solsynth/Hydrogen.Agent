import 'dart:convert';

import 'package:drift/drift.dart';

class JsonConverter extends TypeConverter<Object?, String> {
  const JsonConverter();

  @override
  Object? fromSql(String fromDb) => jsonDecode(fromDb);

  @override
  String toSql(Object? value) => jsonEncode(value);
}
