// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'events.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $MessageHistoryDbBuilderContract {
  /// Adds migrations to the builder.
  $MessageHistoryDbBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $MessageHistoryDbBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<MessageHistoryDb> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorMessageHistoryDb {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $MessageHistoryDbBuilderContract databaseBuilder(String name) =>
      _$MessageHistoryDbBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $MessageHistoryDbBuilderContract inMemoryDatabaseBuilder() =>
      _$MessageHistoryDbBuilder(null);
}

class _$MessageHistoryDbBuilder implements $MessageHistoryDbBuilderContract {
  _$MessageHistoryDbBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $MessageHistoryDbBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $MessageHistoryDbBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<MessageHistoryDb> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$MessageHistoryDb();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$MessageHistoryDb extends MessageHistoryDb {
  _$MessageHistoryDb([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  LocalEventDao? _localEventsInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 2,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `LocalEvent` (`id` INTEGER NOT NULL, `data` TEXT NOT NULL, `channelId` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  LocalEventDao get localEvents {
    return _localEventsInstance ??= _$LocalEventDao(database, changeListener);
  }
}

class _$LocalEventDao extends LocalEventDao {
  _$LocalEventDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _localEventInsertionAdapter = InsertionAdapter(
            database,
            'LocalEvent',
            (LocalEvent item) => <String, Object?>{
                  'id': item.id,
                  'data': _remoteEventConverter.encode(item.data),
                  'channelId': item.channelId,
                  'createdAt': _dateTimeConverter.encode(item.createdAt)
                }),
        _localEventUpdateAdapter = UpdateAdapter(
            database,
            'LocalEvent',
            ['id'],
            (LocalEvent item) => <String, Object?>{
                  'id': item.id,
                  'data': _remoteEventConverter.encode(item.data),
                  'channelId': item.channelId,
                  'createdAt': _dateTimeConverter.encode(item.createdAt)
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<LocalEvent> _localEventInsertionAdapter;

  final UpdateAdapter<LocalEvent> _localEventUpdateAdapter;

  @override
  Future<int?> countByChannel(int channelId) async {
    return _queryAdapter.query(
        'SELECT COUNT(id) FROM LocalEvent WHERE channelId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [channelId]);
  }

  @override
  Future<LocalEvent?> findById(int id) async {
    return _queryAdapter.query('SELECT * FROM LocalEvent WHERE id = ?1',
        mapper: (Map<String, Object?> row) => LocalEvent(
            row['id'] as int,
            _remoteEventConverter.decode(row['data'] as String),
            row['channelId'] as int,
            _dateTimeConverter.decode(row['createdAt'] as int)),
        arguments: [id]);
  }

  @override
  Future<List<LocalEvent>> findAllByChannel(int channelId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM LocalEvent WHERE channelId = ?1 ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => LocalEvent(
            row['id'] as int,
            _remoteEventConverter.decode(row['data'] as String),
            row['channelId'] as int,
            _dateTimeConverter.decode(row['createdAt'] as int)),
        arguments: [channelId]);
  }

  @override
  Future<LocalEvent?> findLastByChannel(int channelId) async {
    return _queryAdapter.query(
        'SELECT * FROM LocalEvent WHERE channelId = ?1 ORDER BY createdAt DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => LocalEvent(row['id'] as int, _remoteEventConverter.decode(row['data'] as String), row['channelId'] as int, _dateTimeConverter.decode(row['createdAt'] as int)),
        arguments: [channelId]);
  }

  @override
  Future<void> delete(int id) async {
    await _queryAdapter
        .queryNoReturn('DELETE FROM LocalEvent WHERE id = ?1', arguments: [id]);
  }

  @override
  Future<List<LocalEvent>> deleteByChannel(int channelId) async {
    return _queryAdapter.queryList(
        'DELETE FROM LocalEvent WHERE channelId = ?1',
        mapper: (Map<String, Object?> row) => LocalEvent(
            row['id'] as int,
            _remoteEventConverter.decode(row['data'] as String),
            row['channelId'] as int,
            _dateTimeConverter.decode(row['createdAt'] as int)),
        arguments: [channelId]);
  }

  @override
  Future<void> wipeLocalEvents() async {
    await _queryAdapter.queryNoReturn('DELETE FROM LocalEvent');
  }

  @override
  Future<void> insert(LocalEvent m) async {
    await _localEventInsertionAdapter.insert(m, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertBulk(List<LocalEvent> m) async {
    await _localEventInsertionAdapter.insertList(m, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(LocalEvent m) async {
    await _localEventUpdateAdapter.update(m, OnConflictStrategy.replace);
  }
}

// ignore_for_file: unused_element
final _dateTimeConverter = DateTimeConverter();
final _remoteEventConverter = RemoteEventConverter();
