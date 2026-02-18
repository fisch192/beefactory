import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../domain/models/site.dart';
import '../../domain/repositories/site_repository.dart';

class SitesProvider extends ChangeNotifier {
  final SiteRepository _siteRepository;

  List<SiteModel> _sites = [];
  bool _isLoading = false;
  String? _error;
  StreamSubscription? _subscription;

  SitesProvider(this._siteRepository) {
    loadSites();
  }

  List<SiteModel> get sites => _sites;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadSites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sites = await _siteRepository.getAll();
      _isLoading = false;
      notifyListeners();

      // Start watching for changes
      _subscription?.cancel();
      _subscription = _siteRepository.watchAll().listen((sites) {
        _sites = sites;
        notifyListeners();
      });
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<SiteModel?> getSiteById(int id) async {
    return _siteRepository.getById(id);
  }

  Future<bool> createSite(SiteModel site) async {
    try {
      await _siteRepository.create(site);
      await loadSites();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSite(SiteModel site) async {
    try {
      await _siteRepository.update(site);
      await loadSites();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSite(int id) async {
    try {
      await _siteRepository.delete(id);
      await loadSites();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
