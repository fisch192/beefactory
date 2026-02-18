// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hives_dao.dart';

// ignore_for_file: type=lint
mixin _$HivesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  $HivesTable get hives => attachedDatabase.hives;
  HivesDaoManager get managers => HivesDaoManager(this);
}

class HivesDaoManager {
  final _$HivesDaoMixin _db;
  HivesDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
  $$HivesTableTableManager get hives =>
      $$HivesTableTableManager(_db.attachedDatabase, _db.hives);
}
