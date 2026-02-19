import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/daos/tasks_dao.dart';
import '../../../data/local/database.dart' as db;
import '../../../services/notification_service.dart';

const _kAmber = Color(0xFFFFA000);

class HiveTasksScreen extends StatefulWidget {
  final int hiveId;

  const HiveTasksScreen({super.key, required this.hiveId});

  @override
  State<HiveTasksScreen> createState() => _HiveTasksScreenState();
}

class _HiveTasksScreenState extends State<HiveTasksScreen> {
  List<db.Task> _openTasks = [];
  List<db.Task> _doneTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasksDao = context.read<TasksDao>();
      final all = await tasksDao.getByHiveId(widget.hiveId);
      if (mounted) {
        setState(() {
          _openTasks = all.where((t) => t.status == 'open').toList();
          _doneTasks = all.where((t) => t.status == 'done').toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateSwarmSeriesDialog() {
    final now = DateTime.now();
    int year = now.year;
    if (now.month > 9) year++;
    final start = DateTime(year, 4, 1);
    final end = DateTime(year, 9, 30);
    int count = 0;
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      count++;
      cur = cur.add(const Duration(days: 7));
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('🐝 Schwarmkontroll-Serie'),
        content: Text(
          'Erstelle $count wöchentliche Schwarmkontrollen von '
          '01.04.$year bis 30.09.$year (jeden 7. Tag).\n\n'
          'Jede Aufgabe enthält eine Erinnerungsnotifikation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _kAmber),
            onPressed: () {
              Navigator.pop(ctx);
              _createSwarmControlSeries(year);
            },
            child: const Text('Erstellen',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createSwarmControlSeries(int year) async {
    final start = DateTime(year, 4, 1);
    final end = DateTime(year, 9, 30);
    final tasksDao = context.read<TasksDao>();
    int created = 0;
    DateTime current = start;

    while (!current.isAfter(end)) {
      final taskId = await tasksDao.insertTask(
        db.TasksCompanion(
          clientTaskId: Value(const Uuid().v4()),
          hiveId: Value(widget.hiveId),
          title: const Value('Schwarmkontrolle'),
          description: const Value(
              'Wöchentliche Schwarmkontrolle: Weiselzellen prüfen, '
              'Brutraum bewerten, Schwarmsignale erkennen.'),
          status: const Value('open'),
          dueAt: Value(current),
          source: const Value('auto'),
          syncStatus: const Value('pending'),
          createdAt: Value(current),
          updatedAt: Value(current),
        ),
      );
      await NotificationService.scheduleTaskReminder(
        id: taskId,
        title: '🐝 Schwarmkontrolle fällig',
        body: 'Jetzt Weiselzellen und Schwarmsignale prüfen!',
        dueAt: current,
      );
      created++;
      current = current.add(const Duration(days: 7));
    }

    if (mounted) {
      _loadTasks();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            '$created Schwarmkontrollen erstellt (Apr–Sep $year)'),
        backgroundColor: _kAmber,
      ));
    }
  }

  void _showAddTaskDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddTaskSheet(
        hiveId: widget.hiveId,
        onSaved: _loadTasks,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Aufgaben'),
        backgroundColor: const Color(0xFF1A0E00),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddTaskDialog,
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'swarm_series') _showCreateSwarmSeriesDialog();
            },
            icon: const Icon(Icons.more_vert),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'swarm_series',
                child: Row(
                  children: [
                    Icon(Icons.repeat, size: 20, color: Color(0xFF1A1A2E)),
                    SizedBox(width: 10),
                    Text('🐝 Schwarmkontroll-Serie erstellen'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _kAmber))
          : RefreshIndicator(
              color: _kAmber,
              onRefresh: _loadTasks,
              child: CustomScrollView(
                slivers: [
                  // Open tasks
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: _SectionHeader(
                        label: 'Offen',
                        count: _openTasks.length,
                        color: _kAmber,
                      ),
                    ),
                  ),
                  if (_openTasks.isEmpty)
                    const SliverToBoxAdapter(child: _EmptyTasksHint())
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _TaskCard(
                          task: _openTasks[i],
                          onDone: () async {
                            await context
                                .read<TasksDao>()
                                .completeTask(_openTasks[i].id);
                            await NotificationService.cancel(
                                _openTasks[i].id);
                            _loadTasks();
                          },
                          onDelete: () async {
                            await context
                                .read<TasksDao>()
                                .deleteTask(_openTasks[i].id);
                            await NotificationService.cancel(
                                _openTasks[i].id);
                            _loadTasks();
                          },
                        ),
                        childCount: _openTasks.length,
                      ),
                    ),

                  // Done tasks
                  if (_doneTasks.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding:
                            const EdgeInsets.fromLTRB(20, 24, 20, 8),
                        child: _SectionHeader(
                          label: 'Erledigt',
                          count: _doneTasks.length,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => _TaskCard(
                          task: _doneTasks[i],
                          done: true,
                          onDone: null,
                          onDelete: () async {
                            await context
                                .read<TasksDao>()
                                .deleteTask(_doneTasks[i].id);
                            _loadTasks();
                          },
                        ),
                        childCount: _doneTasks.length,
                      ),
                    ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTaskDialog,
        backgroundColor: _kAmber,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add_task),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SectionHeader(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E)),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withAlpha(35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }
}

// ── Task Card ─────────────────────────────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final db.Task task;
  final bool done;
  final VoidCallback? onDone;
  final VoidCallback onDelete;

  const _TaskCard({
    required this.task,
    this.done = false,
    required this.onDone,
    required this.onDelete,
  });

  bool get _isOverdue =>
      !done &&
      task.dueAt != null &&
      task.dueAt!.isBefore(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final color = done
        ? Colors.green
        : _isOverdue
            ? Colors.red
            : _kAmber;

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: done ? Colors.grey.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: done
              ? []
              : const [
                  BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 4,
                      offset: Offset(0, 1))
                ],
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Color bar
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

              // Checkbox
              if (onDone != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GestureDetector(
                    onTap: onDone,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.check_circle,
                      color: Colors.green, size: 24),
                ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: done
                              ? Colors.grey
                              : const Color(0xFF1A1A2E),
                          decoration: done
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.description != null &&
                          task.description!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          task.description!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (task.dueAt != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _isOverdue
                                  ? Icons.warning
                                  : Icons.schedule,
                              size: 12,
                              color: _isOverdue
                                  ? Colors.red
                                  : Colors.grey[500],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              DateFormat('dd.MM.yyyy').format(task.dueAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: _isOverdue
                                    ? Colors.red
                                    : Colors.grey[500],
                                fontWeight: _isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (_isOverdue) ...[
                              const SizedBox(width: 4),
                              const Text(
                                'Überfällig',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add Task Sheet ────────────────────────────────────────────────────────────

class _AddTaskSheet extends StatefulWidget {
  final int hiveId;
  final VoidCallback onSaved;

  const _AddTaskSheet({required this.hiveId, required this.onSaved});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme:
              const ColorScheme.light(primary: _kAmber),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final now = DateTime.now();
    final tasksDao = context.read<TasksDao>();
    final taskId = await tasksDao.insertTask(
      db.TasksCompanion(
        clientTaskId: Value(const Uuid().v4()),
        hiveId: Value(widget.hiveId),
        title: Value(_titleCtrl.text.trim()),
        description: Value(_descCtrl.text.trim().isEmpty
            ? null
            : _descCtrl.text.trim()),
        dueAt: Value(_dueDate),
        status: const Value('open'),
        source: const Value('manual'),
        syncStatus: const Value('pending'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );

    if (_dueDate != null) {
      await NotificationService.scheduleTaskReminder(
        id: taskId,
        title: '🐝 Aufgabe: ${_titleCtrl.text.trim()}',
        body: 'Dein Volk wartet auf dich!',
        dueAt: _dueDate!,
      );
    }

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Neue Aufgabe',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleCtrl,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Titel *',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _kAmber, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Description
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Beschreibung (optional)',
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: _kAmber, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Due date
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: _kAmber, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _dueDate != null
                          ? DateFormat('dd.MM.yyyy').format(_dueDate!)
                          : 'Fälligkeitsdatum (optional)',
                      style: TextStyle(
                        color: _dueDate != null
                            ? const Color(0xFF1A1A2E)
                            : Colors.grey[500],
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    if (_dueDate != null)
                      GestureDetector(
                        onTap: () => setState(() => _dueDate = null),
                        child: const Icon(Icons.close,
                            color: Colors.grey, size: 16),
                      ),
                  ],
                ),
              ),
            ),

            if (_dueDate != null) ...[
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.notifications_active,
                      size: 12, color: _kAmber),
                  SizedBox(width: 4),
                  Text(
                    'Erinnerung am Fälligkeitstag um 8:00 Uhr',
                    style: TextStyle(fontSize: 11, color: _kAmber),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Aufgabe speichern',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Empty Hint ────────────────────────────────────────────────────────────────

class _EmptyTasksHint extends StatelessWidget {
  const _EmptyTasksHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _kAmber.withAlpha(50)),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline,
              size: 44, color: _kAmber.withAlpha(100)),
          const SizedBox(height: 10),
          const Text('Keine offenen Aufgaben',
              style:
                  TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(height: 4),
          Text(
            'Tippe auf + um eine Aufgabe zu erstellen',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

