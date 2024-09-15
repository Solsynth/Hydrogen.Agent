// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalMessageEventTableTable extends LocalMessageEventTable
    with TableInfo<$LocalMessageEventTableTable, LocalMessageEventTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessageEventTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _channelIdMeta =
      const VerificationMeta('channelId');
  @override
  late final GeneratedColumn<int> channelId = GeneratedColumn<int>(
      'channel_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumnWithTypeConverter<Event?, String> data =
      GeneratedColumn<String>('data', aliasedName, false,
              type: DriftSqlType.string, requiredDuringInsert: true)
          .withConverter<Event?>($LocalMessageEventTableTable.$converterdata);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: Constant(DateTime.now()));
  @override
  List<GeneratedColumn> get $columns => [id, channelId, data, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_message_event_table';
  @override
  VerificationContext validateIntegrity(
      Insertable<LocalMessageEventTableData> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('channel_id')) {
      context.handle(_channelIdMeta,
          channelId.isAcceptableOrUnknown(data['channel_id']!, _channelIdMeta));
    } else if (isInserting) {
      context.missing(_channelIdMeta);
    }
    context.handle(_dataMeta, const VerificationResult.success());
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMessageEventTableData map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessageEventTableData(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      channelId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}channel_id'])!,
      data: $LocalMessageEventTableTable.$converterdata.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}data'])!),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $LocalMessageEventTableTable createAlias(String alias) {
    return $LocalMessageEventTableTable(attachedDatabase, alias);
  }

  static TypeConverter<Event?, String> $converterdata =
      const MessageEventConverter();
}

class LocalMessageEventTableData extends DataClass
    implements Insertable<LocalMessageEventTableData> {
  final int id;
  final int channelId;
  final Event? data;
  final DateTime createdAt;
  const LocalMessageEventTableData(
      {required this.id,
      required this.channelId,
      this.data,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['channel_id'] = Variable<int>(channelId);
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(
          $LocalMessageEventTableTable.$converterdata.toSql(data));
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalMessageEventTableCompanion toCompanion(bool nullToAbsent) {
    return LocalMessageEventTableCompanion(
      id: Value(id),
      channelId: Value(channelId),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      createdAt: Value(createdAt),
    );
  }

  factory LocalMessageEventTableData.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessageEventTableData(
      id: serializer.fromJson<int>(json['id']),
      channelId: serializer.fromJson<int>(json['channelId']),
      data: serializer.fromJson<Event?>(json['data']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'channelId': serializer.toJson<int>(channelId),
      'data': serializer.toJson<Event?>(data),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalMessageEventTableData copyWith(
          {int? id,
          int? channelId,
          Value<Event?> data = const Value.absent(),
          DateTime? createdAt}) =>
      LocalMessageEventTableData(
        id: id ?? this.id,
        channelId: channelId ?? this.channelId,
        data: data.present ? data.value : this.data,
        createdAt: createdAt ?? this.createdAt,
      );
  LocalMessageEventTableData copyWithCompanion(
      LocalMessageEventTableCompanion data) {
    return LocalMessageEventTableData(
      id: data.id.present ? data.id.value : this.id,
      channelId: data.channelId.present ? data.channelId.value : this.channelId,
      data: data.data.present ? data.data.value : this.data,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageEventTableData(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, channelId, data, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessageEventTableData &&
          other.id == this.id &&
          other.channelId == this.channelId &&
          other.data == this.data &&
          other.createdAt == this.createdAt);
}

class LocalMessageEventTableCompanion
    extends UpdateCompanion<LocalMessageEventTableData> {
  final Value<int> id;
  final Value<int> channelId;
  final Value<Event?> data;
  final Value<DateTime> createdAt;
  const LocalMessageEventTableCompanion({
    this.id = const Value.absent(),
    this.channelId = const Value.absent(),
    this.data = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LocalMessageEventTableCompanion.insert({
    this.id = const Value.absent(),
    required int channelId,
    required Event? data,
    this.createdAt = const Value.absent(),
  })  : channelId = Value(channelId),
        data = Value(data);
  static Insertable<LocalMessageEventTableData> custom({
    Expression<int>? id,
    Expression<int>? channelId,
    Expression<String>? data,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (channelId != null) 'channel_id': channelId,
      if (data != null) 'data': data,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LocalMessageEventTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? channelId,
      Value<Event?>? data,
      Value<DateTime>? createdAt}) {
    return LocalMessageEventTableCompanion(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (channelId.present) {
      map['channel_id'] = Variable<int>(channelId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(
          $LocalMessageEventTableTable.$converterdata.toSql(data.value));
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessageEventTableCompanion(')
          ..write('id: $id, ')
          ..write('channelId: $channelId, ')
          ..write('data: $data, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $LocalMessageEventTableTable localMessageEventTable =
      $LocalMessageEventTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [localMessageEventTable];
}

typedef $$LocalMessageEventTableTableCreateCompanionBuilder
    = LocalMessageEventTableCompanion Function({
  Value<int> id,
  required int channelId,
  required Event? data,
  Value<DateTime> createdAt,
});
typedef $$LocalMessageEventTableTableUpdateCompanionBuilder
    = LocalMessageEventTableCompanion Function({
  Value<int> id,
  Value<int> channelId,
  Value<Event?> data,
  Value<DateTime> createdAt,
});

class $$LocalMessageEventTableTableFilterComposer
    extends FilterComposer<_$AppDatabase, $LocalMessageEventTableTable> {
  $$LocalMessageEventTableTableFilterComposer(super.$state);
  ColumnFilters<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnFilters<int> get channelId => $state.composableBuilder(
      column: $state.table.channelId,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));

  ColumnWithTypeConverterFilters<Event?, Event, String> get data =>
      $state.composableBuilder(
          column: $state.table.data,
          builder: (column, joinBuilders) => ColumnWithTypeConverterFilters(
              column,
              joinBuilders: joinBuilders));

  ColumnFilters<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnFilters(column, joinBuilders: joinBuilders));
}

class $$LocalMessageEventTableTableOrderingComposer
    extends OrderingComposer<_$AppDatabase, $LocalMessageEventTableTable> {
  $$LocalMessageEventTableTableOrderingComposer(super.$state);
  ColumnOrderings<int> get id => $state.composableBuilder(
      column: $state.table.id,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<int> get channelId => $state.composableBuilder(
      column: $state.table.channelId,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<String> get data => $state.composableBuilder(
      column: $state.table.data,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));

  ColumnOrderings<DateTime> get createdAt => $state.composableBuilder(
      column: $state.table.createdAt,
      builder: (column, joinBuilders) =>
          ColumnOrderings(column, joinBuilders: joinBuilders));
}

class $$LocalMessageEventTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $LocalMessageEventTableTable,
    LocalMessageEventTableData,
    $$LocalMessageEventTableTableFilterComposer,
    $$LocalMessageEventTableTableOrderingComposer,
    $$LocalMessageEventTableTableCreateCompanionBuilder,
    $$LocalMessageEventTableTableUpdateCompanionBuilder,
    (
      LocalMessageEventTableData,
      BaseReferences<_$AppDatabase, $LocalMessageEventTableTable,
          LocalMessageEventTableData>
    ),
    LocalMessageEventTableData,
    PrefetchHooks Function()> {
  $$LocalMessageEventTableTableTableManager(
      _$AppDatabase db, $LocalMessageEventTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          filteringComposer: $$LocalMessageEventTableTableFilterComposer(
              ComposerState(db, table)),
          orderingComposer: $$LocalMessageEventTableTableOrderingComposer(
              ComposerState(db, table)),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> channelId = const Value.absent(),
            Value<Event?> data = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LocalMessageEventTableCompanion(
            id: id,
            channelId: channelId,
            data: data,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int channelId,
            required Event? data,
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              LocalMessageEventTableCompanion.insert(
            id: id,
            channelId: channelId,
            data: data,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$LocalMessageEventTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $LocalMessageEventTableTable,
        LocalMessageEventTableData,
        $$LocalMessageEventTableTableFilterComposer,
        $$LocalMessageEventTableTableOrderingComposer,
        $$LocalMessageEventTableTableCreateCompanionBuilder,
        $$LocalMessageEventTableTableUpdateCompanionBuilder,
        (
          LocalMessageEventTableData,
          BaseReferences<_$AppDatabase, $LocalMessageEventTableTable,
              LocalMessageEventTableData>
        ),
        LocalMessageEventTableData,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$LocalMessageEventTableTableTableManager get localMessageEventTable =>
      $$LocalMessageEventTableTableTableManager(
          _db, _db.localMessageEventTable);
}
