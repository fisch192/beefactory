import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/community_provider.dart';
import 'create_post_screen.dart';
import 'post_detail_screen.dart';

/// Honey amber theme colours used across community screens.
const Color kHoneyAmber = Color(0xFFFFA000);
const Color kHoneyAmberLight = Color(0xFFFFB300);
const Color kHoneyAmberDark = Color(0xFFFF8F00);
const Color kHoneyAmberSurface = Color(0xFFFFF8E1);

/// Community feed screen showing posts filtered by the user's region and
/// elevation band. Supports pull-to-refresh and cursor-based pagination
/// (infinite scroll).
class CommunityFeedScreen extends StatefulWidget {
  /// Region slug, e.g. "suedtirol". Loaded from SharedPreferences if null.
  final String? region;

  /// Elevation band: "low", "mid", or "high". Loaded from SharedPreferences if null.
  final String? elevationBand;

  const CommunityFeedScreen({
    super.key,
    this.region,
    this.elevationBand,
  });

  @override
  State<CommunityFeedScreen> createState() => _CommunityFeedScreenState();
}

class _CommunityFeedScreenState extends State<CommunityFeedScreen> {
  final ScrollController _scrollController = ScrollController();
  late String _region;
  late String _elevationBand;

  @override
  void initState() {
    super.initState();
    _region = _region ?? 'suedtirol';
    _elevationBand = _elevationBand ?? 'mid';

    _scrollController.addListener(_onScroll);

    // Load region/elevation from prefs if not provided, then load feed.
    _initAndLoadFeed();
  }

  Future<void> _initAndLoadFeed() async {
    if (_region == null || _elevationBand == null) {
      final prefs = await SharedPreferences.getInstance();
      _region = _region ?? prefs.getString('user_region') ?? 'suedtirol';
      _elevationBand =
          _elevationBand ?? prefs.getString('user_elevation_band') ?? 'mid';
    }
    _loadFeed();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = context.read<CommunityProvider>();
      if (!provider.feedLoadingMore && provider.hasMore) {
        provider.loadMore(
          region: _region,
          elevationBand: _elevationBand,
        );
      }
    }
  }

  Future<void> _loadFeed() async {
    await context.read<CommunityProvider>().loadFeed(
          region: _region,
          elevationBand: _elevationBand,
        );
  }

  String _formatDate(DateTime date, AppLocalizations l) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return l.tr('just_now');
    if (diff.inHours < 1) return l.tr('minutes_ago').replaceAll('{n}', '${diff.inMinutes}');
    if (diff.inHours < 24) return l.tr('hours_ago').replaceAll('{n}', '${diff.inHours}');
    if (diff.inDays < 7) return l.tr('days_ago').replaceAll('{n}', '${diff.inDays}');
    return DateFormat('dd.MM.yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kHoneyAmberSurface,
      appBar: AppBar(
        title: Text(l.tr('community_title')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          Chip(
            label: Text(
              '$_region / $_elevationBand',
              style: const TextStyle(fontSize: 11, color: Colors.white),
            ),
            backgroundColor: kHoneyAmberDark,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => CreatePostScreen(
                region: _region,
                elevationBand: _elevationBand,
              ),
            ),
          );
          if (created == true && mounted) {
            _loadFeed();
          }
        },
        icon: const Icon(Icons.edit),
        label: Text(l.tr('new_post')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          if (provider.feedLoading && provider.posts.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: kHoneyAmber),
            );
          }

          if (provider.feedError != null && provider.posts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off,
                        size: 64, color: kHoneyAmberDark),
                    const SizedBox(height: 16),
                    Text(
                      l.tr('error'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.feedError!,
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadFeed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kHoneyAmber,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(l.tr('retry')),
                    ),
                  ],
                ),
              ),
            );
          }

          if (provider.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined,
                      size: 64, color: kHoneyAmber.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text(l.tr('no_posts')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: kHoneyAmber,
            onRefresh: _loadFeed,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount:
                  provider.posts.length + (provider.feedLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index >= provider.posts.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(color: kHoneyAmber),
                    ),
                  );
                }

                final post = provider.posts[index];
                return _PostCard(
                  post: post,
                  formattedDate: _formatDate(post.createdAt, l),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PostDetailScreen(postId: post.id),
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

/// A single post card in the feed.
class _PostCard extends StatelessWidget {
  final CommunityPost post;
  final String formattedDate;
  final VoidCallback onTap;

  const _PostCard({
    required this.post,
    required this.formattedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                post.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3E2723),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Body preview
              Text(
                post.body,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Tags
              if (post.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: post.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: kHoneyAmberSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: kHoneyAmberLight.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '#$tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: kHoneyAmberDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Footer: author, date, comment count
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: kHoneyAmber.withValues(alpha: 0.2),
                    child: Text(
                      post.authorName.isNotEmpty
                          ? post.authorName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kHoneyAmberDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      post.authorName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.comment_outlined,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentCount}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
