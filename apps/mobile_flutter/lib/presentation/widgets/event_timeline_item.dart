import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../screens/community/community_feed_screen.dart';

/// Source of the event creation.
enum EventSource {
  manual,
  voice,
  community,
}

/// Reusable widget for displaying events in a timeline.
///
/// Each item shows an icon based on event type, a translated title, key payload
/// summary, timestamp, source indicator, and optional attachment thumbnails.
class EventTimelineItem extends StatelessWidget {
  /// Event type string from the backend, e.g. "INSPECTION", "VARROA_MEASUREMENT".
  final String eventType;

  /// Event payload map containing event-specific fields.
  final Map<String, dynamic> payload;

  /// When the event was created.
  final DateTime timestamp;

  /// How the event was created.
  final EventSource source;

  /// Optional attachment/photo URLs.
  final List<String> attachmentUrls;

  /// Optional tap handler.
  final VoidCallback? onTap;

  const EventTimelineItem({
    super.key,
    required this.eventType,
    required this.payload,
    required this.timestamp,
    this.source = EventSource.manual,
    this.attachmentUrls = const [],
    this.onTap,
  });

  // ---------------------------------------------------------------------------
  // Event type mapping
  // ---------------------------------------------------------------------------

  static IconData _iconForType(String type) {
    switch (type.toUpperCase()) {
      case 'INSPECTION':
        return Icons.search;
      case 'VARROA_MEASUREMENT':
        return Icons.bug_report;
      case 'TREATMENT':
        return Icons.medical_services;
      case 'FEEDING':
        return Icons.restaurant;
      case 'HARVEST':
        return Icons.emoji_nature;
      case 'NOTE':
        return Icons.edit_note;
      case 'TASK_CREATED':
        return Icons.task_alt;
      case 'COMMUNITY_IMPORT':
        return Icons.people;
      default:
        return Icons.event;
    }
  }

  static Color _colorForType(String type) {
    switch (type.toUpperCase()) {
      case 'INSPECTION':
        return Colors.indigo;
      case 'VARROA_MEASUREMENT':
        return Colors.deepOrange;
      case 'TREATMENT':
        return Colors.red;
      case 'FEEDING':
        return Colors.green;
      case 'HARVEST':
        return Colors.amber;
      case 'NOTE':
        return Colors.blueGrey;
      case 'TASK_CREATED':
        return Colors.teal;
      case 'COMMUNITY_IMPORT':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  static String _titleForType(String type) {
    switch (type.toUpperCase()) {
      case 'INSPECTION':
        return 'Durchsicht';
      case 'VARROA_MEASUREMENT':
        return 'Varroa-Messung';
      case 'TREATMENT':
        return 'Behandlung';
      case 'FEEDING':
        return 'Fütterung';
      case 'HARVEST':
        return 'Ernte';
      case 'NOTE':
        return 'Notiz';
      case 'TASK_CREATED':
        return 'Aufgabe';
      case 'COMMUNITY_IMPORT':
        return 'Community-Import';
      default:
        return type;
    }
  }

  /// Build a short summary string from the payload based on event type.
  String _buildSubtitle() {
    switch (eventType.toUpperCase()) {
      case 'INSPECTION':
        final queenSeen = payload['queen_seen'] ?? payload['queenSeen'];
        final mood = payload['mood'] ?? payload['temperament'];
        final parts = <String>[];
        if (queenSeen == true) parts.add('Königin gesehen');
        if (mood != null) parts.add('Stimmung: $mood');
        return parts.isNotEmpty ? parts.join(' | ') : 'Durchsicht durchgeführt';

      case 'VARROA_MEASUREMENT':
        final mites =
            payload['mites_count'] ?? payload['mitesCount'];
        final rate = payload['normalized_rate'] ??
            payload['normalizedRate'];
        final method = payload['method'];
        final parts = <String>[];
        if (mites != null) parts.add('$mites Milben');
        if (rate != null) {
          parts.add('${(rate as num).toStringAsFixed(1)}/Tag');
        }
        if (method != null) parts.add(_methodLabel(method as String));
        return parts.isNotEmpty ? parts.join(' | ') : 'Messung';

      case 'TREATMENT':
        final method = payload['method'] as String?;
        return method != null
            ? _methodLabel(method)
            : 'Behandlung durchgeführt';

      case 'FEEDING':
        final feedType = payload['feedType'] ?? payload['feed_type'];
        final amount = payload['amount'];
        final unit = payload['unit'];
        if (amount != null && feedType != null) {
          return '$amount${unit ?? ''} $feedType';
        }
        return feedType?.toString() ?? 'Fütterung';

      case 'HARVEST':
        final amount = payload['amount'] ?? payload['weight'];
        return amount != null ? '$amount kg Honig' : 'Ernte';

      case 'NOTE':
        final text =
            payload['text'] ?? payload['transcript'] ?? '';
        final str = text.toString();
        return str.length > 80 ? '${str.substring(0, 80)}...' : str;

      default:
        return payload.entries
            .take(2)
            .map((e) => '${e.key}: ${e.value}')
            .join(', ');
    }
  }

  String _methodLabel(String method) {
    switch (method) {
      case 'sticky_board':
        return 'Varroawindel';
      case 'alcohol_wash':
        return 'Alkoholwaschung';
      case 'sugar_roll':
        return 'Puderzucker';
      case 'co2':
        return 'CO2';
      case 'formic':
        return 'Ameisensäure';
      case 'oxalic':
        return 'Oxalsäure';
      case 'thymol':
        return 'Thymol';
      case 'biotech':
        return 'Biotechnisch';
      case 'brood_break':
        return 'Brutentnahme';
      default:
        return method;
    }
  }

  IconData _sourceIcon() {
    switch (source) {
      case EventSource.manual:
        return Icons.edit;
      case EventSource.voice:
        return Icons.mic;
      case EventSource.community:
        return Icons.people;
    }
  }

  String _sourceLabel() {
    switch (source) {
      case EventSource.manual:
        return 'Manuell';
      case EventSource.voice:
        return 'Sprache';
      case EventSource.community:
        return 'Community';
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(eventType);
    final icon = _iconForType(eventType);
    final title = _titleForType(eventType);
    final subtitle = _buildSubtitle();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + timestamp
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      Text(
                        _formatTimestamp(timestamp),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Subtitle (key payload summary)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Source indicator + attachment thumbnails
                  Row(
                    children: [
                      // Source
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_sourceIcon(),
                                size: 10, color: Colors.grey[600]),
                            const SizedBox(width: 3),
                            Text(
                              _sourceLabel(),
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Attachment thumbnails
                      if (attachmentUrls.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        ...attachmentUrls.take(3).map((url) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                width: 24,
                                height: 24,
                                color: kHoneyAmber.withValues(alpha: 0.1),
                                child: Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.image,
                                    size: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                        if (attachmentUrls.length > 3)
                          Text(
                            '+${attachmentUrls.length - 3}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min.';
    if (diff.inHours < 24) return 'vor ${diff.inHours} Std.';
    if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
    return DateFormat('dd.MM.yy').format(dt);
  }
}
