import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/models/event.dart';
import '../../../domain/models/hive.dart';
import '../../../domain/repositories/hive_repository.dart';
import '../../../data/local/daos/events_dao.dart';
import '../../../data/local/database.dart' as db;
import '../../../l10n/app_localizations.dart';
import '../../../services/recommendation_engine.dart';
import '../../widgets/hive_illustration.dart';

const _kAmber = Color(0xFFFFA000);
const _kAmberDark = Color(0xFFFF8F00);
const _kSurface = Color(0xFFFFF8E1);

class HiveDetailScreen extends StatefulWidget {
  final int hiveId;

  const HiveDetailScreen({super.key, required this.hiveId});

  @override
  State<HiveDetailScreen> createState() => _HiveDetailScreenState();
}

class _HiveDetailScreenState extends State<HiveDetailScreen> {
  HiveModel? _hive;
  List<EventModel> _events = [];
  double? _lastVarroaRate;
  DateTime? _lastInspectionDate;
  List<Recommendation> _recommendations = [];
  VarroaTrend? _varroaTrend;
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
      final events = rawEvents.map(_toModel).toList();

      // Last varroa rate
      final varroa = events.where(
          (e) => e.type == EventType.varroaMeasurement);
      double? lastRate;
      if (varroa.isNotEmpty) {
        lastRate = (varroa.first.payload['normalized_rate'] as num?)
            ?.toDouble();
      }

      // Last inspection date
      final inspections =
          events.where((e) => e.type == EventType.inspection);
      DateTime? lastInspection =
          inspections.isNotEmpty ? inspections.first.occurredAtLocal : null;

      final recs = hive != null
          ? RecommendationEngine.analyze(events: events, hive: hive)
          : <Recommendation>[];

      final varroaEvents =
          events.where((e) => e.type == EventType.varroaMeasurement).toList();
      final trend = RecommendationEngine.analyzeTrend(varroaEvents);

      if (mounted) {
        setState(() {
          _hive = hive;
          _events = events;
          _lastVarroaRate = lastRate;
          _lastInspectionDate = lastInspection;
          _recommendations = recs;
          _varroaTrend = trend;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  EventModel _toModel(db.Event e) {
    Map<String, dynamic> payload = {};
    try {
      payload = jsonDecode(e.payload) as Map<String, dynamic>;
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
      payload: payload,
      source: e.source,
      syncStatus: e.syncStatus,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
    );
  }

  Color _queenColor(String? color) {
    switch (color?.toLowerCase()) {
      case 'white':
        return Colors.blueGrey.shade300;
      case 'yellow':
        return Colors.amber;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      default:
        return _kAmber;
    }
  }

  Color get _varroaStatusColor {
    final r = _lastVarroaRate;
    if (r == null) return Colors.grey;
    if (r < 1) return Colors.green;
    if (r <= 3) return Colors.orange;
    return Colors.red;
  }

  String get _varroaStatusLabel {
    final r = _lastVarroaRate;
    if (r == null) return 'Keine Daten';
    if (r < 1) return 'Gering (${r.toStringAsFixed(1)})';
    if (r <= 3) return 'Erhöht (${r.toStringAsFixed(1)})';
    return 'Kritisch (${r.toStringAsFixed(1)})';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_hive == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tr('hive'))),
        body: Center(child: Text(l.tr('hive_not_found'))),
      );
    }

    final qColor = _queenColor(_hive!.queenColor);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        color: _kAmber,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ── Animated Hero ────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 230,
              pinned: true,
              backgroundColor: const Color(0xFF1A0E00),
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: HiveIllustration(
                  queenColor: qColor,
                  varroaRate: _lastVarroaRate,
                  hiveNumber: _hive!.number,
                ),
                title: Text(
                  _hive!.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.edit_outlined,
                        color: Colors.white, size: 18),
                  ),
                  onPressed: () {},
                ),
              ],
            ),

            // ── Status chips ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  children: [
                    _StatusChip(
                      icon: Icons.bug_report,
                      label: _varroaStatusLabel,
                      color: _varroaStatusColor,
                    ),
                    const SizedBox(width: 8),
                    if (_lastInspectionDate != null)
                      _StatusChip(
                        icon: Icons.assignment_turned_in,
                        label: _relativeDate(_lastInspectionDate!),
                        color: Colors.blue,
                      ),
                    if (_hive!.queenYear != null) ...[
                      const SizedBox(width: 8),
                      _StatusChip(
                        icon: Icons.star_rounded,
                        label: '♛ ${_hive!.queenYear}',
                        color: qColor,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Varroa Trend Forecast ─────────────────────────────────────
            if (_varroaTrend != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: GestureDetector(
                    onTap: () async {
                      await context.push(
                          '/hives/${widget.hiveId}/varroa-history');
                      _loadData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _varroaTrend!.trendColor.withAlpha(18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _varroaTrend!.trendColor.withAlpha(60)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up,
                              color: _varroaTrend!.trendColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Varroa-Trend: ${_varroaTrend!.trendLabel}  '
                            '(aktuell ${_varroaTrend!.latestRate.toStringAsFixed(1)}/Tag)',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: _varroaTrend!.trendColor,
                            ),
                          ),
                          if (_varroaTrend!.daysToThreshold != null) ...[
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '⚠ ${_varroaTrend!.daysToThreshold}d',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red),
                              ),
                            ),
                          ],
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              size: 16,
                              color: _varroaTrend!.trendColor.withAlpha(140)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── 2×2 Action grid ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aktionen',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 2.5,
                      children: [
                        _ActionCard(
                          icon: Icons.assignment,
                          label: l.tr('inspect'),
                          color: Colors.blue,
                          onTap: () async {
                            await context
                                .push('/hives/${widget.hiveId}/inspect');
                            _loadData();
                          },
                        ),
                        _ActionCard(
                          icon: Icons.bug_report,
                          label: l.tr('varroa_measurement'),
                          color: Colors.deepOrange,
                          onTap: () async {
                            await context
                                .push('/hives/${widget.hiveId}/varroa');
                            _loadData();
                          },
                        ),
                        _ActionCard(
                          icon: Icons.medical_services,
                          label: l.tr('treatment'),
                          color: Colors.red,
                          onTap: () async {
                            await context
                                .push('/hives/${widget.hiveId}/treatment');
                            _loadData();
                          },
                        ),
                        _ActionCard(
                          icon: Icons.timeline,
                          label: l.tr('varroa_history'),
                          color: Colors.teal,
                          onTap: () async {
                            await context.push(
                                '/hives/${widget.hiveId}/varroa-history');
                            _loadData();
                          },
                        ),
                        _ActionCard(
                          icon: Icons.checklist_rtl,
                          label: 'Aufgaben',
                          color: Colors.indigo,
                          onTap: () async {
                            await context.push(
                                '/hives/${widget.hiveId}/tasks');
                            _loadData();
                          },
                        ),
                        _ActionCard(
                          icon: Icons.calculate,
                          label: 'Imkerrechner',
                          color: Colors.brown,
                          onTap: () =>
                              context.push('/tools/calculator'),
                        ),
                        _ActionCard(
                          icon: Icons.emoji_nature,
                          label: 'Ernte erfassen',
                          color: Colors.amber.shade700,
                          onTap: _showHarvestSheet,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── AI Insights ──────────────────────────────────────────────
            if (_recommendations.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome,
                              size: 14, color: _kAmber),
                          const SizedBox(width: 5),
                          Text(
                            'Smart Insights',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[600],
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._recommendations.map((rec) => _InsightCard(
                            rec: rec,
                            hiveId: widget.hiveId,
                            onAction: _loadData,
                          )),
                    ],
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // ── Timeline header ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Text(
                      l.tr('timeline'),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _kAmber.withAlpha(35),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_events.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _kAmberDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Events ───────────────────────────────────────────────────
            if (_events.isEmpty)
              SliverToBoxAdapter(
                child: _EmptyTimeline(l: l),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, i) => _EventCard(event: _events[i]),
                  childCount: _events.length,
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  void _showHarvestSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HarvestSheet(
        hiveId: widget.hiveId,
        onSaved: _loadData,
      ),
    );
  }

  String _relativeDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Heute';
    if (diff.inDays == 1) return 'Gestern';
    if (diff.inDays < 7) return 'vor ${diff.inDays}d';
    return DateFormat('dd.MM').format(dt);
  }
}

// ── Status Chip ──────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatusChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Card ──────────────────────────────────────────────────────────────
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      elevation: 1.5,
      shadowColor: color.withAlpha(40),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withAlpha(28),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Insight Card ─────────────────────────────────────────────────────────────

class _InsightCard extends StatelessWidget {
  final Recommendation rec;
  final int hiveId;
  final VoidCallback onAction;

  const _InsightCard({
    required this.rec,
    required this.hiveId,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rec.color.withAlpha(60)),
        boxShadow: [
          BoxShadow(
              color: rec.color.withAlpha(20),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: rec.color.withAlpha(30),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(rec.icon, color: rec.color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: rec.priority == RecommendationPriority.urgent
                        ? Colors.red.shade700
                        : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  rec.body,
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                if (rec.actionLabel != null && rec.actionRoute != null) ...[
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () async {
                      await context.push(
                          '/hives/$hiveId/${rec.actionRoute}');
                      onAction();
                    },
                    child: Text(
                      rec.actionLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: rec.color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Timeline ───────────────────────────────────────────────────────────
class _EmptyTimeline extends StatelessWidget {
  final AppLocalizations l;

  const _EmptyTimeline({required this.l});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAmber.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(Icons.timeline, size: 44, color: _kAmber.withAlpha(100)),
          const SizedBox(height: 10),
          Text(l.tr('no_events'),
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(l.tr('no_events_hint'),
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Event Card ───────────────────────────────────────────────────────────────
class _EventCard extends StatelessWidget {
  final EventModel event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('dd.MM.yy · HH:mm').format(event.occurredAtLocal);
    final (icon, color) = _typeStyle(event.type);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1))
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colour bar
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: color.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 16, color: color),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width:
                            MediaQuery.of(context).size.width - 16 * 2 - 4 - 40 - 14 * 2 - 10,
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _localLabel(event.type),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            Text(
                              dateStr,
                              style: TextStyle(
                                  color: Colors.grey[500], fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (event.payload.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: event.payload.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_fmtKey(e.key)}: ${e.value}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey[700]),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _typeStyle(EventType t) {
    switch (t) {
      case EventType.inspection:
        return (Icons.assignment, Colors.blue);
      case EventType.feeding:
        return (Icons.restaurant, Colors.orange);
      case EventType.treatment:
        return (Icons.medical_services, Colors.red);
      case EventType.varroaMeasurement:
        return (Icons.bug_report, Colors.deepOrange);
      case EventType.harvest:
        return (Icons.emoji_nature, Colors.amber);
      case EventType.swarm:
        return (Icons.cloud, Colors.purple);
      case EventType.queenEvent:
        return (Icons.star, Colors.pink);
      case EventType.loss:
        return (Icons.warning, Colors.red);
      case EventType.split:
        return (Icons.call_split, Colors.teal);
      case EventType.combine:
        return (Icons.merge, Colors.indigo);
      case EventType.note:
        return (Icons.note_alt, Colors.grey);
      case EventType.other:
        return (Icons.more_horiz, Colors.grey);
    }
  }

  String _localLabel(EventType t) {
    switch (t) {
      case EventType.inspection:
        return 'Durchsicht';
      case EventType.feeding:
        return 'Fütterung';
      case EventType.treatment:
        return 'Behandlung';
      case EventType.varroaMeasurement:
        return 'Varroa-Messung';
      case EventType.harvest:
        return 'Ernte';
      case EventType.swarm:
        return 'Schwarm';
      case EventType.queenEvent:
        return 'Königin';
      case EventType.loss:
        return 'Verlust';
      case EventType.split:
        return 'Ableger';
      case EventType.combine:
        return 'Vereinigung';
      case EventType.note:
        return 'Notiz';
      case EventType.other:
        return 'Sonstiges';
    }
  }

  String _fmtKey(String k) => k
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
      .join(' ');
}

// ── Harvest Sheet ─────────────────────────────────────────────────────────────

class _HarvestSheet extends StatefulWidget {
  final int hiveId;
  final VoidCallback onSaved;

  const _HarvestSheet({required this.hiveId, required this.onSaved});

  @override
  State<_HarvestSheet> createState() => _HarvestSheetState();
}

class _HarvestSheetState extends State<_HarvestSheet> {
  final _kgController = TextEditingController();
  final _notesController = TextEditingController();
  String _quality = 'gut';
  bool _saving = false;

  @override
  void dispose() {
    _kgController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final kg =
        double.tryParse(_kgController.text.trim().replaceAll(',', '.'));
    if (kg == null || kg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bitte eine gültige Menge (kg) eingeben.')));
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      await context.read<EventsDao>().insertEvent(db.EventsCompanion(
            clientEventId: Value(const Uuid().v4()),
            hiveId: Value(widget.hiveId),
            type: const Value('harvest'),
            occurredAtLocal: Value(now),
            occurredAtUtc: Value(now.toUtc()),
            payload: Value(jsonEncode({
              'kg': kg,
              'quality': _quality,
              if (_notesController.text.trim().isNotEmpty)
                'notes': _notesController.text.trim(),
            })),
            syncStatus: const Value('pending'),
          ));
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Icon(Icons.emoji_nature, color: _kAmber, size: 22),
              SizedBox(width: 8),
              Text(
                'Ernte erfassen',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _kgController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Honigmenge (kg)',
              prefixIcon: const Icon(Icons.monitor_weight_outlined),
              suffix: const Text('kg'),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            value: _quality,
            decoration: InputDecoration(
              labelText: 'Qualität',
              prefixIcon: const Icon(Icons.star_outline),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            items: const [
              DropdownMenuItem(value: 'gut', child: Text('Gut')),
              DropdownMenuItem(
                  value: 'sehr gut', child: Text('Sehr gut')),
              DropdownMenuItem(
                  value: 'exzellent', child: Text('Exzellent')),
            ],
            onChanged: (v) => setState(() => _quality = v ?? 'gut'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _notesController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Notizen (optional)',
              prefixIcon: const Icon(Icons.note_outlined),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: const Text('Ernte speichern',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kAmber,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
