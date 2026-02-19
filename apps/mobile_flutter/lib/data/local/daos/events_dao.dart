import 'package:drift/drift.dart';
import '../database.dart';

part 'events_dao.g.dart';

@DriftAccessor(tables: [Events])
class EventsDao extends DatabaseAccessor<AppDatabase> with _$EventsDaoMixin {
  EventsDao(super.db);

  Future<List<Event>> getAll() => select(events).get();

  Future<Event?> getById(int id) =>
      (select(events)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<List<Event>> getByHiveId(int hiveId,
      {int limit = 50, int offset = 0}) {
    return (select(events)
          ..where((e) => e.hiveId.equals(hiveId))
          ..orderBy([
            (e) =>
                OrderingTerm(expression: e.occurredAtLocal, mode: OrderingMode.desc)
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Stream<List<Event>> watchByHiveId(int hiveId) {
    return (select(events)
          ..where((e) => e.hiveId.equals(hiveId))
          ..orderBy([
            (e) =>
                OrderingTerm(expression: e.occurredAtLocal, mode: OrderingMode.desc)
          ]))
        .watch();
  }

  Future<List<Event>> getByHiveIdAndTypes(int hiveId, List<String> types,
      {int limit = 100, int offset = 0}) {
    return (select(events)
          ..where(
              (e) => e.hiveId.equals(hiveId) & e.type.isIn(types))
          ..orderBy([
            (e) => OrderingTerm(
                expression: e.occurredAtLocal, mode: OrderingMode.desc)
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<List<Event>> getBySiteId(int siteId) =>
      (select(events)
            ..where((e) => e.siteId.equals(siteId))
            ..orderBy([
              (e) => OrderingTerm(
                  expression: e.occurredAtLocal, mode: OrderingMode.desc)
            ]))
          .get();

  Future<List<Event>> getPending() =>
      (select(events)..where((e) => e.syncStatus.equals('pending'))).get();

  Future<int> insertEvent(EventsCompanion entry) =>
      into(events).insert(entry);

  Future<bool> updateEvent(Event entry) => update(events).replace(entry);

  Future<int> deleteEvent(int id) =>
      (delete(events)..where((e) => e.id.equals(id))).go();

  Future<void> markSynced(int id, String serverId) {
    return (update(events)..where((e) => e.id.equals(id))).write(
      EventsCompanion(
        serverId: Value(serverId),
        syncStatus: const Value('uploaded'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFailed(int id) {
    return (update(events)..where((e) => e.id.equals(id))).write(
      EventsCompanion(
        syncStatus: const Value('failed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
