import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../data/local/daos/events_dao.dart';
import '../../../data/local/daos/tasks_dao.dart';
import '../../../data/local/database.dart' as db;
import '../../../l10n/app_localizations.dart';
import '../../../services/gamification_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/sync_provider.dart';
import '../../providers/sites_provider.dart';

class HomeScreen extends StatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _routes = ['/home', '/sites', '/community', '/settings'];

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
      context.go(_routes[index]);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update index from current route
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _routes.length; i++) {
      if (location.startsWith(_routes[i])) {
        if (_currentIndex != i) {
          setState(() {
            _currentIndex = i;
          });
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('app_name')),
        actions: [
          // Sync indicator
          Consumer<SyncProvider>(
            builder: (context, sync, _) {
              return IconButton(
                icon: sync.isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        sync.isOnline
                            ? Icons.cloud_done
                            : Icons.cloud_off,
                        color: Colors.white,
                      ),
                tooltip: sync.isSyncing
                    ? l.tr('syncing')
                    : sync.isOnline
                        ? l.tr('online')
                        : l.tr('offline'),
                onPressed: sync.isSyncing ? null : () => sync.triggerSync(),
              );
            },
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: l.tr('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.location_on_outlined),
            activeIcon: const Icon(Icons.location_on),
            label: l.tr('sites'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_outline),
            activeIcon: const Icon(Icons.people),
            label: l.tr('community'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings_outlined),
            activeIcon: const Icon(Icons.settings),
            label: l.tr('settings'),
          ),
        ],
      ),
    );
  }
}

/// Content for the Home tab.
class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  List<Achievement> _achievements = [];
  int _streak = 0;
  bool _gamLoaded = false;
  List<db.Task> _todayTasks = [];
  List<db.Task> _weekTasks = [];
  int _inspectionCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    try {
      final eventsDao = context.read<EventsDao>();
      final tasksDao = context.read<TasksDao>();
      final events = await eventsDao.getAll();
      final tasks = await tasksDao.getAll();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));
      final weekEnd = todayStart.add(const Duration(days: 7));

      final todayTasks = tasks
          .where((t) =>
              t.status == 'open' &&
              t.dueAt != null &&
              !t.dueAt!.isBefore(todayStart) &&
              t.dueAt!.isBefore(todayEnd))
          .toList();

      final weekTasks = tasks
          .where((t) =>
              t.status == 'open' &&
              t.dueAt != null &&
              !t.dueAt!.isBefore(todayEnd) &&
              t.dueAt!.isBefore(weekEnd))
          .toList()
        ..sort((a, b) => a.dueAt!.compareTo(b.dueAt!));

      final inspectionCount = events
          .where((e) => e.type == 'inspection' || e.type == 'INSPECTION')
          .length;

      if (mounted) {
        setState(() {
          _achievements =
              GamificationService.evaluate(events: events, tasks: tasks);
          _streak = GamificationService.computeStreak(events);
          _todayTasks = todayTasks;
          _weekTasks = weekTasks;
          _inspectionCount = inspectionCount;
          _gamLoaded = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _gamLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting + streak
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Consumer<AuthProvider>(
                  builder: (context, auth, _) {
                    final name = auth.user?.name ?? 'Imker';
                    final greeting = _greeting(l);
                    return Text(
                      '$greeting, $name!',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    );
                  },
                ),
              ),
              if (_streak > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA000).withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFFA000).withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      Text(
                        '$_streak',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFFFFA000),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Achievements row
          if (_gamLoaded && _achievements.isNotEmpty) ...[
            Row(
              children: [
                const Text('🏅',
                    style: TextStyle(fontSize: 13)),
                const SizedBox(width: 4),
                Text(
                  'Errungenschaften',
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
            SizedBox(
              height: 72,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _achievements
                    .map((a) => _AchievementBadge(achievement: a))
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Quick Actions
          Text(
            l.tr('quick_actions'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.mic,
                  label: l.tr('voice_note'),
                  color: Colors.orange.shade700,
                  onTap: () => context.push('/voice'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.search,
                  label: l.tr('new_inspection'),
                  color: Colors.amber.shade800,
                  onTap: () {
                    context.go('/sites');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Tools row
          Row(
            children: [
              Expanded(
                child: _ToolButton(
                  icon: Icons.calculate,
                  label: 'Imkerrechner',
                  color: Colors.brown,
                  onTap: () => context.push('/tools/calculator'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToolButton(
                  icon: Icons.calendar_month,
                  label: 'Bienenkalender',
                  color: Colors.teal,
                  onTap: () => context.push('/tools/calendar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ToolButton(
                  icon: Icons.smart_toy_outlined,
                  label: 'Imker-KI',
                  color: Colors.deepPurple,
                  onTap: () => context.push('/ai'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Today's Tasks
          Text(
            l.tr('todays_tasks'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          if (_todayTasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 32, color: Colors.green[300]),
                    const SizedBox(width: 12),
                    Text(
                      l.tr('no_tasks_today'),
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_todayTasks.map((t) => _HomeTaskTile(task: t))),
          const SizedBox(height: 24),

          // Weekly Focus (next 7 days)
          Text(
            l.tr('weekly_focus'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          if (_weekTasks.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 20, horizontal: 16),
                child: Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined,
                        size: 32, color: Colors.amber[400]),
                    const SizedBox(width: 12),
                    const Text(
                      'Freie Woche – keine weiteren Aufgaben.',
                      style: TextStyle(color: Colors.grey, fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            ...(_weekTasks.map((t) => _HomeTaskTile(task: t))),
          const SizedBox(height: 24),

          // Summary card
          Text(
            l.tr('summary'),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 12),
          Consumer<SitesProvider>(
            builder: (context, sitesProvider, _) {
              final siteCount = sitesProvider.sites.length;
              final hiveCount = sitesProvider.sites
                  .fold<int>(0, (sum, s) => sum + s.hiveCount);
              return Card(
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        value: siteCount.toString(),
                        label: l.tr('sites_count'),
                        icon: Icons.location_on,
                      ),
                      _StatItem(
                        value: hiveCount.toString(),
                        label: l.tr('hives_count'),
                        icon: Icons.hexagon_outlined,
                      ),
                      _StatItem(
                        value: _inspectionCount.toString(),
                        label: l.tr('inspections_count'),
                        icon: Icons.assignment,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _greeting(AppLocalizations l) {
    final hour = DateTime.now().hour;
    if (hour < 12) return l.tr('greeting_morning');
    if (hour < 17) return l.tr('greeting_afternoon');
    return l.tr('greeting_evening');
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final unlocked = achievement.unlocked;
    return Container(
      width: 64,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: unlocked
                  ? const Color(0xFFFFA000).withAlpha(35)
                  : Colors.grey.withAlpha(20),
              shape: BoxShape.circle,
              border: Border.all(
                color: unlocked
                    ? const Color(0xFFFFA000).withAlpha(120)
                    : Colors.grey.withAlpha(60),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                achievement.emoji,
                style: TextStyle(
                  fontSize: 20,
                  color: unlocked ? null : Colors.transparent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: unlocked ? const Color(0xFF1A1A2E) : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Home Task Tile ────────────────────────────────────────────────────────────

class _HomeTaskTile extends StatelessWidget {
  final db.Task task;

  const _HomeTaskTile({required this.task});

  bool get _isOverdue =>
      task.dueAt != null && task.dueAt!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final color = _isOverdue ? Colors.red : const Color(0xFFFFA000);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  if (task.dueAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _isOverdue
                          ? '⚠ Überfällig · ${DateFormat('dd.MM').format(task.dueAt!)}'
                          : 'Heute · ${DateFormat('HH:mm').format(task.dueAt!)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: _isOverdue ? Colors.red : Colors.grey[500]),
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
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;

  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
