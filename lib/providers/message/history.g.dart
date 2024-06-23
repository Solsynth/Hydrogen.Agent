// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history.dart';

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

  LocalMessageDao? _localMessagesInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
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
            'CREATE TABLE IF NOT EXISTS `LocalMessage` (`id` INTEGER NOT NULL, `data` TEXT NOT NULL, `channelId` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  LocalMessageDao get localMessages {
    return _localMessagesInstance ??=
        _$LocalMessageDao(database, changeListener);
  }
}

class _$LocalMessageDao extends LocalMessageDao {
  _$LocalMessageDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _localMessageInsertionAdapter = InsertionAdapter(
            database,
            'LocalMessage',
            (LocalMessage item) => <String, Object?>{
                  'id': item.id,
                  'data': _remoteMessageConverter.encode(item.data),
                  'channelId': item.channelId
                }),
        _localMessageUpdateAdapter = UpdateAdapter(
            database,
            'LocalMessage',
            ['id'],
            (LocalMessage item) => <String, Object?>{
                  'id': item.id,
                  'data': _remoteMessageConverter.encode(item.data),
                  'channelId': item.channelId
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<LocalMessage> _localMessageInsertionAdapter;

  final UpdateAdapter<LocalMessage> _localMessageUpdateAdapter;

  @override
  Future<int?> countByChannel(int channelId) async {
    return _queryAdapter.query(
        'SELECT COUNT(id) FROM LocalMessage WHERE channelId = ?1',
        mapper: (Map<String, Object?> row) => row.values.first as int,
        arguments: [channelId]);
  }

  @override
  Future<List<LocalMessage>> findAllByChannel(int channelId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM LocalMessage WHERE channelId = ?1 ORDER BY id DESC',
        mapper: (Map<String, Object?> row) => LocalMessage(
            row['id'] as int,
            _remoteMessageConverter.decode(row['data'] as String),
            row['channelId'] as int),
        arguments: [channelId]);
  }

  @override
  Future<LocalMessage?> findLastByChannel(int channelId) async {
    return _queryAdapter.query(
        'SELECT * FROM LocalMessage WHERE channelId = ?1 ORDER BY id DESC LIMIT 1',
        mapper: (Map<String, Object?> row) => LocalMessage(row['id'] as int, _remoteMessageConverter.decode(row['data'] as String), row['channelId'] as int),
        arguments: [channelId]);
  }

  @override
  Future<void> delete(int id) async {
    await _queryAdapter.queryNoReturn('DELETE FROM LocalMessage WHERE id = ?1',
        arguments: [id]);
  }

  @override
  Future<List<LocalMessage>> deleteByChannel(int channelId) async {
    return _queryAdapter.queryList(
        'DELETE FROM LocalMessage WHERE channelId = ?1',
        mapper: (Map<String, Object?> row) => LocalMessage(
            row['id'] as int,
            _remoteMessageConverter.decode(row['data'] as String),
            row['channelId'] as int),
        arguments: [channelId]);
  }

  @override
  Future<void> wipeLocalMessages() async {
    await _queryAdapter.queryNoReturn('DELETE FROM LocalMessage');
  }

  @override
  Future<void> insert(LocalMessage m) async {
    await _localMessageInsertionAdapter.insert(m, OnConflictStrategy.replace);
  }

  @override
  Future<void> insertBulk(List<LocalMessage> m) async {
    await _localMessageInsertionAdapter.insertList(
        m, OnConflictStrategy.replace);
  }

  @override
  Future<void> update(LocalMessage person) async {
    await _localMessageUpdateAdapter.update(person, OnConflictStrategy.replace);
  }
}

// ignore_for_file: unused_element
final _remoteMessageConverter = RemoteMessageConverter();
