import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/connectivity_service.dart';
import '../../data/sync/sync_engine.dart';

class SyncProvider extends ChangeNotifier {
  final SyncEngine _syncEngine;
  final ConnectivityService _connectivity;
  StreamSubscription<bool>? _connectivitySub;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  List<String> _errors = [];
  bool _isOnline = true;

  SyncProvider({
    required SyncEngine syncEngine,
    required ConnectivityService connectivity,
  })  : _syncEngine = syncEngine,
        _connectivity = connectivity {
    _isOnline = _connectivity.isOnline;
    _lastSyncTime = _syncEngine.lastSyncTime;

    // Listen for connectivity changes
    _connectivitySub = _connectivity.onConnectivityChanged.listen((online) {
      _isOnline = online;
      notifyListeners();

      if (online) {
        // Auto-sync when coming back online
        triggerSync();
      }
    });

    // Initial sync attempt
    triggerSync();
  }

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  List<String> get errors => _errors;
  bool get isOnline => _isOnline;

  Future<void> triggerSync() async {
    // Offline mode: skip server sync entirely
    return;
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
