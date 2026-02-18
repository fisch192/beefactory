import 'api_client.dart';

class HivesApi {
  final ApiClient _client;

  HivesApi(this._client);

  Future<List<dynamic>> listHives({String? siteId}) async {
    final path = siteId != null ? '/sites/$siteId/hives' : '/hives';
    final response = await _client.get(path);
    return (response['data'] as List<dynamic>?) ??
        (response['hives'] as List<dynamic>?) ??
        [];
  }

  Future<Map<String, dynamic>> getHive(String id) async {
    return _client.get('/hives/$id');
  }

  Future<Map<String, dynamic>> createHive(Map<String, dynamic> data) async {
    return _client.post('/hives', body: data);
  }

  Future<Map<String, dynamic>> updateHive(
      String id, Map<String, dynamic> data) async {
    return _client.put('/hives/$id', body: data);
  }

  Future<void> deleteHive(String id) async {
    await _client.delete('/hives/$id');
  }

  Future<List<dynamic>> listHivesSince(DateTime since) async {
    final response = await _client.get('/hives', queryParams: {
      'since': since.toUtc().toIso8601String(),
    });
    return (response['data'] as List<dynamic>?) ??
        (response['hives'] as List<dynamic>?) ??
        [];
  }
}
