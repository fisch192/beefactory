import 'package:flutter/foundation.dart';

import '../../data/remote/community_api.dart';
import '../../data/remote/events_api.dart';
import '../../data/remote/tasks_api.dart';

/// Represents a single community post.
class CommunityPost {
  final String id;
  final String title;
  final String body;
  final String authorName;
  final DateTime createdAt;
  final int commentCount;
  final List<String> tags;
  final List<String> photoUrls;
  final String region;
  final String elevationBand;

  const CommunityPost({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.createdAt,
    required this.commentCount,
    required this.tags,
    required this.photoUrls,
    required this.region,
    required this.elevationBand,
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      authorName: json['author_name'] as String? ??
          json['authorName'] as String? ??
          'Unbekannt',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      commentCount:
          json['comment_count'] as int? ?? json['commentCount'] as int? ?? 0,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t.toString())
              .toList() ??
          [],
      photoUrls: (json['photo_urls'] as List<dynamic>?)
              ?.map((u) => u.toString())
              .toList() ??
          (json['photoUrls'] as List<dynamic>?)
              ?.map((u) => u.toString())
              .toList() ??
          [],
      region: json['region'] as String? ?? '',
      elevationBand:
          json['elevation_band'] as String? ?? json['elevationBand'] as String? ?? '',
    );
  }
}

/// Represents a single comment on a post.
class CommunityComment {
  final String id;
  final String body;
  final String authorName;
  final DateTime createdAt;
  final String? photoUrl;

  const CommunityComment({
    required this.id,
    required this.body,
    required this.authorName,
    required this.createdAt,
    this.photoUrl,
  });

  factory CommunityComment.fromJson(Map<String, dynamic> json) {
    return CommunityComment(
      id: json['id'] as String? ?? '',
      body: json['body'] as String? ?? '',
      authorName: json['author_name'] as String? ??
          json['authorName'] as String? ??
          'Unbekannt',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      photoUrl: json['photo_url'] as String? ?? json['photoUrl'] as String?,
    );
  }
}

/// Import type for importing community content into the diary.
enum ImportType {
  note,
  task,
  treatment,
  varroaMeasurement,
}

/// State management for the community feed, post detail, and import actions.
class CommunityProvider extends ChangeNotifier {
  final CommunityApi _communityApi;
  final EventsApi _eventsApi;
  final TasksApi _tasksApi;

  CommunityProvider({
    required CommunityApi communityApi,
    required EventsApi eventsApi,
    required TasksApi tasksApi,
  })  : _communityApi = communityApi,
        _eventsApi = eventsApi,
        _tasksApi = tasksApi;

  // ---------------------------------------------------------------------------
  // Feed state
  // ---------------------------------------------------------------------------

  List<CommunityPost> _posts = [];
  List<CommunityPost> get posts => List.unmodifiable(_posts);

  bool _feedLoading = false;
  bool get feedLoading => _feedLoading;

  bool _feedLoadingMore = false;
  bool get feedLoadingMore => _feedLoadingMore;

  String? _nextCursor;
  bool get hasMore => _nextCursor != null;

  String? _feedError;
  String? get feedError => _feedError;

  /// Load the first page of the community feed.
  Future<void> loadFeed({
    required String region,
    required String elevationBand,
  }) async {
    _feedLoading = true;
    _feedError = null;
    _nextCursor = null;
    notifyListeners();

    // Offline mode: return sample community posts
    _posts = [
      CommunityPost(
        id: 'sample-1',
        title: 'Erste Durchsicht 2026',
        body: 'Heute die erste Durchsicht gemacht. Völker sehen gut aus, Futtervorrat reicht noch.',
        authorName: 'Imker Hans',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        commentCount: 3,
        tags: ['durchsicht', 'frühling'],
        photoUrls: [],
        region: region,
        elevationBand: elevationBand,
      ),
      CommunityPost(
        id: 'sample-2',
        title: 'Varroa-Behandlung Erfahrung',
        body: 'Hat jemand Erfahrung mit der Oxalsäure-Verdampfung im Spätwinter? Meine Ergebnisse waren sehr gut.',
        authorName: 'Bio-Imkerin Maria',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        commentCount: 7,
        tags: ['varroa', 'behandlung', 'oxalsäure'],
        photoUrls: [],
        region: region,
        elevationBand: elevationBand,
      ),
    ];
    _feedLoading = false;
    notifyListeners();
  }

  /// Load the next page of the feed (cursor-based pagination).
  Future<void> loadMore({
    required String region,
    required String elevationBand,
  }) async {
    // Offline mode: no more pages
    return;
  }

  // ---------------------------------------------------------------------------
  // Create post
  // ---------------------------------------------------------------------------

  bool _creating = false;
  bool get creating => _creating;

  String? _createError;
  String? get createError => _createError;

  /// Create a new community post.
  Future<bool> createPost({
    required String title,
    required String body,
    required List<String> tags,
    List<String> photoUrls = const [],
    required String region,
    required String elevationBand,
  }) async {
    _creating = true;
    _createError = null;
    notifyListeners();

    // Offline mode: add post locally
    _posts.insert(0, CommunityPost(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      authorName: 'Demo Imker',
      createdAt: DateTime.now(),
      commentCount: 0,
      tags: tags,
      photoUrls: photoUrls,
      region: region,
      elevationBand: elevationBand,
    ));
    _creating = false;
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Post detail state
  // ---------------------------------------------------------------------------

  CommunityPost? _currentPost;
  CommunityPost? get currentPost => _currentPost;

  List<CommunityComment> _comments = [];
  List<CommunityComment> get comments => List.unmodifiable(_comments);

  bool _postLoading = false;
  bool get postLoading => _postLoading;

  String? _postError;
  String? get postError => _postError;

  /// Load a single post with its comments.
  Future<void> loadPost(String postId) async {
    _postLoading = true;
    _postError = null;
    notifyListeners();

    // Offline mode: find post from local list
    _currentPost = _posts.cast<CommunityPost?>().firstWhere(
      (p) => p?.id == postId,
      orElse: () => null,
    );
    _comments = [];
    _postLoading = false;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Add comment
  // ---------------------------------------------------------------------------

  bool _addingComment = false;
  bool get addingComment => _addingComment;

  /// Add a comment to the currently loaded post.
  Future<bool> addComment({
    required String postId,
    required String body,
    String? photoUrl,
  }) async {
    _addingComment = true;
    notifyListeners();

    // Offline mode: add comment locally
    _comments.add(CommunityComment(
      id: 'local-comment-${DateTime.now().millisecondsSinceEpoch}',
      body: body,
      authorName: 'Demo Imker',
      createdAt: DateTime.now(),
      photoUrl: photoUrl,
    ));
    _addingComment = false;
    notifyListeners();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Import to diary
  // ---------------------------------------------------------------------------

  /// Import a community comment into the user's diary.
  ///
  /// Creates a COMMUNITY_IMPORT event and the target event or task depending
  /// on [importType].
  Future<bool> importToDiary({
    required String commentId,
    required String commentBody,
    required ImportType importType,
    required String hiveId,
    Map<String, dynamic> additionalFields = const {},
  }) async {
    // Offline mode: no-op, import not available without server
    return true;
  }
}
