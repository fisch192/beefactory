import 'zone_config.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

/// Summary of a past event, used as input to the rule engine.
class EventSummary {
  final String type;
  final String? hiveId;
  final String siteId;
  final DateTime occurredAt;
  final Map<String, dynamic> payload;

  const EventSummary({
    required this.type,
    this.hiveId,
    required this.siteId,
    required this.occurredAt,
    this.payload = const {},
  });
}

/// Summary of a pending/active task.
class TaskSummary {
  final String id;
  final String title;
  final String status;
  final DateTime? dueAt;

  const TaskSummary({
    required this.id,
    required this.title,
    required this.status,
    this.dueAt,
  });
}

/// Everything the rule engine needs to decide which suggestions to produce.
class RuleContext {
  /// Region slug, e.g. "suedtirol".
  final String region;

  /// Elevation band: "low", "mid", or "high".
  final String elevationBand;

  /// ISO week-of-year (1-53).
  final int weekOfYear;

  /// The evaluation timestamp (used for "days since" calculations).
  final DateTime now;

  /// Events from roughly the last 30 days.
  final List<EventSummary> recentEvents;

  /// Currently pending tasks.
  final List<TaskSummary> pendingTasks;

  /// Optional list of hive IDs the user owns.  When provided the engine can
  /// emit per-hive suggestions even if no events exist for a hive yet.
  final List<String> hiveIds;

  const RuleContext({
    required this.region,
    required this.elevationBand,
    required this.weekOfYear,
    required this.now,
    this.recentEvents = const [],
    this.pendingTasks = const [],
    this.hiveIds = const [],
  });
}

// ---------------------------------------------------------------------------
// Suggestion
// ---------------------------------------------------------------------------

enum SuggestionPriority { low, medium, high, urgent }

class Suggestion {
  /// Deterministic identifier so the same suggestion is not shown twice.
  /// Constructed as a hash of rule name + scope (hive/site) + week.
  final String id;

  final String title;
  final String description;
  final SuggestionPriority priority;
  final String? hiveId;
  final String? siteId;

  /// If set, the UI can offer a quick-action to log this event type.
  final String? suggestedEventType;

  /// Whether the suggestion can be converted into a task.
  final bool canCreateTask;

  const Suggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.hiveId,
    this.siteId,
    this.suggestedEventType,
    this.canCreateTask = true,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Suggestion &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Suggestion(id=$id, title=$title, priority=$priority, '
      'hive=$hiveId, site=$siteId)';
}

// ---------------------------------------------------------------------------
// Rule engine
// ---------------------------------------------------------------------------

class RuleEngine {
  const RuleEngine();

  /// Evaluate all rules against [context] and return a deduplicated, priority-
  /// sorted list of suggestions.
  List<Suggestion> evaluate(RuleContext context) {
    final config = ZoneConfig.lookup(context.region, context.elevationBand);
    if (config == null) return [];

    final suggestions = <Suggestion>[];

    // Collect all known hive IDs from events + explicit list.
    final allHiveIds = <String>{
      ...context.hiveIds,
      ...context.recentEvents
          .where((e) => e.hiveId != null)
          .map((e) => e.hiveId!),
    };

    // Collect all known site IDs from events.
    final allSiteIds = <String>{
      ...context.recentEvents.map((e) => e.siteId),
    };

    for (final hiveId in allHiveIds) {
      final hiveEvents = context.recentEvents
          .where((e) => e.hiveId == hiveId)
          .toList();

      _springInspection(context, config, hiveId, hiveEvents, suggestions);
      _varroaMeasurement(context, config, hiveId, hiveEvents, suggestions);
      _postTreatmentFollowup(context, config, hiveId, hiveEvents, suggestions);
      _swarmControlInspection(context, config, hiveId, hiveEvents, suggestions);
    }

    // Site-level rules (not per-hive).
    for (final siteId in allSiteIds) {
      final siteEvents = context.recentEvents
          .where((e) => e.siteId == siteId)
          .toList();

      _feedingCheck(context, config, siteId, siteEvents, suggestions);
      _harvestReadiness(context, config, siteId, siteEvents, suggestions);
    }

    // If we have no site IDs at all, still run site-level rules with a
    // generic scope so the user gets at least something.
    if (allSiteIds.isEmpty) {
      _feedingCheck(context, config, '_all', [], suggestions);
      _harvestReadiness(context, config, '_all', [], suggestions);
    }

    // Deduplicate by id (first wins) and sort by priority descending.
    final seen = <String>{};
    final unique = <Suggestion>[];
    for (final s in suggestions) {
      if (seen.add(s.id)) unique.add(s);
    }

    unique.sort((a, b) =>
        b.priority.index.compareTo(a.priority.index));
    return unique;
  }

  // ---- individual rule implementations ------------------------------------

  /// Rule 1: Spring inspection reminder.
  /// Condition: spring window, no INSPECTION for this hive in last 10 days.
  void _springInspection(
    RuleContext ctx,
    SeasonConfig config,
    String hiveId,
    List<EventSummary> hiveEvents,
    List<Suggestion> out,
  ) {
    if (!config.isSpring(ctx.weekOfYear)) return;

    final tenDaysAgo = ctx.now.subtract(const Duration(days: 10));
    final hasRecent = hiveEvents.any((e) =>
        e.type == 'INSPECTION' && e.occurredAt.isAfter(tenDaysAgo));
    if (hasRecent) return;

    out.add(Suggestion(
      id: _makeId('spring_inspection', hiveId, ctx.weekOfYear),
      title: 'Time for spring inspection',
      description:
          'No inspection recorded for this hive in the last 10 days. '
          'Spring is the time to assess colony strength, check for the '
          'queen, and evaluate food stores.',
      priority: SuggestionPriority.high,
      hiveId: hiveId,
      suggestedEventType: 'INSPECTION',
    ));
  }

  /// Rule 2: Varroa measurement reminder.
  /// Condition: varroa window (weeks 25-40), no VARROA_MEASUREMENT in last
  /// 14 days for this hive.
  void _varroaMeasurement(
    RuleContext ctx,
    SeasonConfig config,
    String hiveId,
    List<EventSummary> hiveEvents,
    List<Suggestion> out,
  ) {
    if (!config.isVarroaWindow(ctx.weekOfYear)) return;

    final fourteenDaysAgo = ctx.now.subtract(const Duration(days: 14));
    final hasRecent = hiveEvents.any((e) =>
        e.type == 'VARROA_MEASUREMENT' &&
        e.occurredAt.isAfter(fourteenDaysAgo));
    if (hasRecent) return;

    out.add(Suggestion(
      id: _makeId('varroa_check', hiveId, ctx.weekOfYear),
      title: 'Varroa check overdue',
      description:
          'No varroa measurement recorded for this hive in the last '
          '14 days. Regular monitoring is essential to keep mite levels '
          'under the damage threshold.',
      priority: SuggestionPriority.high,
      hiveId: hiveId,
      suggestedEventType: 'VARROA_MEASUREMENT',
    ));
  }

  /// Rule 3: Post-treatment follow-up.
  /// Condition: TREATMENT event 7-21 days ago, no VARROA_MEASUREMENT after it.
  void _postTreatmentFollowup(
    RuleContext ctx,
    SeasonConfig config,
    String hiveId,
    List<EventSummary> hiveEvents,
    List<Suggestion> out,
  ) {
    final sevenDaysAgo = ctx.now.subtract(const Duration(days: 7));
    final twentyOneDaysAgo = ctx.now.subtract(const Duration(days: 21));

    final treatmentEvents = hiveEvents.where((e) =>
        e.type == 'TREATMENT' &&
        e.occurredAt.isAfter(twentyOneDaysAgo) &&
        e.occurredAt.isBefore(sevenDaysAgo));

    for (final treatment in treatmentEvents) {
      final hasFollowup = hiveEvents.any((e) =>
          e.type == 'VARROA_MEASUREMENT' &&
          e.occurredAt.isAfter(treatment.occurredAt));
      if (hasFollowup) continue;

      out.add(Suggestion(
        id: _makeId('post_treatment_followup', hiveId, ctx.weekOfYear),
        title: 'Follow-up varroa measurement after treatment',
        description:
            'A treatment was applied recently but no follow-up varroa '
            'measurement has been recorded. Measure mite levels to '
            'verify treatment efficacy.',
        priority: SuggestionPriority.medium,
        hiveId: hiveId,
        suggestedEventType: 'VARROA_MEASUREMENT',
      ));
      // Only one suggestion per hive regardless of how many treatments.
      break;
    }
  }

  /// Rule 4: Feeding check in autumn (site-level).
  /// Condition: autumn window, no FEEDING event for this site in last 21 days.
  void _feedingCheck(
    RuleContext ctx,
    SeasonConfig config,
    String siteId,
    List<EventSummary> siteEvents,
    List<Suggestion> out,
  ) {
    if (!config.isAutumn(ctx.weekOfYear)) return;

    final twentyOneDaysAgo = ctx.now.subtract(const Duration(days: 21));
    final hasRecent = siteEvents.any((e) =>
        e.type == 'FEEDING' && e.occurredAt.isAfter(twentyOneDaysAgo));
    if (hasRecent) return;

    out.add(Suggestion(
      id: _makeId('autumn_feeding', siteId, ctx.weekOfYear),
      title: 'Check winter stores / feeding needed?',
      description:
          'No feeding event recorded in the last 21 days. Ensure '
          'colonies have sufficient stores for winter. Weigh hives or '
          'check frames to decide.',
      priority: SuggestionPriority.medium,
      siteId: siteId == '_all' ? null : siteId,
      suggestedEventType: 'FEEDING',
    ));
  }

  /// Rule 5: Weekly swarm-control inspection.
  /// Condition: swarm season, no INSPECTION in last 7 days.
  void _swarmControlInspection(
    RuleContext ctx,
    SeasonConfig config,
    String hiveId,
    List<EventSummary> hiveEvents,
    List<Suggestion> out,
  ) {
    if (!config.isSwarmSeason(ctx.weekOfYear)) return;

    final sevenDaysAgo = ctx.now.subtract(const Duration(days: 7));
    final hasRecent = hiveEvents.any((e) =>
        e.type == 'INSPECTION' && e.occurredAt.isAfter(sevenDaysAgo));
    if (hasRecent) return;

    out.add(Suggestion(
      id: _makeId('swarm_inspection', hiveId, ctx.weekOfYear),
      title: 'Swarm control inspection due',
      description:
          'During swarm season, colonies should be inspected every '
          '7 days to detect and manage queen cells before swarming.',
      priority: SuggestionPriority.urgent,
      hiveId: hiveId,
      suggestedEventType: 'INSPECTION',
    ));
  }

  /// Rule 6: Harvest readiness check (site-level).
  /// Condition: summer window, no HARVEST event this season.
  void _harvestReadiness(
    RuleContext ctx,
    SeasonConfig config,
    String siteId,
    List<EventSummary> siteEvents,
    List<Suggestion> out,
  ) {
    if (!config.isSummer(ctx.weekOfYear)) return;

    // Look for any harvest event within the current summer window.
    final hasHarvest = siteEvents.any((e) => e.type == 'HARVEST');
    if (hasHarvest) return;

    out.add(Suggestion(
      id: _makeId('harvest_readiness', siteId, ctx.weekOfYear),
      title: 'Check if honey harvest ready',
      description:
          'No harvest event recorded this summer. Check if supers are '
          'capped and ready for extraction.',
      priority: SuggestionPriority.low,
      siteId: siteId == '_all' ? null : siteId,
      suggestedEventType: 'HARVEST',
    ));
  }

  // ---- helpers ------------------------------------------------------------

  /// Build a deterministic suggestion ID from rule name, scope, and week.
  /// Same inputs always produce the same ID.
  static String _makeId(String rule, String scope, int week) {
    // Simple deterministic hash; no crypto needed for a local ID.
    final raw = '${rule}_${scope}_w$week';
    // Use a basic djb2-style hash to keep the id short but stable.
    var hash = 5381;
    for (var i = 0; i < raw.length; i++) {
      hash = ((hash << 5) + hash) + raw.codeUnitAt(i);
      hash &= 0x7FFFFFFF; // keep positive 31-bit
    }
    return '${rule}_${hash.toRadixString(36)}';
  }
}
