import 'package:flutter/material.dart';

import '../data/remote/weather_api.dart';
import '../domain/models/event.dart';
import '../domain/models/hive.dart';

enum RecommendationPriority { urgent, warning, info }

class Recommendation {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final RecommendationPriority priority;
  final String? actionLabel;
  final String? actionRoute;

  const Recommendation({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.priority,
    this.actionLabel,
    this.actionRoute,
  });
}

// ── Varroa trend result ───────────────────────────────────────────────────────

class VarroaPoint {
  final DateTime date;
  final double rate;
  const VarroaPoint({required this.date, required this.rate});
}

class VarroaTrend {
  final double slope; // rate per day
  final bool isIncreasing;
  final bool isDecreasing;
  final int? daysToThreshold; // days until rate >= 3
  final double latestRate;
  final List<VarroaPoint> points; // oldest first

  const VarroaTrend({
    required this.slope,
    required this.isIncreasing,
    required this.isDecreasing,
    required this.daysToThreshold,
    required this.latestRate,
    required this.points,
  });

  String get trendLabel {
    if (isIncreasing) return '↑ Steigend';
    if (isDecreasing) return '↓ Sinkend';
    return '→ Stabil';
  }

  Color get trendColor {
    if (isIncreasing) return Colors.red;
    if (isDecreasing) return Colors.green;
    return Colors.orange;
  }
}

// ── Engine ────────────────────────────────────────────────────────────────────

class RecommendationEngine {
  /// Generate up to 3 prioritised recommendations for a hive.
  static List<Recommendation> analyze({
    required List<EventModel> events,
    required HiveModel hive,
    WeatherData? weather,
  }) {
    final recs = <Recommendation>[];
    final now = DateTime.now();
    final month = now.month;

    // --- Last inspection ---
    final inspections =
        events.where((e) => e.type == EventType.inspection).toList();
    final lastInspection =
        inspections.isNotEmpty ? inspections.first.occurredAtLocal : null;

    // --- Varroa data ---
    final varroaEvents = events
        .where((e) => e.type == EventType.varroaMeasurement)
        .toList();
    final lastVarroaRate = varroaEvents.isNotEmpty
        ? (varroaEvents.first.payload['normalized_rate'] as num?)?.toDouble()
        : null;

    // ── Inspection checks ─────────────────────────────────────────────
    if (lastInspection == null) {
      recs.add(const Recommendation(
        title: 'Erste Durchsicht steht aus',
        body: 'Noch keine Kontrolle dokumentiert. Führe die erste Durchsicht durch!',
        icon: Icons.assignment,
        color: Colors.blue,
        priority: RecommendationPriority.info,
        actionLabel: 'Jetzt kontrollieren',
        actionRoute: 'inspect',
      ));
    } else {
      final daysSince = now.difference(lastInspection).inDays;
      if (daysSince > 21) {
        recs.add(Recommendation(
          title: 'Durchsicht überfällig',
          body: 'Letzte Kontrolle vor $daysSince Tagen – dringend nachsehen!',
          icon: Icons.warning_amber,
          color: Colors.deepOrange,
          priority: RecommendationPriority.urgent,
          actionLabel: 'Durchsicht',
          actionRoute: 'inspect',
        ));
      } else if (daysSince > 10 && month >= 4 && month <= 9) {
        recs.add(Recommendation(
          title: 'Durchsicht empfohlen',
          body: 'In der Saison alle 7–10 Tage kontrollieren (Schwarmkontrolle).',
          icon: Icons.assignment_outlined,
          color: Colors.blue,
          priority: RecommendationPriority.warning,
          actionLabel: 'Durchsicht',
          actionRoute: 'inspect',
        ));
      }
    }

    // ── Varroa checks ─────────────────────────────────────────────────
    if (lastVarroaRate != null) {
      if (lastVarroaRate > 3) {
        recs.add(Recommendation(
          title: '🚨 Varroa: Behandlung dringend!',
          body: 'Befall ${lastVarroaRate.toStringAsFixed(1)}/Tag – kritischer Bereich. Sofort behandeln!',
          icon: Icons.bug_report,
          color: Colors.red,
          priority: RecommendationPriority.urgent,
          actionLabel: 'Behandlung erfassen',
          actionRoute: 'treatment',
        ));
      } else if (lastVarroaRate > 1) {
        recs.add(Recommendation(
          title: 'Varroa beobachten',
          body: 'Befall ${lastVarroaRate.toStringAsFixed(1)}/Tag – bald erneut messen.',
          icon: Icons.bug_report_outlined,
          color: Colors.orange,
          priority: RecommendationPriority.warning,
          actionLabel: 'Varroa messen',
          actionRoute: 'varroa',
        ));
      }
    } else if (varroaEvents.isEmpty) {
      recs.add(const Recommendation(
        title: 'Varroa-Messung ausstehend',
        body: 'Keine Varroa-Daten vorhanden. Führe eine erste Messung durch.',
        icon: Icons.science,
        color: Colors.deepOrange,
        priority: RecommendationPriority.info,
        actionLabel: 'Jetzt messen',
        actionRoute: 'varroa',
      ));
    }

    // ── Seasonal recommendations ──────────────────────────────────────
    if ((month == 8 || month == 9) && lastVarroaRate == null) {
      recs.add(const Recommendation(
        title: 'Varroa-Behandlung August/Sept.',
        body: 'Nach der Ernte Varroa-Behandlung durchführen – Winterbienen schützen!',
        icon: Icons.medical_services,
        color: Colors.brown,
        priority: RecommendationPriority.warning,
        actionLabel: 'Behandlung',
        actionRoute: 'treatment',
      ));
    }

    if (month == 10 || month == 11) {
      recs.add(const Recommendation(
        title: 'Einwinterung prüfen',
        body: 'Mäuseschutz, Eingang einengen, Futtervorrat mind. 20 kg sichern.',
        icon: Icons.cabin,
        color: Colors.indigo,
        priority: RecommendationPriority.info,
      ));
    }

    if (month == 3) {
      recs.add(const Recommendation(
        title: 'Frühjahrskontrolle',
        body: 'Erste Frühjahrsdurchsicht ab 12 °C – Brutbeginn und Futtervorrat prüfen.',
        icon: Icons.eco,
        color: Colors.green,
        priority: RecommendationPriority.info,
        actionLabel: 'Durchsicht',
        actionRoute: 'inspect',
      ));
    }

    // ── Weather-based ─────────────────────────────────────────────────
    if (weather != null) {
      if (weather.varroaRisk == VarroaWeatherRisk.high &&
          (lastVarroaRate == null || lastVarroaRate > 1)) {
        recs.add(const Recommendation(
          title: 'Ungünstiges Varroawetter',
          body: 'Warm und feucht: ideale Bedingungen für Varroa-Vermehrung. Jetzt messen!',
          icon: Icons.thermostat,
          color: Colors.deepOrange,
          priority: RecommendationPriority.warning,
          actionLabel: 'Varroa messen',
          actionRoute: 'varroa',
        ));
      }

      if (weather.goodForBeesFlight &&
          lastInspection != null &&
          now.difference(lastInspection).inDays >= 6) {
        recs.add(const Recommendation(
          title: 'Perfekter Durchsichtstag ☀️',
          body: 'Gutes Wetter, Bienen fliegen – ideale Bedingungen für eine Kontrolle.',
          icon: Icons.wb_sunny,
          color: Colors.amber,
          priority: RecommendationPriority.info,
          actionLabel: 'Durchsicht',
          actionRoute: 'inspect',
        ));
      }
    }

    // Sort by priority: urgent first
    recs.sort((a, b) => a.priority.index.compareTo(b.priority.index));
    return recs.take(3).toList();
  }

  // ── Varroa Trend (linear regression) ─────────────────────────────────────

  static VarroaTrend? analyzeTrend(List<EventModel> varroaEvents) {
    final points = varroaEvents
        .where((e) => e.payload['normalized_rate'] != null)
        .map((e) => VarroaPoint(
              date: e.occurredAtLocal,
              rate: (e.payload['normalized_rate'] as num).toDouble(),
            ))
        .toList();

    if (points.length < 2) return null;

    // Sort oldest first
    points.sort((a, b) => a.date.compareTo(b.date));

    final n = points.length;
    final firstDate = points.first.date;
    final xs = points
        .map((p) => p.date.difference(firstDate).inDays.toDouble())
        .toList();
    final ys = points.map((p) => p.rate).toList();

    final xMean = xs.reduce((a, b) => a + b) / n;
    final yMean = ys.reduce((a, b) => a + b) / n;

    double numer = 0, denom = 0;
    for (int i = 0; i < n; i++) {
      numer += (xs[i] - xMean) * (ys[i] - yMean);
      denom += (xs[i] - xMean) * (xs[i] - xMean);
    }
    if (denom == 0) return null;

    final slope = numer / denom;
    final intercept = yMean - slope * xMean;

    // Days until rate reaches 3
    final todayX =
        DateTime.now().difference(firstDate).inDays.toDouble();
    int? daysToThreshold;
    final currentPredicted = slope * todayX + intercept;
    if (slope > 0 && currentPredicted < 3) {
      final d = ((3 - intercept) / slope - todayX).round();
      if (d > 0) daysToThreshold = d;
    }

    return VarroaTrend(
      slope: slope,
      isIncreasing: slope > 0.01,
      isDecreasing: slope < -0.01,
      daysToThreshold: daysToThreshold,
      latestRate: points.last.rate,
      points: points,
    );
  }
}
