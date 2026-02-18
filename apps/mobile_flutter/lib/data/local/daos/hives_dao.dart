import 'package:drift/drift.dart';
import '../database.dart';

part 'hives_dao.g.dart';

@DriftAccessor(tables: [Hives])
class HivesDao extends DatabaseAccessor<AppDatabase> with _$HivesDaoMixin {
  HivesDao(super.db);

  Future<List<Hive>> getAll() => select(hives).get();

  Stream<List<Hive>> watchAll() => select(hives).watch();

  Future<Hive?> getById(int id) =>
      (select(hives)..where((h) => h.id.equals(id))).getSingleOrNull();

  Future<List<Hive>> getBySiteId(int siteId) =>
      (select(hives)..where((h) => h.siteId.equals(siteId))).get();

  Stream<List<Hive>> watchBySiteId(int siteId) =>
      (select(hives)..where((h) => h.siteId.equals(siteId))).watch();

  Future<List<Hive>> getPending() =>
      (select(hives)..where((h) => h.syncStatus.equals('pending'))).get();

  Future<int> insertHive(HivesCompanion entry) => into(hives).insert(entry);

  Future<bool> updateHive(Hive entry) => update(hives).replace(entry);

  Future<int> deleteHive(int id) =>
      (delete(hives)..where((h) => h.id.equals(id))).go();

  Future<void> markSynced(int id, String serverId) {
    return (update(hives)..where((h) => h.id.equals(id))).write(
      HivesCompanion(
        serverId: Value(serverId),
        syncStatus: const Value('uploaded'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFailed(int id) {
    return (update(hives)..where((h) => h.id.equals(id))).write(
      HivesCompanion(
        syncStatus: const Value('failed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> countBySiteId(int siteId) async {
    final count = countAll();
    final query = selectOnly(hives)
      ..addColumns([count])
      ..where(hives.siteId.equals(siteId));
    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
