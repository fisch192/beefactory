import 'package:drift/drift.dart';

import '../../data/local/database.dart';
import '../../data/local/daos/sites_dao.dart';
import '../../data/local/daos/hives_dao.dart';
import '../models/site.dart';

abstract class SiteRepository {
  Future<List<SiteModel>> getAll();
  Stream<List<SiteModel>> watchAll();
  Future<SiteModel?> getById(int id);
  Future<int> create(SiteModel site);
  Future<void> update(SiteModel site);
  Future<void> delete(int id);
}

class SiteRepositoryImpl implements SiteRepository {
  final SitesDao _sitesDao;
  final HivesDao _hivesDao;

  SiteRepositoryImpl({
    required SitesDao sitesDao,
    required HivesDao hivesDao,
  })  : _sitesDao = sitesDao,
        _hivesDao = hivesDao;

  @override
  Future<List<SiteModel>> getAll() async {
    final sites = await _sitesDao.getAll();
    final models = <SiteModel>[];
    for (final s in sites) {
      final count = await _hivesDao.countBySiteId(s.id);
      models.add(_toModel(s, hiveCount: count));
    }
    return models;
  }

  @override
  Stream<List<SiteModel>> watchAll() {
    return _sitesDao.watchAll().asyncMap((sites) async {
      final models = <SiteModel>[];
      for (final s in sites) {
        final count = await _hivesDao.countBySiteId(s.id);
        models.add(_toModel(s, hiveCount: count));
      }
      return models;
    });
  }

  @override
  Future<SiteModel?> getById(int id) async {
    final site = await _sitesDao.getById(id);
    if (site == null) return null;
    final count = await _hivesDao.countBySiteId(id);
    return _toModel(site, hiveCount: count);
  }

  @override
  Future<int> create(SiteModel site) async {
    return _sitesDao.insertSite(SitesCompanion(
      name: Value(site.name),
      location: Value(site.location),
      latitude: Value(site.latitude),
      longitude: Value(site.longitude),
      elevation: Value(site.elevation),
      notes: Value(site.notes),
      syncStatus: const Value('pending'),
    ));
  }

  @override
  Future<void> update(SiteModel site) async {
    if (site.id == null) return;
    final existing = await _sitesDao.getById(site.id!);
    if (existing == null) return;

    await _sitesDao.updateSite(existing.copyWith(
      name: site.name,
      location: Value(site.location),
      latitude: Value(site.latitude),
      longitude: Value(site.longitude),
      elevation: Value(site.elevation),
      notes: Value(site.notes),
      syncStatus: 'pending',
      updatedAt: DateTime.now(),
    ));
  }

  @override
  Future<void> delete(int id) async {
    await _sitesDao.deleteSite(id);
  }

  SiteModel _toModel(Site s, {int hiveCount = 0}) {
    return SiteModel(
      id: s.id,
      serverId: s.serverId,
      name: s.name,
      location: s.location,
      latitude: s.latitude,
      longitude: s.longitude,
      elevation: s.elevation,
      notes: s.notes,
      syncStatus: s.syncStatus,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      hiveCount: hiveCount,
    );
  }
}
