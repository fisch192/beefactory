import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/remote/events_api.dart';
import '../../../l10n/app_localizations.dart';
import '../community/community_feed_screen.dart';
import 'varroa_measurement_screen.dart';

/// Represents a single timeline entry (either a measurement or a treatment).
class _TimelineEntry {
  final String id;
  final String type; // 'VARROA_MEASUREMENT' or 'TREATMENT'
  final DateTime date;
  final Map<String, dynamic> payload;

  const _TimelineEntry({
    required this.id,
    required this.type,
    required this.date,
    required this.payload,
  });
}

/// Screen showing a chronological timeline of varroa measurements and
/// treatments for a specific hive.
class VarroaHistoryScreen extends StatefulWidget {
  final String hiveId;
  final String? hiveName;

  const VarroaHistoryScreen({
    super.key,
    required this.hiveId,
    this.hiveName,
  });

  @override
  State<VarroaHistoryScreen> createState() => _VarroaHistoryScreenState();
}

class _VarroaHistoryScreenState extends State<VarroaHistoryScreen> {
  List<_TimelineEntry> _entries = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHistory());
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final eventsApi = context.read<EventsApi>();

      // Load varroa measurements.
      final measurements = await eventsApi.listEvents(
        hiveId: widget.hiveId,
        type: 'VARROA_MEASUREMENT',
        limit: 100,
      );

      // Load treatments.
      final treatments = await eventsApi.listEvents(
        hiveId: widget.hiveId,
        type: 'TREATMENT',
        limit: 100,
      );

      final entries = <_TimelineEntry>[];

      for (final m in measurements) {
        final data = m as Map<String, dynamic>;
        entries.add(_TimelineEntry(
          id: data['id'] as String? ?? '',
          type: 'VARROA_MEASUREMENT',
          date: DateTime.tryParse(
                  data['created_at'] as String? ?? '') ??
              DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
          payload: (data['payload'] as Map<String, dynamic>?) ?? data,
        ));
      }

      for (final t in treatments) {
        final data = t as Map<String, dynamic>;
        entries.add(_TimelineEntry(
          id: data['id'] as String? ?? '',
          type: 'TREATMENT',
          date: DateTime.tryParse(
                  data['created_at'] as String? ?? '') ??
              DateTime.tryParse(data['createdAt'] as String? ?? '') ??
              DateTime.now(),
          payload: (data['payload'] as Map<String, dynamic>?) ?? data,
        ));
      }

      // Sort newest first.
      entries.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Color _rateColor(double? rate) {
    if (rate == null) return Colors.grey;
    if (rate < 1) return Colors.green;
    if (rate <= 3) return Colors.orange;
    return Colors.red;
  }

  String _methodLabel(String? method, AppLocalizations l) {
    switch (method) {
      case 'sticky_board':
        return l.tr('varroa_board');
      case 'alcohol_wash':
        return l.tr('alcohol_wash');
      case 'sugar_roll':
        return l.tr('powdered_sugar');
      case 'co2':
        return 'CO2';
      case 'formic':
        return l.tr('formic_acid');
      case 'oxalic':
        return l.tr('oxalic_acid');
      case 'thymol':
        return l.tr('thymol');
      case 'biotech':
        return l.tr('biotechnical');
      case 'brood_break':
        return l.tr('brood_removal');
      default:
        return method ?? l.tr('unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kHoneyAmberSurface,
      appBar: AppBar(
        title: Text(widget.hiveName != null
            ? '${l.tr('varroa_history')} - ${widget.hiveName}'
            : l.tr('varroa_history')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l.tr('new_measurement'),
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => VarroaMeasurementScreen(
                    hiveId: widget.hiveId,
                    hiveName: widget.hiveName,
                  ),
                ),
              );
              if (result == true && mounted) _loadHistory();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: kHoneyAmber))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadHistory,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kHoneyAmber,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l.tr('retry')),
                        ),
                      ],
                    ),
                  ),
                )
              : _entries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timeline,
                              size: 64,
                              color:
                                  kHoneyAmber.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(l.tr('no_varroa_entries')),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      VarroaMeasurementScreen(
                                    hiveId: widget.hiveId,
                                    hiveName: widget.hiveName,
                                  ),
                                ),
                              );
                              if (result == true && mounted) {
                                _loadHistory();
                              }
                            },
                            icon: const Icon(Icons.add),
                            label: Text(l.tr('new_measurement')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kHoneyAmber,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      color: kHoneyAmber,
                      onRefresh: _loadHistory,
                      child: Column(
                        children: [
                          // Simple dot chart
                          _DotTimeline(
                            entries: _entries,
                            rateColor: _rateColor,
                          ),
                          const Divider(height: 1),
                          // Timeline list
                          Expanded(
                            child: ListView.builder(
                              padding:
                                  const EdgeInsets.fromLTRB(0, 8, 0, 80),
                              itemCount: _entries.length,
                              itemBuilder: (context, index) {
                                final entry = _entries[index];
                                return _TimelineListItem(
                                  entry: entry,
                                  methodLabel: (m) => _methodLabel(m, l),
                                  rateColor: _rateColor,
                                  isFirst: index == 0,
                                  isLast: index == _entries.length - 1,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
    );
  }
}

/// Simple horizontal dot timeline chart showing coloured dots for each entry.
class _DotTimeline extends StatelessWidget {
  final List<_TimelineEntry> entries;
  final Color Function(double?) rateColor;

  const _DotTimeline({
    required this.entries,
    required this.rateColor,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    // Show the last 20 entries, oldest first.
    final displayEntries = entries.length > 20
        ? entries.sublist(0, 20).reversed.toList()
        : entries.reversed.toList();

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.tr('varroa_history'),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3E2723),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: displayEntries.map((entry) {
                final isMeasurement =
                    entry.type == 'VARROA_MEASUREMENT';
                final rate =
                    (entry.payload['normalized_rate'] as num?)?.toDouble() ??
                        (entry.payload['normalizedRate'] as num?)
                            ?.toDouble();

                final color = isMeasurement
                    ? rateColor(rate)
                    : Colors.blue;

                // Bar height proportional to rate (max 5 = full height).
                final heightFraction = isMeasurement && rate != null
                    ? (rate / 5).clamp(0.1, 1.0)
                    : 0.5;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: heightFraction,
                            child: Container(
                              width: 8,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: isMeasurement ? 8 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: color,
                            shape: isMeasurement
                                ? BoxShape.circle
                                : BoxShape.rectangle,
                            borderRadius: isMeasurement
                                ? null
                                : BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single item in the timeline list.
class _TimelineListItem extends StatelessWidget {
  final _TimelineEntry entry;
  final String Function(String?) methodLabel;
  final Color Function(double?) rateColor;
  final bool isFirst;
  final bool isLast;

  const _TimelineListItem({
    required this.entry,
    required this.methodLabel,
    required this.rateColor,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    final isMeasurement = entry.type == 'VARROA_MEASUREMENT';
    final method = entry.payload['method'] as String?;
    final rate =
        (entry.payload['normalized_rate'] as num?)?.toDouble() ??
            (entry.payload['normalizedRate'] as num?)?.toDouble();
    final mitesCount = entry.payload['mites_count'] as int? ??
        entry.payload['mitesCount'] as int?;

    final color = isMeasurement ? rateColor(rate) : Colors.blue;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline connector
          SizedBox(
            width: 48,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(
                    isMeasurement
                        ? Icons.bug_report
                        : Icons.medical_services,
                    size: 10,
                    color: Colors.white,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          // Content card
          Expanded(
            child: Card(
              margin: const EdgeInsets.only(right: 16, bottom: 4, top: 4),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isMeasurement ? l.tr('measurement') : l.tr('treatment'),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd.MM.yyyy').format(entry.date),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      methodLabel(method),
                      style: const TextStyle(fontSize: 13),
                    ),
                    if (isMeasurement && mitesCount != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '$mitesCount Milben',
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (rate != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${rate.toStringAsFixed(1)}/Tag',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (!isMeasurement) ...[
                      const SizedBox(height: 4),
                      // Show date range for treatments.
                      Builder(
                        builder: (_) {
                          final startStr = entry.payload['start_date']
                                  as String? ??
                              entry.payload['startDate'] as String?;
                          final endStr = entry.payload['end_date']
                                  as String? ??
                              entry.payload['endDate'] as String?;
                          if (startStr == null) return const SizedBox.shrink();
                          final start = DateTime.tryParse(startStr);
                          final end = endStr != null
                              ? DateTime.tryParse(endStr)
                              : null;
                          if (start == null) return const SizedBox.shrink();
                          final fmt = DateFormat('dd.MM');
                          return Text(
                            end != null
                                ? '${fmt.format(start)} - ${fmt.format(end)}'
                                : 'Ab ${fmt.format(start)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
