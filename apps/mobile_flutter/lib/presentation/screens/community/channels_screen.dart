import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants.dart';
import '../../../data/remote/chat_socket.dart';
import '../../../l10n/app_localizations.dart';
import '../../providers/channels_provider.dart';
import 'groups_screen.dart';
import 'topics_screen.dart';

const Color kHoneyAmber = Color(0xFFFFA000);
const Color kDarkSurface = Color(0xFF1A1A2E);
const Color kDarkCard = Color(0xFF232340);
const Color kDarkText = Color(0xFFE0E0E0);

// ── Community Tab (Channels + Groups) ────────────────────────────────────────

class CommunityTabScreen extends StatelessWidget {
  const CommunityTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: kDarkSurface,
        appBar: AppBar(
          title: const Text('Community'),
          backgroundColor: kDarkCard,
          foregroundColor: kDarkText,
          elevation: 0,
          bottom: TabBar(
            labelColor: kHoneyAmber,
            unselectedLabelColor: kDarkText.withAlpha(120),
            indicatorColor: kHoneyAmber,
            tabs: const [
              Tab(icon: Icon(Icons.forum_outlined), text: 'Kanäle'),
              Tab(icon: Icon(Icons.groups_outlined), text: 'Gruppen'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ChannelsTab(),
            GroupsScreen(),
          ],
        ),
      ),
    );
  }
}

/// Discord-like channel list screen (used as tab inside CommunityTabScreen).
class _ChannelsTab extends StatefulWidget {
  const _ChannelsTab();

  @override
  State<_ChannelsTab> createState() => _ChannelsTabState();
}

class _ChannelsTabState extends State<_ChannelsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChannelsProvider>().loadChannels();
      _connectSocket();
    });
  }

  Future<void> _connectSocket() async {
    final socket = context.read<ChatSocket>();
    if (socket.connected) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.jwtTokenKey);
    if (token != null && token.isNotEmpty) {
      socket.connect(serverUrl: AppConstants.wsBaseUrl, token: token);
    }
  }

  void _showCreateChannelDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final l = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kDarkCard,
        title: Text(l.tr('create_channel'), style: const TextStyle(color: kDarkText)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: kDarkText),
              decoration: InputDecoration(
                labelText: l.tr('channel_name'),
                labelStyle: TextStyle(color: kDarkText.withValues(alpha: 0.7)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kHoneyAmber.withValues(alpha: 0.5)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: kHoneyAmber),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              style: const TextStyle(color: kDarkText),
              decoration: InputDecoration(
                labelText: l.tr('description_hint'),
                labelStyle: TextStyle(color: kDarkText.withValues(alpha: 0.7)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: kHoneyAmber.withValues(alpha: 0.5)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: kHoneyAmber),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l.tr('cancel'), style: const TextStyle(color: kDarkText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kHoneyAmber),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              await context.read<ChannelsProvider>().createChannel(
                    name: nameCtrl.text.trim(),
                    description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(l.tr('save'), style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kDarkSurface,
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateChannelDialog,
        backgroundColor: kHoneyAmber,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<ChannelsProvider>(
        builder: (context, provider, _) {
          if (provider.channelsLoading && provider.channels.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kHoneyAmber),
            );
          }

          if (provider.channels.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 64, color: kHoneyAmber.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(l.tr('no_channels'), style: const TextStyle(color: kDarkText)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kHoneyAmber,
            onRefresh: provider.loadChannels,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: provider.channels.length,
              itemBuilder: (context, index) {
                final channel = provider.channels[index];
                return _ChannelTile(
                  channel: channel,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TopicsScreen(
                          channelId: channel.id,
                          channelName: channel.name,
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

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final VoidCallback onTap;

  const _ChannelTile({required this.channel, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: kHoneyAmber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  channel.icon ?? '#',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: const TextStyle(
                      color: kDarkText,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (channel.description != null && channel.description!.isNotEmpty)
                    Text(
                      channel.description!,
                      style: TextStyle(
                        color: kDarkText.withValues(alpha: 0.6),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: kHoneyAmber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${channel.topicCount}',
                style: const TextStyle(color: kHoneyAmber, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: kDarkText.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}
