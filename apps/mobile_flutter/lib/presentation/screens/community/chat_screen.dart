import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../data/remote/chat_socket.dart';
import '../../providers/channels_provider.dart';

const Color kHoneyAmber = Color(0xFFFFA000);
const Color kDarkSurface = Color(0xFF1A1A2E);
const Color kDarkCard = Color(0xFF232340);
const Color kDarkText = Color(0xFFE0E0E0);
const Color kDarkInput = Color(0xFF2D2D4A);
const Color kOwnBubble = Color(0xFF3A3A5C);

/// Real-time chat screen for a topic — Discord-like message thread.
class ChatScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final String channelName;

  const ChatScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.channelName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _focusNode = FocusNode();
  String? _replyToId;
  String? _replyToBody;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelsProvider>().loadMessages(widget.topicId);
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _scrollCtrl.dispose();
    _focusNode.dispose();
    _typingTimer?.cancel();
    // Leave the topic room
    context.read<ChannelsProvider>().leaveCurrentTopic();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage() {
    final body = _messageCtrl.text.trim();
    if (body.isEmpty) return;

    context.read<ChannelsProvider>().sendMessage(
          topicId: widget.topicId,
          body: body,
          replyToId: _replyToId,
        );

    _messageCtrl.clear();
    setState(() {
      _replyToId = null;
      _replyToBody = null;
    });
    _scrollToBottom();
  }

  void _onTyping() {
    _typingTimer?.cancel();
    context.read<ChannelsProvider>().sendTyping(widget.topicId);
    _typingTimer = Timer(const Duration(seconds: 2), () {});
  }

  void _setReply(String messageId, String body) {
    setState(() {
      _replyToId = messageId;
      _replyToBody = body.length > 60 ? '${body.substring(0, 60)}...' : body;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kDarkSurface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.topicTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            Text(
              '# ${widget.channelName}',
              style: TextStyle(fontSize: 12, color: kDarkText.withValues(alpha: 0.6)),
            ),
          ],
        ),
        backgroundColor: kDarkCard,
        foregroundColor: kDarkText,
        elevation: 0,
        actions: [
          // Connection indicator
          Consumer<ChatSocket>(
            builder: (_, socket, __) => Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                Icons.circle,
                size: 10,
                color: socket.connected ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChannelsProvider>(
              builder: (context, provider, _) {
                if (provider.messagesLoading && provider.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: kHoneyAmber),
                  );
                }

                if (provider.messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: kHoneyAmber.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          l.tr('start_conversation'),
                          style: TextStyle(color: kDarkText.withValues(alpha: 0.6)),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollCtrl.hasClients) {
                    _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
                  }
                });

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = provider.messages[index];
                    final prevMsg = index > 0 ? provider.messages[index - 1] : null;
                    final showHeader = prevMsg == null ||
                        prevMsg.userId != msg.userId ||
                        msg.createdAt.difference(prevMsg.createdAt).inMinutes > 5;

                    return _MessageBubble(
                      message: msg,
                      showHeader: showHeader,
                      onReply: () => _setReply(msg.id, msg.body),
                    );
                  },
                );
              },
            ),
          ),

          // Typing indicator
          Consumer<ChatSocket>(
            builder: (_, socket, __) {
              if (socket.typingUsers.isEmpty) return const SizedBox.shrink();
              final names = socket.typingUsers
                  .map((u) => u['displayName'] as String? ?? '?')
                  .join(', ');
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                alignment: Alignment.centerLeft,
                child: Text(
                  '$names ${l.tr("is_typing")}',
                  style: TextStyle(color: kDarkText.withValues(alpha: 0.5), fontSize: 12, fontStyle: FontStyle.italic),
                ),
              );
            },
          ),

          // Reply preview
          if (_replyToBody != null)
            Container(
              color: kDarkCard,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 24,
                    color: kHoneyAmber,
                    margin: const EdgeInsets.only(right: 8),
                  ),
                  Expanded(
                    child: Text(
                      _replyToBody!,
                      style: TextStyle(color: kDarkText.withValues(alpha: 0.7), fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: kDarkText.withValues(alpha: 0.5),
                    onPressed: () => setState(() {
                      _replyToId = null;
                      _replyToBody = null;
                    }),
                  ),
                ],
              ),
            ),

          // Message input
          Container(
            color: kDarkCard,
            padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + MediaQuery.of(context).padding.bottom),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: kDarkInput,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextField(
                      controller: _messageCtrl,
                      focusNode: _focusNode,
                      style: const TextStyle(color: kDarkText, fontSize: 15),
                      maxLines: 4,
                      minLines: 1,
                      onChanged: (_) => _onTyping(),
                      decoration: InputDecoration(
                        hintText: l.tr('type_message'),
                        hintStyle: TextStyle(color: kDarkText.withValues(alpha: 0.4)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: kHoneyAmber,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A single message bubble in the chat.
class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showHeader;
  final VoidCallback onReply;

  const _MessageBubble({
    required this.message,
    required this.showHeader,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: showHeader ? 12 : 2, bottom: 2),
      child: GestureDetector(
        onLongPress: onReply,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: kHoneyAmber.withValues(alpha: 0.2),
                      child: Text(
                        message.displayName.isNotEmpty
                            ? message.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: kHoneyAmber,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      message.displayName,
                      style: const TextStyle(
                        color: kHoneyAmber,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('HH:mm').format(message.createdAt),
                      style: TextStyle(
                        color: kDarkText.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

            // Reply reference
            if (message.replyTo != null)
              Container(
                margin: const EdgeInsets.only(left: 36, bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: kHoneyAmber.withValues(alpha: 0.5), width: 2)),
                  color: kDarkCard.withValues(alpha: 0.5),
                ),
                child: Text(
                  '${message.replyTo!.displayName}: ${message.replyTo!.body}',
                  style: TextStyle(color: kDarkText.withValues(alpha: 0.5), fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // Message body
            Padding(
              padding: const EdgeInsets.only(left: 36),
              child: Text(
                message.body,
                style: const TextStyle(color: kDarkText, fontSize: 15, height: 1.4),
              ),
            ),

            // Photo
            if (message.photoUrl != null)
              Padding(
                padding: const EdgeInsets.only(left: 36, top: 4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    message.photoUrl!,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
