import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/hive.dart';
import '../../../domain/models/event.dart';
import '../../../domain/repositories/hive_repository.dart';
import '../../../data/local/daos/events_dao.dart';
import '../../../data/local/database.dart' as db;
import '../../../l10n/app_localizations.dart';

class HiveDetailScreen extends StatefulWidget {
  final int hiveId;

  const HiveDetailScreen({super.key, required this.hiveId});

  @override
  State<HiveDetailScreen> createState() => _HiveDetailScreenState();
}

class _HiveDetailScreenState extends State<HiveDetailScreen> {
  HiveModel? _hive;
  List<EventModel> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final hive =
          await context.read<HiveRepository>().getById(widget.hiveId);
      final eventsDao = context.read<EventsDao>();
      final rawEvents = await eventsDao.getByHiveId(widget.hiveId);
      final events = rawEvents.map(_dbEventToModel).toList();

      if (mounted) {
        setState(() {
          _hive = hive;
          _events = events;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  EventModel _dbEventToModel(db.Event e) {
    Map<String, dynamic> payloadMap = {};
    try {
      payloadMap = jsonDecode(e.payload) as Map<String, dynamic>;
    } catch (_) {}

    return EventModel(
      id: e.id,
      serverId: e.serverId,
      clientEventId: e.clientEventId,
      hiveId: e.hiveId,
      siteId: e.siteId,
      type: EventType.fromString(e.type),
      occurredAtLocal: e.occurredAtLocal,
      occurredAtUtc: e.occurredAtUtc,
      payload: payloadMap,
      source: e.source,
      syncStatus: e.syncStatus,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tr('hive'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_hive == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tr('hive'))),
        body: Center(child: Text(l.tr('hive_not_found'))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_hive!.displayName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit not yet implemented
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // Hive info card
            SliverToBoxAdapter(
              child: _HiveInfoCard(hive: _hive!),
            ),

            // Quick actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await context
                              .push('/hives/${widget.hiveId}/inspect');
                          _loadData();
                        },
                        icon: const Icon(Icons.assignment),
                        label: Text(l.tr('inspect')),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Timeline header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  '${l.tr('timeline')} (${_events.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),

            // Events timeline
            if (_events.isEmpty)
              SliverToBoxAdapter(
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.timeline,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            l.tr('no_events'),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l.tr('no_events_hint'),
                            style: TextStyle(
                                color: Colors.grey[400], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = _events[index];
                    return _EventTimelineCard(event: event);
                  },
                  childCount: _events.length,
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        ),
      ),
    );
  }
}

class _HiveInfoCard extends StatelessWidget {
  final HiveModel hive;

  const _HiveInfoCard({required this.hive});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '#${hive.number}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hive.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (hive.queenYear != null)
                        Text(
                          '${l.tr('queen_year')}: ${hive.queenYear}${hive.queenColor != null ? ' (${hive.queenColor})' : ''}',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (hive.notes != null && hive.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                hive.notes!,
                style: TextStyle(color: Colors.grey[700], fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EventTimelineCard extends StatelessWidget {
  final EventModel event;

  const _EventTimelineCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMM d, yyyy HH:mm').format(event.occurredAtLocal);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _eventIcon(event.type),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    event.type.label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            if (event.payload.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: event.payload.entries.map((entry) {
                  return Chip(
                    label: Text(
                      '${_formatKey(entry.key)}: ${entry.value}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _eventIcon(EventType type) {
    IconData icon;
    Color color;
    switch (type) {
      case EventType.inspection:
        icon = Icons.assignment;
        color = Colors.blue;
        break;
      case EventType.feeding:
        icon = Icons.restaurant;
        color = Colors.orange;
        break;
      case EventType.treatment:
        icon = Icons.medical_services;
        color = Colors.red;
        break;
      case EventType.harvest:
        icon = Icons.emoji_nature;
        color = Colors.amber;
        break;
      case EventType.swarm:
        icon = Icons.cloud;
        color = Colors.purple;
        break;
      case EventType.queenEvent:
        icon = Icons.star;
        color = Colors.pink;
        break;
      case EventType.loss:
        icon = Icons.warning;
        color = Colors.red;
        break;
      case EventType.split:
        icon = Icons.call_split;
        color = Colors.teal;
        break;
      case EventType.combine:
        icon = Icons.merge;
        color = Colors.indigo;
        break;
      case EventType.note:
        icon = Icons.note;
        color = Colors.grey;
        break;
      case EventType.other:
        icon = Icons.more_horiz;
        color = Colors.grey;
        break;
    }

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isNotEmpty ? w[0].toUpperCase() + w.substring(1) : w)
        .join(' ');
  }
}
