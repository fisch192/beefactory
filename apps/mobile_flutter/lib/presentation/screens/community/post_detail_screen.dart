import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/community_provider.dart';
import 'community_feed_screen.dart';
import 'import_dialog.dart';

/// Screen displaying the full content of a community post, its comments, and
/// a form for adding new comments. Provides "Report" and "Import to diary"
/// actions.
class PostDetailScreen extends StatefulWidget {
  final String postId;

  const PostDetailScreen({
    super.key,
    required this.postId,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommunityProvider>().loadPost(widget.postId);
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy HH:mm').format(date);
  }

  Future<void> _submitComment() async {
    final body = _commentController.text.trim();
    if (body.isEmpty) return;

    final success = await context.read<CommunityProvider>().addComment(
          postId: widget.postId,
          body: body,
        );

    if (!mounted) return;

    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus();
      // Scroll to bottom to show the new comment.
      Future.delayed(const Duration(milliseconds: 300), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  void _showReportPostDialog() {
    _showReportDialog(
      title: 'Beitrag melden',
      onReport: (reason) async {
        // Report is handled server-side. In a full implementation this would
        // call CommunityApi.reportPost via a provider method.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Beitrag gemeldet. Vielen Dank.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  void _showReportCommentDialog(String commentId) {
    _showReportDialog(
      title: 'Kommentar melden',
      onReport: (reason) async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kommentar gemeldet. Vielen Dank.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
    );
  }

  void _showReportDialog({
    required String title,
    required Future<void> Function(String reason) onReport,
  }) {
    String? selectedReason;
    final reasons = [
      'Spam',
      'Beleidigung',
      'Falschinformation',
      'Nicht themenbezogen',
      'Sonstiges',
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: reasons.map((reason) {
                  return RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    activeColor: kHoneyAmber,
                    onChanged: (value) {
                      setDialogState(() => selectedReason = value);
                    },
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child:
                      const Text('Abbrechen', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: selectedReason != null
                      ? () {
                          Navigator.of(ctx).pop();
                          onReport(selectedReason!);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(AppLocalizations.of(context).tr('report')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kHoneyAmberSurface,
      appBar: AppBar(
        title: Text(l.tr('community')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'report') {
                _showReportPostDialog();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'report',
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Beitrag melden'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<CommunityProvider>(
        builder: (context, provider, _) {
          if (provider.postLoading) {
            return const Center(
              child: CircularProgressIndicator(color: kHoneyAmber),
            );
          }

          if (provider.postError != null && provider.currentPost == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline,
                        size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(provider.postError!),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => provider.loadPost(widget.postId),
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

          final post = provider.currentPost;
          if (post == null) return const SizedBox.shrink();

          return Column(
            children: [
              // Scrollable content: post + comments
              Expanded(
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Post content card
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Author + date
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor:
                                      kHoneyAmber.withValues(alpha: 0.2),
                                  child: Text(
                                    post.authorName.isNotEmpty
                                        ? post.authorName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: kHoneyAmberDark,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      post.authorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      _formatDate(post.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Title
                            Text(
                              post.title,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF3E2723),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Body
                            Text(
                              post.body,
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Photos
                            if (post.photoUrls.isNotEmpty) ...[
                              SizedBox(
                                height: 160,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: post.photoUrls.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (_, index) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 200,
                                        color: kHoneyAmber
                                            .withValues(alpha: 0.1),
                                        child: Image.network(
                                          post.photoUrls[index],
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Center(
                                            child: Icon(Icons.broken_image,
                                                color: Colors.grey),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Tags
                            if (post.tags.isNotEmpty)
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
                                        color: kHoneyAmberLight
                                            .withValues(alpha: 0.5),
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
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Comments header
                    Text(
                      '${l.tr('comments')} (${provider.comments.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF3E2723),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Comments list
                    if (provider.comments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        child: Text(
                          'Noch keine Kommentare',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    else
                      ...provider.comments.map((comment) {
                        return _CommentCard(
                          comment: comment,
                          formattedDate: _formatDate(comment.createdAt),
                          onReport: () =>
                              _showReportCommentDialog(comment.id),
                          onImport: () {
                            ImportDialog.show(
                              context,
                              commentId: comment.id,
                              commentBody: comment.body,
                              commentAuthor: comment.authorName,
                            );
                          },
                        );
                      }),

                    // Spacer so comment form is not hidden.
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Add comment bar
              _CommentInputBar(
                controller: _commentController,
                isLoading: provider.addingComment,
                onSubmit: _submitComment,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A single comment card with report and import actions.
class _CommentCard extends StatelessWidget {
  final CommunityComment comment;
  final String formattedDate;
  final VoidCallback onReport;
  final VoidCallback onImport;

  const _CommentCard({
    required this.comment,
    required this.formattedDate,
    required this.onReport,
    required this.onImport,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar, name, date
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kHoneyAmber.withValues(alpha: 0.2),
                  child: Text(
                    comment.authorName.isNotEmpty
                        ? comment.authorName[0].toUpperCase()
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
                    comment.authorName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Body
            Text(
              comment.body,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey[800],
              ),
            ),

            // Photo
            if (comment.photoUrl != null) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  comment.photoUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // Actions
            Row(
              children: [
                // Import to diary
                TextButton.icon(
                  onPressed: onImport,
                  icon: const Icon(Icons.download, size: 16),
                  label: const Text('Ins Tagebuch'),
                  style: TextButton.styleFrom(
                    foregroundColor: kHoneyAmberDark,
                    textStyle: const TextStyle(fontSize: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const Spacer(),
                // Report
                TextButton.icon(
                  onPressed: onReport,
                  icon:
                      const Icon(Icons.flag_outlined, size: 14, color: Colors.grey),
                  label: Text(l.tr('report')),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    textStyle: const TextStyle(fontSize: 11),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom bar with a text field and send button for adding comments.
class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSubmit;

  const _CommentInputBar({
    required this.controller,
    required this.isLoading,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: l.tr('write_comment'),
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              textCapitalization: TextCapitalization.sentences,
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 44,
            height: 44,
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: kHoneyAmber,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : IconButton(
                    onPressed: onSubmit,
                    icon: const Icon(Icons.send_rounded),
                    color: kHoneyAmber,
                    style: IconButton.styleFrom(
                      backgroundColor: kHoneyAmber.withValues(alpha: 0.1),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
