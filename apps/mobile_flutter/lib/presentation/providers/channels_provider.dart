import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../data/remote/channels_api.dart';
import '../../data/remote/chat_socket.dart';

// ---------------------------------------------------------------------------
// Models
// ---------------------------------------------------------------------------

class Channel {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final int topicCount;

  const Channel({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.topicCount = 0,
  });

  factory Channel.fromJson(Map<String, dynamic> json) => Channel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        description: json['description'] as String?,
        icon: json['icon'] as String?,
        topicCount: (json['_count'] as Map<String, dynamic>?)?['topics'] as int? ?? 0,
      );
}

class Topic {
  final String id;
  final String channelId;
  final String title;
  final bool pinned;
  final bool locked;
  final String authorName;
  final int messageCount;
  final DateTime? lastMessageAt;
  final DateTime createdAt;

  const Topic({
    required this.id,
    required this.channelId,
    required this.title,
    this.pinned = false,
    this.locked = false,
    required this.authorName,
    this.messageCount = 0,
    this.lastMessageAt,
    required this.createdAt,
  });

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String? ?? '',
        channelId: json['channelId'] as String? ?? json['channel_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        pinned: json['pinned'] as bool? ?? false,
        locked: json['locked'] as bool? ?? false,
        authorName: (json['createdBy'] as Map<String, dynamic>?)?['displayName'] as String? ?? 'Unbekannt',
        messageCount: (json['_count'] as Map<String, dynamic>?)?['messages'] as int? ?? 0,
        lastMessageAt: json['lastMessageAt'] != null
            ? DateTime.tryParse(json['lastMessageAt'] as String)
            : json['last_message_at'] != null
                ? DateTime.tryParse(json['last_message_at'] as String)
                : null,
        createdAt: DateTime.tryParse(
                json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

class ChatMessage {
  final String id;
  final String topicId;
  final String userId;
  final String displayName;
  final String body;
  final String? photoUrl;
  final ChatMessage? replyTo;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.topicId,
    required this.userId,
    required this.displayName,
    required this.body,
    this.photoUrl,
    this.replyTo,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['id'] as String? ?? '',
        topicId: json['topicId'] as String? ?? json['topic_id'] as String? ?? '',
        userId: (json['user'] as Map<String, dynamic>?)?['id'] as String? ?? '',
        displayName: (json['user'] as Map<String, dynamic>?)?['displayName'] as String? ?? 'Unbekannt',
        body: json['body'] as String? ?? '',
        photoUrl: json['photoUrl'] as String? ?? json['photo_url'] as String?,
        replyTo: json['replyTo'] != null
            ? ChatMessage.fromJson(json['replyTo'] as Map<String, dynamic>)
            : null,
        createdAt: DateTime.tryParse(
                json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
            DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

class ChannelsProvider extends ChangeNotifier {
  final ChannelsApi _api;
  final ChatSocket _socket;

  ChannelsProvider({
    required ChannelsApi api,
    required ChatSocket socket,
  })  : _api = api,
        _socket = socket;

  StreamSubscription<Map<String, dynamic>>? _messageSub;

  // ---- Channels ----

  List<Channel> _channels = [];
  List<Channel> get channels => List.unmodifiable(_channels);
  bool _channelsLoading = false;
  bool get channelsLoading => _channelsLoading;
  String? _channelsError;
  String? get channelsError => _channelsError;

  Future<void> loadChannels() async {
    _channelsLoading = true;
    _channelsError = null;
    notifyListeners();
    try {
      final data = await _api.listChannels();
      _channels = data.map((j) => Channel.fromJson(j as Map<String, dynamic>)).toList();
    } catch (e) {
      _channelsError = e.toString();
      // Offline fallback — show default channels
      if (_channels.isEmpty) {
        _channels = [
          const Channel(id: 'default-general', name: 'Allgemein', description: 'Allgemeine Diskussionen', icon: '💬'),
          const Channel(id: 'default-varroa', name: 'Varroa', description: 'Varroa-Behandlung & Erfahrungen', icon: '🐛'),
          const Channel(id: 'default-anfaenger', name: 'Anfänger', description: 'Fragen für Neuimker', icon: '🌱'),
          const Channel(id: 'default-ernte', name: 'Ernte', description: 'Honigernte & Verarbeitung', icon: '🍯'),
        ];
      }
    }
    _channelsLoading = false;
    notifyListeners();
  }

  Future<bool> createChannel({required String name, String? description, String? icon}) async {
    try {
      final json = await _api.createChannel(name: name, description: description, icon: icon);
      _channels.add(Channel.fromJson(json));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---- Topics ----

  List<Topic> _topics = [];
  List<Topic> get topics => List.unmodifiable(_topics);
  bool _topicsLoading = false;
  bool get topicsLoading => _topicsLoading;
  String? _topicsCursor;
  bool get hasMoreTopics => _topicsCursor != null;

  Future<void> loadTopics(String channelId) async {
    _topicsLoading = true;
    _topicsCursor = null;
    _topics = [];
    notifyListeners();
    try {
      final res = await _api.listTopics(channelId);
      final items = (res['items'] as List<dynamic>?) ?? [];
      _topics = items.map((j) => Topic.fromJson(j as Map<String, dynamic>)).toList();
      _topicsCursor = res['nextCursor'] as String?;
    } catch (_) {
      // Offline: empty
    }
    _topicsLoading = false;
    notifyListeners();
  }

  Future<bool> createTopic({required String channelId, required String title}) async {
    try {
      final json = await _api.createTopic(channelId: channelId, title: title);
      _topics.insert(0, Topic.fromJson(json));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ---- Messages ----

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool _messagesLoading = false;
  bool get messagesLoading => _messagesLoading;
  String? _messagesCursor;
  bool get hasMoreMessages => _messagesCursor != null;

  Future<void> loadMessages(String topicId) async {
    _messagesLoading = true;
    _messagesCursor = null;
    _messages = [];
    notifyListeners();

    // Subscribe to real-time messages
    _messageSub?.cancel();
    _socket.joinTopic(topicId);
    _messageSub = _socket.messageStream.listen((data) {
      final msg = ChatMessage.fromJson(data);
      // Avoid duplicates
      if (!_messages.any((m) => m.id == msg.id)) {
        _messages.add(msg);
        notifyListeners();
      }
    });

    try {
      final res = await _api.getMessages(topicId);
      final items = (res['items'] as List<dynamic>?) ?? [];
      _messages = items.map((j) => ChatMessage.fromJson(j as Map<String, dynamic>)).toList();
      _messagesCursor = res['nextCursor'] as String?;
    } catch (_) {
      // Offline: empty
    }
    _messagesLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreMessages(String topicId) async {
    if (_messagesCursor == null) return;
    try {
      final res = await _api.getMessages(topicId, cursor: _messagesCursor);
      final items = (res['items'] as List<dynamic>?) ?? [];
      final older = items.map((j) => ChatMessage.fromJson(j as Map<String, dynamic>)).toList();
      _messages.insertAll(0, older);
      _messagesCursor = res['nextCursor'] as String?;
      notifyListeners();
    } catch (_) {}
  }

  void sendMessage({required String topicId, required String body, String? replyToId}) {
    _socket.sendMessage(topicId: topicId, body: body, replyToId: replyToId);
  }

  void sendTyping(String topicId) {
    _socket.sendTyping(topicId);
  }

  void leaveCurrentTopic() {
    _messageSub?.cancel();
    _socket.leaveTopic();
    _messages = [];
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    super.dispose();
  }
}
