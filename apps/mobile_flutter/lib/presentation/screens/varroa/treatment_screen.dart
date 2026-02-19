import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../../../data/local/daos/events_dao.dart';
import '../../../data/local/daos/tasks_dao.dart';
import '../../../data/local/database.dart' as db;
import '../../../l10n/app_localizations.dart';
import '../community/community_feed_screen.dart';

/// Treatment methods.
enum TreatmentMethod {
  formic('formic', 'Ameisensäure'),
  oxalic('oxalic', 'Oxalsäure'),
  thymol('thymol', 'Thymol'),
  biotech('biotech', 'Biotechnisch'),
  broodBreak('brood_break', 'Brutentnahme');

  final String apiValue;
  final String label;
  const TreatmentMethod(this.apiValue, this.label);
}

/// Form screen for recording a varroa treatment. Optionally creates a
/// follow-up measurement reminder as a TASK.
class TreatmentScreen extends StatefulWidget {
  final String hiveId;
  final String? hiveName;

  const TreatmentScreen({
    super.key,
    required this.hiveId,
    this.hiveName,
  });

  @override
  State<TreatmentScreen> createState() => _TreatmentScreenState();
}

class _TreatmentScreenState extends State<TreatmentScreen> {
  TreatmentMethod _method = TreatmentMethod.formic;
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();
  final _followUpDaysController = TextEditingController(text: '14');

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _createFollowUp = true;
  bool _saving = false;

  @override
  void dispose() {
    _dosageController.dispose();
    _notesController.dispose();
    _followUpDaysController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  Future<void> _pickDate({required bool isStart}) async {
    final initial = isStart ? _startDate : _endDate;
    final firstDate = isStart
        ? DateTime.now().subtract(const Duration(days: 365))
        : _startDate;
    final lastDate = DateTime.now().add(const Duration(days: 365));

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: kHoneyAmber,
                  onPrimary: Colors.white,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    setState(() => _saving = true);

    try {
      final eventsDao = context.read<EventsDao>();
      final now = DateTime.now();
      final payload = {
        'method': _method.apiValue,
        'dosage': _dosageController.text.trim(),
        'start_date': _startDate.toUtc().toIso8601String(),
        'end_date': _endDate.toUtc().toIso8601String(),
        'notes': _notesController.text.trim(),
        'source': 'manual',
      };

      // Create TREATMENT event in local DB.
      await eventsDao.insertEvent(db.EventsCompanion(
        clientEventId: Value(const Uuid().v4()),
        hiveId: Value(int.tryParse(widget.hiveId)),
        type: const Value('treatment'),
        occurredAtLocal: Value(now),
        occurredAtUtc: Value(now.toUtc()),
        payload: Value(jsonEncode(payload)),
        source: const Value('manual'),
        syncStatus: const Value('pending'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      // Create follow-up measurement reminder task in local DB.
      if (_createFollowUp) {
        final followUpDays =
            int.tryParse(_followUpDaysController.text) ?? 14;
        final dueAt = _endDate.add(Duration(days: followUpDays));

        final tasksDao = context.read<TasksDao>();
        await tasksDao.insertTask(db.TasksCompanion(
          clientTaskId: Value(const Uuid().v4()),
          hiveId: Value(int.tryParse(widget.hiveId)),
          title: Value(
              'Varroa-Kontrolle nach ${_method.label}-Behandlung'),
          description: Value(
              'Follow-up Varroa-Messung nach Behandlung vom '
              '${_formatDate(_startDate)} bis ${_formatDate(_endDate)}.'),
          status: const Value('open'),
          dueAt: Value(dueAt),
          source: const Value('manual'),
          syncStatus: const Value('pending'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ));
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_createFollowUp
              ? l.tr('treatment_saved_reminder')
              : l.tr('treatment_saved')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l.tr('error')}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      backgroundColor: kHoneyAmberSurface,
      appBar: AppBar(
        title: Text(widget.hiveName != null
            ? '${l.tr('treatment')} - ${widget.hiveName}'
            : l.tr('treatment_title')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Method selection
            Text(
              l.tr('treatment_method'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: TreatmentMethod.values.map((method) {
                    return RadioListTile<TreatmentMethod>(
                      title: Text(method.label),
                      value: method,
                      groupValue: _method,
                      activeColor: kHoneyAmber,
                      onChanged: (value) {
                        if (value != null) setState(() => _method = value);
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dosage
            TextFormField(
              controller: _dosageController,
              decoration: InputDecoration(
                labelText: l.tr('dosage'),
                hintText: l.tr('dosage_hint'),
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.science, color: kHoneyAmber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kHoneyAmber, width: 2),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Date pickers
            Row(
              children: [
                Expanded(
                  child: _DatePickerField(
                    label: 'Startdatum',
                    value: _formatDate(_startDate),
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DatePickerField(
                    label: 'Enddatum',
                    value: _formatDate(_endDate),
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: l.tr('notes'),
                hintText: 'Beobachtungen, Temperatur, etc.',
                filled: true,
                fillColor: Colors.white,
                prefixIcon:
                    const Icon(Icons.edit_note, color: kHoneyAmber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kHoneyAmber, width: 2),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 20),

            // Follow-up reminder
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notifications_active,
                            color: kHoneyAmber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l.tr('create_reminder'),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3E2723),
                            ),
                          ),
                        ),
                        Switch(
                          value: _createFollowUp,
                          activeColor: kHoneyAmber,
                          onChanged: (value) =>
                              setState(() => _createFollowUp = value),
                        ),
                      ],
                    ),
                    if (_createFollowUp) ...[
                      const SizedBox(height: 8),
                      Text(
                        l.tr('followup_description'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(l.tr('reminder_days')),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: _followUpDaysController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.grey[100],
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Builder(
                        builder: (_) {
                          final days = int.tryParse(
                                  _followUpDaysController.text) ??
                              14;
                          final dueDate =
                              _endDate.add(Duration(days: days));
                          return Text(
                            '${l.tr('reminder_on_date')} ${_formatDate(dueDate)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: kHoneyAmberDark,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save),
                label:
                    Text(_saving ? l.tr('syncing') : l.tr('save')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kHoneyAmber,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      kHoneyAmber.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tappable date picker field widget.
class _DatePickerField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DatePickerField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.calendar_today,
              color: kHoneyAmber, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(value),
      ),
    );
  }
}
