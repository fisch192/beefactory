import 'api_client.dart';

/// REST API client for channels, topics, and messages.
class ChannelsApi {
  final ApiClient _client;

  ChannelsApi(this._client);

  // ---- Channels ----

  Future<List<dynamic>> listChannels() async {
    final res = await _client.get('/channels');
    return (res['data'] as List<dynamic>?) ?? [];
  }

  Future<Map<String, dynamic>> createChannel({
    required String name,
    String? description,
    String? icon,
  }) async {
    return _client.post('/channels', body: {
      'name': name,
      if (description != null) 'description': description,
      if (icon != null) 'icon': icon,
    });
  }

  Future<Map<String, dynamic>> deleteChannel(String channelId) async {
    return _client.delete('/channels/$channelId');
  }

  // ---- Topics ----

  Future<Map<String, dynamic>> listTopics(
    String channelId, {
    String? cursor,
    int limit = 30,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    return _client.get('/channels/$channelId/topics', queryParams: params);
  }

  Future<Map<String, dynamic>> createTopic({
    required String channelId,
    required String title,
  }) async {
    return _client.post('/channels/$channelId/topics', body: {
      'channelId': channelId,
      'title': title,
    });
  }

  // ---- Messages ----

  Future<Map<String, dynamic>> getMessages(
    String topicId, {
    String? cursor,
    int limit = 50,
  }) async {
    final params = <String, String>{'limit': limit.toString()};
    if (cursor != null) params['cursor'] = cursor;
    return _client.get('/channels/topics/$topicId/messages', queryParams: params);
  }

  Future<Map<String, dynamic>> sendMessage({
    required String topicId,
    required String body,
    String? photoUrl,
    String? replyToId,
  }) async {
    return _client.post('/channels/topics/$topicId/messages', body: {
      'topicId': topicId,
      'body': body,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (replyToId != null) 'replyToId': replyToId,
    });
  }

  Future<Map<String, dynamic>> deleteMessage(String messageId) async {
    return _client.delete('/channels/messages/$messageId');
  }
}
