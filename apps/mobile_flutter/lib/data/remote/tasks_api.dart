import 'api_client.dart';

class TasksApi {
  final ApiClient _client;

  TasksApi(this._client);

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    return _client.post('/tasks', body: data);
  }

  Future<List<dynamic>> listTasks({
    String? status,
    DateTime? since,
    int limit = 50,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };
    if (status != null) queryParams['status'] = status;
    if (since != null) queryParams['since'] = since.toUtc().toIso8601String();

    final response =
        await _client.get('/tasks', queryParams: queryParams);
    return (response['data'] as List<dynamic>?) ??
        (response['tasks'] as List<dynamic>?) ??
        [];
  }

  Future<Map<String, dynamic>> getTask(String id) async {
    return _client.get('/tasks/$id');
  }

  Future<Map<String, dynamic>> updateTask(
      String id, Map<String, dynamic> data) async {
    return _client.put('/tasks/$id', body: data);
  }

  Future<void> deleteTask(String id) async {
    await _client.delete('/tasks/$id');
  }
}
