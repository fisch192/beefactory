import 'api_client.dart';

class SitesApi {
  final ApiClient _client;

  SitesApi(this._client);

  Future<List<dynamic>> listSites() async {
    final response = await _client.get('/sites');
    return (response['data'] as List<dynamic>?) ??
        (response['sites'] as List<dynamic>?) ??
        [];
  }

  Future<Map<String, dynamic>> getSite(String id) async {
    return _client.get('/sites/$id');
  }

  Future<Map<String, dynamic>> createSite(Map<String, dynamic> data) async {
    return _client.post('/sites', body: data);
  }

  Future<Map<String, dynamic>> updateSite(
      String id, Map<String, dynamic> data) async {
    return _client.put('/sites/$id', body: data);
  }

  Future<void> deleteSite(String id) async {
    await _client.delete('/sites/$id');
  }

  Future<List<dynamic>> listSitesSince(DateTime since) async {
    final response = await _client.get('/sites', queryParams: {
      'since': since.toUtc().toIso8601String(),
    });
    return (response['data'] as List<dynamic>?) ??
        (response['sites'] as List<dynamic>?) ??
        [];
  }
}
