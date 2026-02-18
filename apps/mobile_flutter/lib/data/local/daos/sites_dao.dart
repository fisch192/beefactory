import 'package:drift/drift.dart';
import '../database.dart';

part 'sites_dao.g.dart';

@DriftAccessor(tables: [Sites])
class SitesDao extends DatabaseAccessor<AppDatabase> with _$SitesDaoMixin {
  SitesDao(super.db);

  Future<List<Site>> getAll() => select(sites).get();

  Stream<List<Site>> watchAll() => select(sites).watch();

  Future<Site?> getById(int id) =>
      (select(sites)..where((s) => s.id.equals(id))).getSingleOrNull();

  Future<List<Site>> getPending() =>
      (select(sites)..where((s) => s.syncStatus.equals('pending'))).get();

  Future<int> insertSite(SitesCompanion entry) => into(sites).insert(entry);

  Future<bool> updateSite(Site entry) => update(sites).replace(entry);

  Future<int> deleteSite(int id) =>
      (delete(sites)..where((s) => s.id.equals(id))).go();

  Future<void> markSynced(int id, String serverId) {
    return (update(sites)..where((s) => s.id.equals(id))).write(
      SitesCompanion(
        serverId: Value(serverId),
        syncStatus: const Value('uploaded'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFailed(int id, String error) {
    return (update(sites)..where((s) => s.id.equals(id))).write(
      SitesCompanion(
        syncStatus: const Value('failed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
