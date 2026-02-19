import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Real-time WebSocket client for chat using Socket.IO.
class ChatSocket extends ChangeNotifier {
  io.Socket? _socket;
  String? _currentTopicId;
  bool _connected = false;
  final List<Map<String, dynamic>> _typingUsers = [];

  bool get connected => _connected;
  List<Map<String, dynamic>> get typingUsers => List.unmodifiable(_typingUsers);

  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get messageStream => _messageController.stream;

  /// Connect to the chat server.
  void connect({required String serverUrl, required String token}) {
    _socket?.dispose();
    _socket = io.io(
      '$serverUrl/chat',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .setReconnectionAttempts(10)
          .build(),
    );

    _socket!.onConnect((_) {
      _connected = true;
      notifyListeners();
      // Rejoin current topic if reconnecting
      if (_currentTopicId != null) {
        _socket!.emit('join_topic', {'topicId': _currentTopicId});
      }
    });

    _socket!.onDisconnect((_) {
      _connected = false;
      notifyListeners();
    });

    _socket!.on('new_message', (data) {
      if (data is Map<String, dynamic>) {
        _messageController.add(data);
      }
    });

    _socket!.on('user_typing', (data) {
      if (data is Map<String, dynamic>) {
        final userId = data['userId'] as String?;
        if (userId != null && !_typingUsers.any((u) => u['userId'] == userId)) {
          _typingUsers.add(data);
          notifyListeners();
          // Auto-remove after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            _typingUsers.removeWhere((u) => u['userId'] == userId);
            notifyListeners();
          });
        }
      }
    });

    _socket!.on('user_stop_typing', (data) {
      if (data is Map<String, dynamic>) {
        _typingUsers.removeWhere((u) => u['userId'] == data['userId']);
        notifyListeners();
      }
    });

    _socket!.connect();
  }

  /// Join a topic room to receive real-time messages.
  void joinTopic(String topicId) {
    if (_currentTopicId != null) {
      _socket?.emit('leave_topic', {'topicId': _currentTopicId});
    }
    _currentTopicId = topicId;
    _typingUsers.clear();
    _socket?.emit('join_topic', {'topicId': topicId});
  }

  /// Leave the current topic room.
  void leaveTopic() {
    if (_currentTopicId != null) {
      _socket?.emit('leave_topic', {'topicId': _currentTopicId});
      _currentTopicId = null;
      _typingUsers.clear();
      notifyListeners();
    }
  }

  /// Send a message via WebSocket (preferred over REST for real-time).
  void sendMessage({
    required String topicId,
    required String body,
    String? photoUrl,
    String? replyToId,
  }) {
    _socket?.emit('send_message', {
      'topicId': topicId,
      'body': body,
      if (photoUrl != null) 'photoUrl': photoUrl,
      if (replyToId != null) 'replyToId': replyToId,
    });
  }

  /// Notify others that the user is typing.
  void sendTyping(String topicId) {
    _socket?.emit('typing', {'topicId': topicId});
  }

  /// Notify others that the user stopped typing.
  void sendStopTyping(String topicId) {
    _socket?.emit('stop_typing', {'topicId': topicId});
  }

  /// Disconnect and clean up.
  void disconnect() {
    _socket?.dispose();
    _socket = null;
    _connected = false;
    _currentTopicId = null;
    _typingUsers.clear();
  }

  @override
  void dispose() {
    disconnect();
    _messageController.close();
    super.dispose();
  }
}
