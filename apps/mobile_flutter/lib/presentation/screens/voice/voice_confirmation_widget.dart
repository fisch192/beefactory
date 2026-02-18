import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/voice/intent.dart';
import '../../../l10n/app_localizations.dart';
import '../community/community_feed_screen.dart';

/// Reusable widget that displays a parsed voice intent for confirmation.
///
/// Shows the intent type icon + label, hive/site reference, extracted fields
/// as key-value pairs, target date if applicable, and an edit button.
class VoiceConfirmationWidget extends StatelessWidget {
  final ParsedIntent intent;
  final Map<String, dynamic> extractedFields;
  final VoidCallback? onEdit;

  const VoiceConfirmationWidget({
    super.key,
    required this.intent,
    required this.extractedFields,
    this.onEdit,
  });

  IconData _iconForType(VoiceIntentType type) {
    switch (type) {
      case VoiceIntentType.note:
        return Icons.edit_note;
      case VoiceIntentType.varroaMeasurement:
        return Icons.bug_report;
      case VoiceIntentType.feeding:
        return Icons.restaurant;
      case VoiceIntentType.treatment:
        return Icons.medical_services;
      case VoiceIntentType.reminder:
        return Icons.notifications;
      case VoiceIntentType.siteTask:
        return Icons.task_alt;
      case VoiceIntentType.inspection:
        return Icons.search;
      case VoiceIntentType.unknown:
        return Icons.help_outline;
    }
  }

  String _labelForType(VoiceIntentType type, AppLocalizations l) {
    switch (type) {
      case VoiceIntentType.note:
        return l.tr('note');
      case VoiceIntentType.varroaMeasurement:
        return l.tr('varroa_measurement');
      case VoiceIntentType.feeding:
        return l.tr('feeding');
      case VoiceIntentType.treatment:
        return l.tr('treatment');
      case VoiceIntentType.reminder:
        return l.tr('reminder');
      case VoiceIntentType.siteTask:
        return l.tr('site_task');
      case VoiceIntentType.inspection:
        return l.tr('inspection');
      case VoiceIntentType.unknown:
        return l.tr('unknown');
    }
  }

  Color _colorForType(VoiceIntentType type) {
    switch (type) {
      case VoiceIntentType.note:
        return Colors.blueGrey;
      case VoiceIntentType.varroaMeasurement:
        return Colors.deepOrange;
      case VoiceIntentType.feeding:
        return Colors.green;
      case VoiceIntentType.treatment:
        return Colors.red;
      case VoiceIntentType.reminder:
        return Colors.blue;
      case VoiceIntentType.siteTask:
        return Colors.teal;
      case VoiceIntentType.inspection:
        return Colors.indigo;
      case VoiceIntentType.unknown:
        return Colors.grey;
    }
  }

  /// Friendly key labels for display.
  String _friendlyKey(String key, AppLocalizations l) {
    switch (key) {
      case 'transcript':
        return l.tr('transcript');
      case 'parsedHints':
        return l.tr('hints');
      case 'method':
        return l.tr('method');
      case 'durationHours':
        return l.tr('duration_hours');
      case 'mitesCount':
        return l.tr('mite_count');
      case 'normalizedRate':
        return 'Rate/Tag';
      case 'feedType':
        return l.tr('feed_type');
      case 'amount':
        return l.tr('amount');
      case 'unit':
        return l.tr('unit');
      case 'title':
        return l.tr('title');
      case 'dueAt':
        return l.tr('due_date');
      case 'notes':
        return l.tr('notes');
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    final typeColor = _colorForType(intent.type);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: icon, type label, edit button
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _iconForType(intent.type),
                    color: typeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _labelForType(intent.type, l),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: typeColor,
                    ),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit, size: 18),
                    color: kHoneyAmber,
                    tooltip: l.tr('edit'),
                    style: IconButton.styleFrom(
                      backgroundColor: kHoneyAmber.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Hive / Site reference
            if (intent.hiveRef != null || intent.siteRef != null) ...[
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (intent.hiveRef != null)
                    _ReferenceChip(
                      icon: Icons.hive,
                      label: '${l.tr('hive')} ${intent.hiveRef}',
                    ),
                  if (intent.siteRef != null)
                    _ReferenceChip(
                      icon: Icons.location_on,
                      label: '${l.tr('site')} ${intent.siteRef}',
                    ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Extracted fields
            ...extractedFields.entries.map((entry) {
              // Skip very long values in chip display; show them as text.
              final valueStr = entry.value.toString();
              final isLong = valueStr.length > 60;

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        _friendlyKey(entry.key, l),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: isLong
                          ? Text(
                              valueStr,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF3E2723)),
                            )
                          : Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                valueStr,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: typeColor,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              );
            }),

            // Target date
            if (intent.targetDate != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 100,
                    child: Text(
                      l.tr('date'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 12, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd.MM.yyyy')
                              .format(intent.targetDate!),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small chip widget displaying a hive or site reference.
class _ReferenceChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReferenceChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kHoneyAmber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kHoneyAmberLight.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: kHoneyAmberDark),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: kHoneyAmberDark,
            ),
          ),
        ],
      ),
    );
  }
}
