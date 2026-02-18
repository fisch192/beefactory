import 'package:test/test.dart';
import '../lib/domain/rules/rule_engine.dart';
import '../lib/domain/rules/zone_config.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Monday of ISO week [week] in [year].
DateTime _mondayOfWeek(int year, int week) {
  // Jan 4 is always in ISO week 1.
  final jan4 = DateTime(year, 1, 4);
  final dayOfWeek = jan4.weekday; // 1=Mon .. 7=Sun
  final week1Monday = jan4.subtract(Duration(days: dayOfWeek - 1));
  return week1Monday.add(Duration(days: (week - 1) * 7));
}

RuleContext _ctx({
  String region = 'suedtirol',
  String elevationBand = 'low',
  int weekOfYear = 20,
  DateTime? now,
  List<EventSummary> recentEvents = const [],
  List<TaskSummary> pendingTasks = const [],
  List<String> hiveIds = const [],
}) {
  final effectiveNow = now ?? _mondayOfWeek(2025, weekOfYear);
  return RuleContext(
    region: region,
    elevationBand: elevationBand,
    weekOfYear: weekOfYear,
    now: effectiveNow,
    recentEvents: recentEvents,
    pendingTasks: pendingTasks,
    hiveIds: hiveIds,
  );
}

EventSummary _event(
  String type, {
  String? hiveId,
  String siteId = 'site-1',
  required DateTime occurredAt,
}) =>
    EventSummary(
      type: type,
      hiveId: hiveId,
      siteId: siteId,
      occurredAt: occurredAt,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const engine = RuleEngine();

  // ========================================================================
  // Rule 1 - Spring inspection reminder
  // ========================================================================
  group('Rule 1: Spring inspection reminder', () {
    test('fires during spring when no recent inspection', () {
      // Week 12 is spring for low (seasonStart=10, swarmStart=16)
      final ctx = _ctx(
        weekOfYear: 12,
        hiveIds: ['hive-1'],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Time for spring inspection'),
        isTrue,
      );
      expect(
        results.firstWhere((s) => s.title == 'Time for spring inspection').priority,
        SuggestionPriority.high,
      );
    });

    test('does NOT fire when recent inspection exists', () {
      final now = _mondayOfWeek(2025, 12);
      final ctx = _ctx(
        weekOfYear: 12,
        now: now,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('INSPECTION',
              hiveId: 'hive-1',
              occurredAt: now.subtract(const Duration(days: 5))),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Time for spring inspection'),
        isFalse,
      );
    });

    test('does NOT fire during summer', () {
      final ctx = _ctx(weekOfYear: 30, hiveIds: ['hive-1']);
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Time for spring inspection'),
        isFalse,
      );
    });
  });

  // ========================================================================
  // Rule 2 - Varroa measurement reminder
  // ========================================================================
  group('Rule 2: Varroa measurement reminder', () {
    test('fires during varroa window when no recent measurement', () {
      final ctx = _ctx(
        weekOfYear: 30,
        hiveIds: ['hive-1'],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Varroa check overdue'),
        isTrue,
      );
    });

    test('does NOT fire when recent measurement exists', () {
      final now = _mondayOfWeek(2025, 30);
      final ctx = _ctx(
        weekOfYear: 30,
        now: now,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('VARROA_MEASUREMENT',
              hiveId: 'hive-1',
              occurredAt: now.subtract(const Duration(days: 10))),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Varroa check overdue'),
        isFalse,
      );
    });

    test('does NOT fire in winter', () {
      final ctx = _ctx(weekOfYear: 2, hiveIds: ['hive-1']);
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Varroa check overdue'),
        isFalse,
      );
    });
  });

  // ========================================================================
  // Rule 3 - Post-treatment follow-up
  // ========================================================================
  group('Rule 3: Post-treatment follow-up', () {
    test('fires when treatment 7-21 days ago with no follow-up', () {
      final now = _mondayOfWeek(2025, 30);
      final ctx = _ctx(
        weekOfYear: 30,
        now: now,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('TREATMENT',
              hiveId: 'hive-1',
              occurredAt: now.subtract(const Duration(days: 10))),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) =>
            s.title == 'Follow-up varroa measurement after treatment'),
        isTrue,
      );
      expect(
        results
            .firstWhere((s) =>
                s.title == 'Follow-up varroa measurement after treatment')
            .priority,
        SuggestionPriority.medium,
      );
    });

    test('does NOT fire when follow-up measurement exists', () {
      final now = _mondayOfWeek(2025, 30);
      final treatmentDate = now.subtract(const Duration(days: 14));
      final ctx = _ctx(
        weekOfYear: 30,
        now: now,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('TREATMENT',
              hiveId: 'hive-1', occurredAt: treatmentDate),
          _event('VARROA_MEASUREMENT',
              hiveId: 'hive-1',
              occurredAt: treatmentDate.add(const Duration(days: 5))),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) =>
            s.title == 'Follow-up varroa measurement after treatment'),
        isFalse,
      );
    });
  });

  // ========================================================================
  // Rule 4 - Feeding check in autumn
  // ========================================================================
  group('Rule 4: Feeding check in autumn', () {
    test('fires during autumn when no recent feeding', () {
      final ctx = _ctx(
        weekOfYear: 38,
        hiveIds: ['hive-1'],
        recentEvents: [
          // Need at least one event with a siteId so the engine has a site.
          _event('NOTE',
              hiveId: 'hive-1',
              siteId: 'site-1',
              occurredAt: _mondayOfWeek(2025, 37)),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any(
            (s) => s.title == 'Check winter stores / feeding needed?'),
        isTrue,
      );
    });

    test('does NOT fire when recent feeding exists', () {
      final now = _mondayOfWeek(2025, 38);
      final ctx = _ctx(
        weekOfYear: 38,
        now: now,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('FEEDING',
              hiveId: 'hive-1',
              siteId: 'site-1',
              occurredAt: now.subtract(const Duration(days: 10))),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any(
            (s) => s.title == 'Check winter stores / feeding needed?'),
        isFalse,
      );
    });
  });

  // ========================================================================
  // Rule 5 - Weekly swarm-control inspection
  // ========================================================================
  group('Rule 5: Swarm control inspection', () {
    test('fires during swarm season when no recent inspection', () {
      final ctx = _ctx(
        weekOfYear: 20,
        hiveIds: ['hive-1'],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Swarm control inspection due'),
        isTrue,
      );
      expect(
        results
            .firstWhere((s) => s.title == 'Swarm control inspection due')
            .priority,
        SuggestionPriority.urgent,
      );
    });

    test('does NOT fire when recent inspection exists', () {
      final now = _mondayOfWeek(2025, 20);
      final ctx = _ctx(
        weekOfYear: 20,
        now: now,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('INSPECTION',
              hiveId: 'hive-1',
              occurredAt: now.subtract(const Duration(days: 3))),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Swarm control inspection due'),
        isFalse,
      );
    });
  });

  // ========================================================================
  // Rule 6 - Harvest readiness
  // ========================================================================
  group('Rule 6: Harvest readiness', () {
    test('fires during summer when no harvest this season', () {
      final ctx = _ctx(
        weekOfYear: 28,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('NOTE',
              hiveId: 'hive-1',
              siteId: 'site-1',
              occurredAt: _mondayOfWeek(2025, 27)),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Check if honey harvest ready'),
        isTrue,
      );
      expect(
        results
            .firstWhere((s) => s.title == 'Check if honey harvest ready')
            .priority,
        SuggestionPriority.low,
      );
    });

    test('does NOT fire when harvest already recorded', () {
      final now = _mondayOfWeek(2025, 28);
      final ctx = _ctx(
        weekOfYear: 28,
        now: now,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('HARVEST',
              hiveId: 'hive-1',
              siteId: 'site-1',
              occurredAt: now.subtract(const Duration(days: 5))),
        ],
      );
      final results = engine.evaluate(ctx);
      expect(
        results.any((s) => s.title == 'Check if honey harvest ready'),
        isFalse,
      );
    });
  });

  // ========================================================================
  // Elevation band differences
  // ========================================================================
  group('Elevation band differences', () {
    test('swarm rule fires for low at week 20 but NOT for high at week 18', () {
      // Low: swarm 16-26, so week 20 is swarm season.
      final ctxLow = _ctx(
        elevationBand: 'low',
        weekOfYear: 20,
        hiveIds: ['hive-1'],
      );
      final resultsLow = engine.evaluate(ctxLow);
      expect(
        resultsLow.any((s) => s.title == 'Swarm control inspection due'),
        isTrue,
      );

      // High: swarm 20-30, so week 18 is NOT swarm season.
      final ctxHigh = _ctx(
        elevationBand: 'high',
        weekOfYear: 18,
        hiveIds: ['hive-1'],
      );
      final resultsHigh = engine.evaluate(ctxHigh);
      expect(
        resultsHigh.any((s) => s.title == 'Swarm control inspection due'),
        isFalse,
      );
    });

    test('spring inspection fires for mid at week 14 but NOT for low at week 8', () {
      // Mid: seasonStart=12, swarmStart=18, so week 14 is spring.
      final ctxMid = _ctx(
        elevationBand: 'mid',
        weekOfYear: 14,
        hiveIds: ['hive-1'],
      );
      final resultsMid = engine.evaluate(ctxMid);
      expect(
        resultsMid.any((s) => s.title == 'Time for spring inspection'),
        isTrue,
      );

      // Low: seasonStart=10, so week 8 is NOT spring yet.
      final ctxLow = _ctx(
        elevationBand: 'low',
        weekOfYear: 8,
        hiveIds: ['hive-1'],
      );
      final resultsLow = engine.evaluate(ctxLow);
      expect(
        resultsLow.any((s) => s.title == 'Time for spring inspection'),
        isFalse,
      );
    });
  });

  // ========================================================================
  // Priority ordering
  // ========================================================================
  group('Priority ordering', () {
    test('suggestions are sorted by priority descending', () {
      // Week 20, low elevation: swarm season (urgent) + varroa window may
      // not overlap, but we can engineer both.
      // Week 26 low: swarm (16-26) AND varroa (25-40) AND summer (24-32).
      final ctx = _ctx(
        weekOfYear: 26,
        hiveIds: ['hive-1'],
        recentEvents: [
          _event('NOTE',
              hiveId: 'hive-1',
              siteId: 'site-1',
              occurredAt: _mondayOfWeek(2025, 25)),
        ],
      );
      final results = engine.evaluate(ctx);

      // Should have multiple suggestions with different priorities.
      expect(results.length, greaterThanOrEqualTo(2));

      // Verify sorted: each priority index >= next.
      for (var i = 0; i < results.length - 1; i++) {
        expect(
          results[i].priority.index,
          greaterThanOrEqualTo(results[i + 1].priority.index),
        );
      }
    });
  });

  // ========================================================================
  // Determinism
  // ========================================================================
  group('Determinism', () {
    test('same input produces identical output', () {
      final now = _mondayOfWeek(2025, 20);
      RuleContext buildCtx() => _ctx(
            weekOfYear: 20,
            now: now,
            hiveIds: ['hive-1'],
          );

      final a = engine.evaluate(buildCtx());
      final b = engine.evaluate(buildCtx());

      expect(a.length, b.length);
      for (var i = 0; i < a.length; i++) {
        expect(a[i].id, b[i].id);
        expect(a[i].title, b[i].title);
        expect(a[i].priority, b[i].priority);
      }
    });
  });

  // ========================================================================
  // Unknown region returns empty
  // ========================================================================
  group('Unknown region', () {
    test('returns empty list for unknown region', () {
      final ctx = _ctx(
        region: 'mordor',
        weekOfYear: 20,
        hiveIds: ['hive-1'],
      );
      final results = engine.evaluate(ctx);
      expect(results, isEmpty);
    });
  });
}
