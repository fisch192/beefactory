import 'package:drift/drift.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/hives_dao.dart';
import '../models/hive.dart';

abstract class HiveRepository {
  Future<List<HiveModel>> getAll();
  Future<List<HiveModel>> getBySiteId(int siteId);
  Stream<List<HiveModel>> watchBySiteId(int siteId);
  Future<HiveModel?> getById(int id);
  Future<int> create(HiveModel hive);
  Future<void> update(HiveModel hive);
  Future<void> delete(int id);
}

class HiveRepositoryImpl implements HiveRepository {
  final HivesDao _hivesDao;

  HiveRepositoryImpl({required HivesDao hivesDao}) : _hivesDao = hivesDao;

  @override
  Future<List<HiveModel>> getAll() async {
    final hives = await _hivesDao.getAll();
    return hives.map(_toModel).toList();
  }

  @override
  Future<List<HiveModel>> getBySiteId(int siteId) async {
    final hives = await _hivesDao.getBySiteId(siteId);
    return hives.map(_toModel).toList();
  }

  @override
  Stream<List<HiveModel>> watchBySiteId(int siteId) {
    return _hivesDao.watchBySiteId(siteId).map(
          (hives) => hives.map(_toModel).toList(),
        );
  }

  @override
  Future<HiveModel?> getById(int id) async {
    final hive = await _hivesDao.getById(id);
    if (hive == null) return null;
    return _toModel(hive);
  }

  @override
  Future<int> create(HiveModel hive) async {
    return _hivesDao.insertHive(HivesCompanion(
      siteId: Value(hive.siteId),
      number: Value(hive.number),
      name: Value(hive.name),
      queenYear: Value(hive.queenYear),
      queenColor: Value(hive.queenColor),
      queenMarked: Value(hive.queenMarked),
      notes: Value(hive.notes),
      syncStatus: const Value('pending'),
    ));
  }

  @override
  Future<void> update(HiveModel hive) async {
    if (hive.id == null) return;
    final existing = await _hivesDao.getById(hive.id!);
    if (existing == null) return;

    await _hivesDao.updateHive(existing.copyWith(
      number: hive.number,
      name: Value(hive.name),
      queenYear: Value(hive.queenYear),
      queenColor: Value(hive.queenColor),
      queenMarked: hive.queenMarked,
      notes: Value(hive.notes),
      syncStatus: 'pending',
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> delete(int id) async {
    await _hivesDao.deleteHive(id);
  }

  HiveModel _toModel(Hive h) {
    return HiveModel(
      id: h.id,
      serverId: h.serverId,
      siteId: h.siteId,
      number: h.number,
      name: h.name,
      queenYear: h.queenYear,
      queenColor: h.queenColor,
      queenMarked: h.queenMarked,
      notes: h.notes,
      syncStatus: h.syncStatus,
      createdAt: h.createdAt,
      updatedAt: h.updatedAt,
    );
  }
}
