import 'api_client.dart';

class EventsApi {
  final ApiClient _client;

  EventsApi(this._client);

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> data) async {
    return _client.post('/events', body: data);
  }

  Future<List<dynamic>> listEvents({
    String? hiveId,
    String? siteId,
    DateTime? since,
    String? type,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (hiveId != null) queryParams['hive_id'] = hiveId;
    if (siteId != null) queryParams['site_id'] = siteId;
    if (since != null) queryParams['since'] = since.toUtc().toIso8601String();
    if (type != null) queryParams['type'] = type;

    final response =
        await _client.get('/events', queryParams: queryParams);
    return (response['data'] as List<dynamic>?) ??
        (response['events'] as List<dynamic>?) ??
        [];
  }

  Future<Map<String, dynamic>> getEvent(String id) async {
    return _client.get('/events/$id');
  }

  Future<Map<String, dynamic>> updateEvent(
      String id, Map<String, dynamic> data) async {
    return _client.put('/events/$id', body: data);
  }

  Future<void> deleteEvent(String id) async {
    await _client.delete('/events/$id');
  }
}
