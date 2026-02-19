import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/channels_provider.dart';
import 'chat_screen.dart';

const Color kHoneyAmber = Color(0xFFFFA000);
const Color kDarkSurface = Color(0xFF1A1A2E);
const Color kDarkCard = Color(0xFF232340);
const Color kDarkText = Color(0xFFE0E0E0);

/// Topic list inside a channel — like a Discord channel's thread list.
class TopicsScreen extends StatefulWidget {
  final String channelId;
  final String channelName;

  const TopicsScreen({
    super.key,
    required this.channelId,
    required this.channelName,
  });

  @override
  State<TopicsScreen> createState() => _TopicsScreenState();
}

class _TopicsScreenState extends State<TopicsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelsProvider>().loadTopics(widget.channelId);
    });
  }

  void _showCreateTopicDialog() {
    final titleCtrl = TextEditingController();
    final l = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kDarkCard,
        title: Text(l.tr('new_topic'), style: const TextStyle(color: kDarkText)),
        content: TextField(
          controller: titleCtrl,
          style: const TextStyle(color: kDarkText),
          decoration: InputDecoration(
            labelText: l.tr('topic_title'),
            labelStyle: TextStyle(color: kDarkText.withValues(alpha: 0.7)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: kHoneyAmber.withValues(alpha: 0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: kHoneyAmber),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.tr('cancel'), style: const TextStyle(color: kDarkText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kHoneyAmber),
            onPressed: () async {
              if (titleCtrl.text.trim().isEmpty) return;
              await context.read<ChannelsProvider>().createTopic(
                    channelId: widget.channelId,
                    title: titleCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l.tr('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'jetzt';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return DateFormat('dd.MM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kDarkSurface,
      appBar: AppBar(
        title: Row(
          children: [
            const Text('# ', style: TextStyle(color: kHoneyAmber, fontWeight: FontWeight.bold)),
            Text(widget.channelName),
          ],
        ),
        backgroundColor: kDarkCard,
        foregroundColor: kDarkText,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateTopicDialog,
        backgroundColor: kHoneyAmber,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(l.tr('new_topic'), style: const TextStyle(color: Colors.white)),
      ),
      body: Consumer<ChannelsProvider>(
        builder: (context, provider, _) {
          if (provider.topicsLoading && provider.topics.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kHoneyAmber),
            );
          }

          if (provider.topics.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.topic_outlined, size: 64, color: kHoneyAmber.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(l.tr('no_topics'), style: const TextStyle(color: kDarkText)),
                  const SizedBox(height: 8),
                  Text(
                    l.tr('create_first_topic'),
                    style: TextStyle(color: kDarkText.withValues(alpha: 0.6), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kHoneyAmber,
            onRefresh: () => provider.loadTopics(widget.channelId),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.topics.length,
              itemBuilder: (context, index) {
                final topic = provider.topics[index];
                return _TopicTile(
                  topic: topic,
                  lastActivity: _formatDate(topic.lastMessageAt ?? topic.createdAt),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          topicId: topic.id,
                          topicTitle: topic.title,
                          channelName: widget.channelName,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  final Topic topic;
  final String lastActivity;
  final VoidCallback onTap;

  const _TopicTile({
    required this.topic,
    required this.lastActivity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          children: [
            if (topic.pinned)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.push_pin, size: 16, color: kHoneyAmber.withValues(alpha: 0.8)),
              ),
            if (topic.locked)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.lock_outline, size: 16, color: kDarkText.withValues(alpha: 0.5)),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic.title,
                    style: const TextStyle(
                      color: kDarkText,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${topic.authorName} · ${topic.messageCount} messages',
                    style: TextStyle(color: kDarkText.withValues(alpha: 0.5), fontSize: 12),
                  ),
                ],
              ),
            ),
            if (lastActivity.isNotEmpty)
              Text(
                lastActivity,
                style: TextStyle(color: kDarkText.withValues(alpha: 0.4), fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}
