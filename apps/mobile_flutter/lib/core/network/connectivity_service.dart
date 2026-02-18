import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  final StreamController<bool> _onlineController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;

  ConnectivityService({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  bool get isOnline => _isOnline;
  Stream<bool> get onConnectivityChanged => _onlineController.stream;

  Future<void> initialize() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _resolveConnectivity(results);
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _isOnline = _resolveConnectivity(results);
      _onlineController.add(_isOnline);
    });
  }

  bool _resolveConnectivity(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = _resolveConnectivity(results);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _onlineController.close();
  }
}
