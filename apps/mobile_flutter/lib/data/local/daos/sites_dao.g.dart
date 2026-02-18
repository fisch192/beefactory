// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sites_dao.dart';

// ignore_for_file: type=lint
mixin _$SitesDaoMixin on DatabaseAccessor<AppDatabase> {
  $SitesTable get sites => attachedDatabase.sites;
  SitesDaoManager get managers => SitesDaoManager(this);
}

class SitesDaoManager {
  final _$SitesDaoMixin _db;
  SitesDaoManager(this._db);
  $$SitesTableTableManager get sites =>
      $$SitesTableTableManager(_db.attachedDatabase, _db.sites);
}
