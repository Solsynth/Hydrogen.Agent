import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:get/get.dart' hide Value;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solian/platform.dart';
import 'package:solian/providers/database/tables/messages.dart';

import 'package:solian/models/event.dart';

part 'database.g.dart';

@DriftDatabase(tables: [LocalMessageEventTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'solar_network_local_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  static Future<int> getDatabaseSize() async {
    if (PlatformInfo.isWeb) return 0;
    final basepath = await getApplicationDocumentsDirectory();
    return await File(join(basepath.path, 'solar_network_local_db.sqlite'))
        .length();
  }

  static Future<void> removeDatabase() async {
    if (PlatformInfo.isWeb) return;
    final basepath = await getApplicationDocumentsDirectory();
    final file = File(join(basepath.path, 'solar_network_local_db.sqlite'));
    await Get.find<DatabaseProvider>().database.close();
    await file.delete();
    Get.find<DatabaseProvider>().database = AppDatabase();
  }
}

class DatabaseProvider extends GetxController {
  var database = AppDatabase();
}
