import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants.dart';
import '../../core/network/connectivity_service.dart';
import '../local/database.dart';
import '../local/daos/sites_dao.dart';
import '../local/daos/hives_dao.dart';
import '../local/daos/events_dao.dart';
import '../local/daos/tasks_dao.dart';
import '../remote/sites_api.dart';
import '../remote/hives_api.dart';
import '../remote/events_api.dart';
import '../remote/tasks_api.dart';

class SyncEngine {
  final SitesDao _sitesDao;
  final HivesDao _hivesDao;
  final EventsDao _eventsDao;
  final TasksDao _tasksDao;
  final SitesApi _sitesApi;
  final HivesApi _hivesApi;
  final EventsApi _eventsApi;
  final TasksApi _tasksApi;
  final ConnectivityService _connectivity;
  final SharedPreferences _prefs;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  DateTime? _lastSyncTime;
  DateTime? get lastSyncTime => _lastSyncTime;

  String? _lastError;
  String? get lastError => _lastError;

  final List<String> _errors = [];
  List<String> get errors => List.unmodifiable(_errors);

  SyncEngine({
    required SitesDao sitesDao,
    required HivesDao hivesDao,
    required EventsDao eventsDao,
    required TasksDao tasksDao,
    required SitesApi sitesApi,
    required HivesApi hivesApi,
    required EventsApi eventsApi,
    required TasksApi tasksApi,
    required ConnectivityService connectivity,
    required SharedPreferences prefs,
  })  : _sitesDao = sitesDao,
        _hivesDao = hivesDao,
        _eventsDao = eventsDao,
        _tasksDao = tasksDao,
        _sitesApi = sitesApi,
        _hivesApi = hivesApi,
        _eventsApi = eventsApi,
        _tasksApi = tasksApi,
        _connectivity = connectivity,
        _prefs = prefs {
    _loadLastSyncTime();
  }

  void _loadLastSyncTime() {
    final ts = _prefs.getString(AppConstants.lastSyncKey);
    if (ts != null) {
      _lastSyncTime = DateTime.tryParse(ts);
    }
  }

  Future<void> _saveLastSyncTime() async {
    _lastSyncTime = DateTime.now().toUtc();
    await _prefs.setString(
        AppConstants.lastSyncKey, _lastSyncTime!.toIso8601String());
  }

  /// Run a full sync cycle: upload pending, then download new.
  Future<void> sync() async {
    if (_isSyncing) return;
    if (!_connectivity.isOnline) {
      _lastError = 'Offline';
      return;
    }

    _isSyncing = true;
    _errors.clear();
    _lastError = null;

    try {
      // Upload in dependency order
      await _uploadPendingSites();
      await _uploadPendingHives();
      await _uploadPendingEvents();
      await _uploadPendingTasks();

      // Download new data
      await _downloadSites();
      await _downloadHives();
      await _downloadEvents();
      await _downloadTasks();

      await _saveLastSyncTime();
    } catch (e) {
      _lastError = e.toString();
      _errors.add(e.toString());
    } finally {
      _isSyncing = false;
    }
  }

  // ---- Upload pending ----

  Future<void> _uploadPendingSites() async {
    final pending = await _sitesDao.getPending();
    for (final site in pending) {
      try {
        final data = {
          'name': site.name,
          'location': site.location,
          'latitude': site.latitude,
          'longitude': site.longitude,
          'elevation': site.elevation,
          'notes': site.notes,
        };

        if (site.serverId != null) {
          await _sitesApi.updateSite(site.serverId!, data);
          await _sitesDao.markSynced(site.id, site.serverId!);
        } else {
          final response = await _sitesApi.createSite(data);
          final serverId = response['id']?.toString() ??
              response['site']?['id']?.toString() ??
              '';
          await _sitesDao.markSynced(site.id, serverId);
        }
      } catch (e) {
        await _sitesDao.markFailed(site.id, e.toString());
        _errors.add('Site "${site.name}": $e');
      }
    }
  }

  Future<void> _uploadPendingHives() async {
    final pending = await _hivesDao.getPending();
    for (final hive in pending) {
      try {
        // Resolve site serverId
        final site = await _sitesDao.getById(hive.siteId);
        final siteServerId = site?.serverId;

        final data = {
          'site_id': siteServerId ?? hive.siteId.toString(),
          'number': hive.number,
          'name': hive.name,
          'queen_year': hive.queenYear,
          'queen_color': hive.queenColor,
          'queen_marked': hive.queenMarked,
          'notes': hive.notes,
        };

        if (hive.serverId != null) {
          await _hivesApi.updateHive(hive.serverId!, data);
          await _hivesDao.markSynced(hive.id, hive.serverId!);
        } else {
          final response = await _hivesApi.createHive(data);
          final serverId = response['id']?.toString() ??
              response['hive']?['id']?.toString() ??
              '';
          await _hivesDao.markSynced(hive.id, serverId);
        }
      } catch (e) {
        await _hivesDao.markFailed(hive.id);
        _errors.add('Hive #${hive.number}: $e');
      }
    }
  }

  Future<void> _uploadPendingEvents() async {
    final pending = await _eventsDao.getPending();
    for (final event in pending) {
      try {
        final data = {
          'client_event_id': event.clientEventId,
          'hive_id': event.hiveId?.toString(),
          'site_id': event.siteId?.toString(),
          'type': event.type,
          'occurred_at_local': event.occurredAtLocal.toIso8601String(),
          'occurred_at_utc': event.occurredAtUtc.toUtc().toIso8601String(),
          'payload': event.payload,
          'attachments': event.attachments,
          'source': event.source,
        };

        final response = await _eventsApi.createEvent(data);
        final serverId = response['id']?.toString() ??
            response['event']?['id']?.toString() ??
            '';
        await _eventsDao.markSynced(event.id, serverId);
      } catch (e) {
        await _eventsDao.markFailed(event.id);
        _errors.add('Event ${event.type}: $e');
      }
    }
  }

  Future<void> _uploadPendingTasks() async {
    final pending = await _tasksDao.getPending();
    for (final task in pending) {
      try {
        final data = {
          'client_task_id': task.clientTaskId,
          'hive_id': task.hiveId?.toString(),
          'site_id': task.siteId?.toString(),
          'title': task.title,
          'description': task.description,
          'status': task.status,
          'due_at': task.dueAt?.toUtc().toIso8601String(),
          'recur_days': task.recurDays,
          'source': task.source,
        };

        if (task.serverId != null) {
          await _tasksApi.updateTask(task.serverId!, data);
          await _tasksDao.markSynced(task.id, task.serverId!);
        } else {
          final response = await _tasksApi.createTask(data);
          final serverId = response['id']?.toString() ??
              response['task']?['id']?.toString() ??
              '';
          await _tasksDao.markSynced(task.id, serverId);
        }
      } catch (e) {
        await _tasksDao.markFailed(task.id);
        _errors.add('Task "${task.title}": $e');
      }
    }
  }

  // ---- Download new data ----

  Future<void> _downloadSites() async {
    try {
      final remoteSites = _lastSyncTime != null
          ? await _sitesApi.listSitesSince(_lastSyncTime!)
          : await _sitesApi.listSites();

      for (final raw in remoteSites) {
        final data = raw as Map<String, dynamic>;
        final serverId = data['id']?.toString() ?? '';

        // Check if we already have this site
        final existing = await _findSiteByServerId(serverId);
        if (existing != null) {
          await _sitesDao.updateSite(existing.copyWith(
            name: data['name'] as String? ?? existing.name,
            location: Value(data['location'] as String?),
            latitude: Value(data['latitude'] as double?),
            longitude: Value(data['longitude'] as double?),
            elevation: Value(data['elevation'] as double?),
            notes: Value(data['notes'] as String?),
            syncStatus: 'uploaded',
            updatedAt: DateTime.now(),
          ));
        } else {
          await _sitesDao.insertSite(SitesCompanion(
            serverId: Value(serverId),
            name: Value(data['name'] as String? ?? 'Unknown'),
            location: Value(data['location'] as String?),
            latitude: Value(data['latitude'] as double?),
            longitude: Value(data['longitude'] as double?),
            elevation: Value(data['elevation'] as double?),
            notes: Value(data['notes'] as String?),
            syncStatus: const Value('uploaded'),
          ));
        }
      }
    } catch (e) {
      _errors.add('Download sites: $e');
    }
  }

  Future<void> _downloadHives() async {
    try {
      final remoteHives = _lastSyncTime != null
          ? await _hivesApi.listHivesSince(_lastSyncTime!)
          : await _hivesApi.listHives();

      for (final raw in remoteHives) {
        final data = raw as Map<String, dynamic>;
        final serverId = data['id']?.toString() ?? '';

        final existing = await _findHiveByServerId(serverId);
        if (existing != null) {
          await _hivesDao.updateHive(existing.copyWith(
            number: data['number'] as int? ?? existing.number,
            name: Value(data['name'] as String?),
            queenYear: Value(data['queen_year'] as int?),
            queenColor: Value(data['queen_color'] as String?),
            queenMarked: data['queen_marked'] as bool? ?? existing.queenMarked,
            notes: Value(data['notes'] as String?),
            syncStatus: 'uploaded',
            updatedAt: DateTime.now(),
          ));
        } else {
          // Resolve local siteId from serverId
          final siteServerId = data['site_id']?.toString();
          final site = siteServerId != null
              ? await _findSiteByServerId(siteServerId)
              : null;
          final localSiteId = site?.id ?? 0;

          await _hivesDao.insertHive(HivesCompanion(
            serverId: Value(serverId),
            siteId: Value(localSiteId),
            number: Value(data['number'] as int? ?? 0),
            name: Value(data['name'] as String?),
            queenYear: Value(data['queen_year'] as int?),
            queenColor: Value(data['queen_color'] as String?),
            queenMarked: Value(data['queen_marked'] as bool? ?? false),
            notes: Value(data['notes'] as String?),
            syncStatus: const Value('uploaded'),
          ));
        }
      }
    } catch (e) {
      _errors.add('Download hives: $e');
    }
  }

  Future<void> _downloadEvents() async {
    try {
      final remoteEvents = await _eventsApi.listEvents(
        since: _lastSyncTime,
      );

      for (final raw in remoteEvents) {
        final data = raw as Map<String, dynamic>;
        final serverId = data['id']?.toString() ?? '';
        final clientEventId =
            data['client_event_id'] as String? ?? serverId;

        final existing = await _findEventByServerId(serverId);
        if (existing == null) {
          final hiveServerId = data['hive_id']?.toString();
          final siteServerId = data['site_id']?.toString();
          final hive = hiveServerId != null
              ? await _findHiveByServerId(hiveServerId)
              : null;
          final site = siteServerId != null
              ? await _findSiteByServerId(siteServerId)
              : null;

          final payload = data['payload'];
          final payloadStr =
              payload is String ? payload : jsonEncode(payload ?? {});

          await _eventsDao.insertEvent(EventsCompanion(
            serverId: Value(serverId),
            clientEventId: Value(clientEventId),
            hiveId: Value(hive?.id),
            siteId: Value(site?.id),
            type: Value(data['type'] as String? ?? 'unknown'),
            occurredAtLocal: Value(
              DateTime.tryParse(data['occurred_at_local'] as String? ?? '') ??
                  DateTime.now(),
            ),
            occurredAtUtc: Value(
              DateTime.tryParse(data['occurred_at_utc'] as String? ?? '') ??
                  DateTime.now().toUtc(),
            ),
            payload: Value(payloadStr),
            attachments: Value(data['attachments'] as String?),
            source: Value(data['source'] as String? ?? 'server'),
            syncStatus: const Value('uploaded'),
          ));
        }
      }
    } catch (e) {
      _errors.add('Download events: $e');
    }
  }

  Future<void> _downloadTasks() async {
    try {
      final remoteTasks = await _tasksApi.listTasks(
        since: _lastSyncTime,
      );

      for (final raw in remoteTasks) {
        final data = raw as Map<String, dynamic>;
        final serverId = data['id']?.toString() ?? '';
        final clientTaskId =
            data['client_task_id'] as String? ?? serverId;

        final existing = await _findTaskByServerId(serverId);
        if (existing == null) {
          final hiveServerId = data['hive_id']?.toString();
          final siteServerId = data['site_id']?.toString();
          final hive = hiveServerId != null
              ? await _findHiveByServerId(hiveServerId)
              : null;
          final site = siteServerId != null
              ? await _findSiteByServerId(siteServerId)
              : null;

          await _tasksDao.insertTask(TasksCompanion(
            serverId: Value(serverId),
            clientTaskId: Value(clientTaskId),
            hiveId: Value(hive?.id),
            siteId: Value(site?.id),
            title: Value(data['title'] as String? ?? ''),
            description: Value(data['description'] as String?),
            status: Value(data['status'] as String? ?? 'open'),
            dueAt: Value(
              data['due_at'] != null
                  ? DateTime.tryParse(data['due_at'] as String)
                  : null,
            ),
            recurDays: Value(data['recur_days'] as int?),
            source: Value(data['source'] as String? ?? 'server'),
            syncStatus: const Value('uploaded'),
          ));
        }
      }
    } catch (e) {
      _errors.add('Download tasks: $e');
    }
  }

  // ---- Helpers to find by serverId ----

  Future<Site?> _findSiteByServerId(String serverId) async {
    final all = await _sitesDao.getAll();
    try {
      return all.firstWhere((s) => s.serverId == serverId);
    } catch (_) {
      return null;
    }
  }

  Future<Hive?> _findHiveByServerId(String serverId) async {
    final all = await _hivesDao.getAll();
    try {
      return all.firstWhere((h) => h.serverId == serverId);
    } catch (_) {
      return null;
    }
  }

  Future<Event?> _findEventByServerId(String serverId) async {
    final all = await _eventsDao.getAll();
    try {
      return all.firstWhere((e) => e.serverId == serverId);
    } catch (_) {
      return null;
    }
  }

  Future<Task?> _findTaskByServerId(String serverId) async {
    final all = await _tasksDao.getAll();
    try {
      return all.firstWhere((t) => t.serverId == serverId);
    } catch (_) {
      return null;
    }
  }
}
