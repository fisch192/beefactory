import 'package:drift/drift.dart';
import '../database.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  Future<List<Task>> getAll() => select(tasks).get();

  Stream<List<Task>> watchAll() => select(tasks).watch();

  Future<Task?> getById(int id) =>
      (select(tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<Task>> getByStatus(String status) =>
      (select(tasks)..where((t) => t.status.equals(status))).get();

  Future<List<Task>> getByHiveId(int hiveId) =>
      (select(tasks)
            ..where((t) => t.hiveId.equals(hiveId))
            ..orderBy([
              (t) => OrderingTerm(
                  expression: t.dueAt, mode: OrderingMode.asc),
              (t) => OrderingTerm(
                  expression: t.createdAt, mode: OrderingMode.desc),
            ]))
          .get();

  Stream<List<Task>> watchByStatus(String status) =>
      (select(tasks)..where((t) => t.status.equals(status))).watch();

  Future<List<Task>> getDueToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.dueAt.isBiggerOrEqualValue(startOfDay) &
              t.dueAt.isSmallerThanValue(endOfDay) &
              t.status.equals('open')))
        .get();
  }

  Stream<List<Task>> watchDueToday() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(tasks)
          ..where((t) =>
              t.dueAt.isBiggerOrEqualValue(startOfDay) &
              t.dueAt.isSmallerThanValue(endOfDay) &
              t.status.equals('open')))
        .watch();
  }

  Future<List<Task>> getPending() =>
      (select(tasks)..where((t) => t.syncStatus.equals('pending'))).get();

  Future<int> insertTask(TasksCompanion entry) => into(tasks).insert(entry);

  Future<bool> updateTask(Task entry) => update(tasks).replace(entry);

  Future<int> deleteTask(int id) =>
      (delete(tasks)..where((t) => t.id.equals(id))).go();

  Future<void> markSynced(int id, String serverId) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        serverId: Value(serverId),
        syncStatus: const Value('uploaded'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> markFailed(int id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        syncStatus: const Value('failed'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> completeTask(int id) {
    return (update(tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        status: const Value('done'),
        syncStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
}
