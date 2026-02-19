import '../data/local/database.dart' as db;
import '../domain/models/event.dart';

class Achievement {
  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool unlocked;

  const Achievement({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.unlocked,
  });
}

class GamificationService {
  /// Derive achievements from existing event + task data.
  static List<Achievement> evaluate({
    required List<db.Event> events,
    required List<db.Task> tasks,
  }) {
    final inspectionCount = events
        .where((e) =>
            e.type == 'inspection' || e.type == 'INSPECTION')
        .length;
    final varroaCount = events
        .where((e) =>
            e.type == 'VARROA_MEASUREMENT' ||
            e.type == 'varroaMeasurement')
        .length;
    final treatmentCount =
        events.where((e) => e.type == 'treatment').length;
    final doneTaskCount =
        tasks.where((t) => t.status == 'done').length;
    final harvestCount =
        events.where((e) => e.type == 'harvest').length;

    return [
      Achievement(
        id: 'first_entry',
        emoji: '🐝',
        title: 'Erster Eintrag',
        description: 'Das Tagebuch beginnt',
        unlocked: events.isNotEmpty,
      ),
      Achievement(
        id: 'first_inspection',
        emoji: '🔍',
        title: 'Erster Blick',
        description: 'Erste Durchsicht dokumentiert',
        unlocked: inspectionCount >= 1,
      ),
      Achievement(
        id: 'diligent_beekeeper',
        emoji: '⭐',
        title: 'Fleißiger Imker',
        description: '10 Durchsichten durchgeführt',
        unlocked: inspectionCount >= 10,
      ),
      Achievement(
        id: 'varroa_watcher',
        emoji: '🔬',
        title: 'Varroawächter',
        description: '3 Varroa-Messungen',
        unlocked: varroaCount >= 3,
      ),
      Achievement(
        id: 'treatment_pro',
        emoji: '💊',
        title: 'Behandlungsprofi',
        description: 'Erste Varroa-Behandlung',
        unlocked: treatmentCount >= 1,
      ),
      Achievement(
        id: 'task_master',
        emoji: '✅',
        title: 'Aufgabenmeister',
        description: '5 Aufgaben erledigt',
        unlocked: doneTaskCount >= 5,
      ),
      Achievement(
        id: 'honey_harvest',
        emoji: '🍯',
        title: 'Honig-Ernte',
        description: 'Erste Ernte dokumentiert',
        unlocked: harvestCount >= 1,
      ),
      Achievement(
        id: 'veteran',
        emoji: '🏆',
        title: 'Imker-Veteran',
        description: '50 Einträge im Tagebuch',
        unlocked: events.length >= 50,
      ),
    ];
  }

  /// How many consecutive days had at least one event (including today).
  static int computeStreak(List<db.Event> events) {
    if (events.isEmpty) return 0;

    // Unique dates, descending
    final dates = events
        .map((e) => _toDay(e.occurredAtLocal))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    final today = _toDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // Streak must start today or yesterday
    if (dates.first.isBefore(yesterday)) return 0;

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      if (dates[i].difference(dates[i + 1]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  static DateTime _toDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}
