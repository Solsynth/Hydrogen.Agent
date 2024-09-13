import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:get/get.dart' hide Value;
import 'package:solian/providers/database/tables/messages.dart';

import 'package:solian/models/event.dart';

part 'database.g.dart';

@DriftDatabase(tables: [LocalMessageEventTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'solar_network_local_db');
  }
}

class DatabaseProvider extends GetxController {
  final database = AppDatabase();
}
