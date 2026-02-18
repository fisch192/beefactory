import 'api_client.dart';

/// API client for the community feed endpoints.
class CommunityApi {
  final ApiClient _client;

  CommunityApi(this._client);

  /// Fetch community feed posts filtered by region and elevation band.
  ///
  /// Uses cursor-based pagination. Pass [cursor] from the previous response
  /// to load the next page.
  Future<Map<String, dynamic>> getFeed({
    required String region,
    required String elevationBand,
    String? cursor,
    int limit = 20,
  }) async {
    final queryParams = <String, String>{
      'region': region,
      'elevation_band': elevationBand,
      'limit': limit.toString(),
    };
    if (cursor != null) queryParams['cursor'] = cursor;

    return _client.get('/community/posts', queryParams: queryParams);
  }

  /// Create a new community post.
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String body,
    required List<String> tags,
    List<String> photoUrls = const [],
    required String region,
    required String elevationBand,
  }) async {
    return _client.post('/community/posts', body: {
      'title': title,
      'body': body,
      'tags': tags,
      'photo_urls': photoUrls,
      'region': region,
      'elevation_band': elevationBand,
    });
  }

  /// Fetch a single post with its comments.
  Future<Map<String, dynamic>> getPost(String postId) async {
    return _client.get('/community/posts/$postId');
  }

  /// Add a comment to a post.
  Future<Map<String, dynamic>> addComment({
    required String postId,
    required String body,
    String? photoUrl,
  }) async {
    final data = <String, dynamic>{
      'body': body,
    };
    if (photoUrl != null) data['photo_url'] = photoUrl;
    return _client.post('/community/posts/$postId/comments', body: data);
  }

  /// Report a post for moderation.
  Future<Map<String, dynamic>> reportPost({
    required String postId,
    required String reason,
  }) async {
    return _client.post('/community/posts/$postId/report', body: {
      'reason': reason,
    });
  }

  /// Report a comment for moderation.
  Future<Map<String, dynamic>> reportComment({
    required String commentId,
    required String reason,
  }) async {
    return _client.post('/community/comments/$commentId/report', body: {
      'reason': reason,
    });
  }
}
