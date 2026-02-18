import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

// ---------- Table definitions ----------

class Sites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get location => text().nullable()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  RealColumn get elevation => real().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Hives extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  IntColumn get siteId => integer().references(Sites, #id)();
  IntColumn get number => integer()();
  TextColumn get name => text().nullable()();
  IntColumn get queenYear => integer().nullable()();
  TextColumn get queenColor => text().nullable()();
  BoolColumn get queenMarked => boolean().withDefault(const Constant(false))();
  TextColumn get notes => text().nullable()();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get clientEventId => text()();
  IntColumn get hiveId => integer().nullable().references(Hives, #id)();
  IntColumn get siteId => integer().nullable().references(Sites, #id)();
  TextColumn get type => text()();
  DateTimeColumn get occurredAtLocal => dateTime()();
  DateTimeColumn get occurredAtUtc => dateTime()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  TextColumn get attachments => text().nullable()();
  TextColumn get source =>
      text().withDefault(const Constant('manual'))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get serverId => text().nullable()();
  TextColumn get clientTaskId => text()();
  IntColumn get hiveId => integer().nullable().references(Hives, #id)();
  IntColumn get siteId => integer().nullable().references(Sites, #id)();
  TextColumn get title => text().withLength(min: 1, max: 300)();
  TextColumn get description => text().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('open'))();
  DateTimeColumn get dueAt => dateTime().nullable()();
  IntColumn get recurDays => integer().nullable()();
  TextColumn get source =>
      text().withDefault(const Constant('manual'))();
  TextColumn get syncStatus =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get entityType => text()();
  IntColumn get entityId => integer()();
  TextColumn get operation => text()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  TextColumn get status =>
      text().withDefault(const Constant('pending'))();
  TextColumn get lastError => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();
}

// ---------- Database ----------

@DriftDatabase(tables: [Sites, Hives, Events, Tasks, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'bee_app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
