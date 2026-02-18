import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart' as drift;

import '../../../data/local/daos/events_dao.dart';
import '../../../data/local/database.dart';
import '../../../domain/models/hive.dart';
import '../../../domain/repositories/hive_repository.dart';
import '../../../l10n/app_localizations.dart';

class QuickInspectionScreen extends StatefulWidget {
  final int hiveId;

  const QuickInspectionScreen({super.key, required this.hiveId});

  @override
  State<QuickInspectionScreen> createState() => _QuickInspectionScreenState();
}

class _QuickInspectionScreenState extends State<QuickInspectionScreen> {
  HiveModel? _hive;
  bool _isLoading = true;
  bool _isSaving = false;

  // Inspection fields
  String _brood = 'present';
  bool _queenSeen = false;
  String _queenCells = 'none';
  String _temperament = 'calm';
  String _stores = 'medium';
  String _supers = 'none';
  final _notesController = TextEditingController();

  static const _broodOptions = ['present', 'compact', 'patchy', 'none'];
  static const _queenCellOptions = ['none', 'cups', 'charged'];
  static const _temperamentOptions = ['calm', 'normal', 'defensive'];
  static const _storesOptions = ['low', 'medium', 'high'];
  static const _supersOptions = ['added', 'removed', 'none'];

  @override
  void initState() {
    super.initState();
    _loadHive();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadHive() async {
    try {
      final hive =
          await context.read<HiveRepository>().getById(widget.hiveId);
      if (mounted) {
        setState(() {
          _hive = hive;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    try {
      final now = DateTime.now();
      final payload = {
        'brood': _brood,
        'queen_seen': _queenSeen,
        'queen_cells': _queenCells,
        'temperament': _temperament,
        'stores': _stores,
        'supers': _supers,
        if (_notesController.text.trim().isNotEmpty)
          'notes': _notesController.text.trim(),
      };

      final eventsDao = context.read<EventsDao>();
      await eventsDao.insertEvent(EventsCompanion(
        clientEventId: drift.Value(const Uuid().v4()),
        hiveId: drift.Value(widget.hiveId),
        siteId: drift.Value(_hive?.siteId),
        type: const drift.Value('inspection'),
        occurredAtLocal: drift.Value(now),
        occurredAtUtc: drift.Value(now.toUtc()),
        payload: drift.Value(jsonEncode(payload)),
        source: const drift.Value('manual'),
        syncStatus: const drift.Value('pending'),
      ));

      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.tr('inspection_saved')),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('error_saving')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l.tr('inspection'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${l.tr('inspect')} ${_hive?.displayName ?? l.tr('hive')}'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Brood
            _SectionTitle(title: l.tr('brood')),
            const SizedBox(height: 8),
            _OptionSelector(
              options: _broodOptions,
              selected: _brood,
              onChanged: (v) => setState(() => _brood = v),
              labelBuilder: (option) => l.tr(option),
            ),
            const SizedBox(height: 20),

            // Queen Seen
            _SectionTitle(title: l.tr('queen_seen')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _ToggleButton(
                    label: l.tr('yes'),
                    isSelected: _queenSeen,
                    onTap: () => setState(() => _queenSeen = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ToggleButton(
                    label: l.tr('no'),
                    isSelected: !_queenSeen,
                    onTap: () => setState(() => _queenSeen = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Queen Cells
            _SectionTitle(title: l.tr('queen_cells')),
            const SizedBox(height: 8),
            _OptionSelector(
              options: _queenCellOptions,
              selected: _queenCells,
              onChanged: (v) => setState(() => _queenCells = v),
              labelBuilder: (option) => l.tr(option),
            ),
            const SizedBox(height: 20),

            // Temperament
            _SectionTitle(title: l.tr('temperament')),
            const SizedBox(height: 8),
            _OptionSelector(
              options: _temperamentOptions,
              selected: _temperament,
              onChanged: (v) => setState(() => _temperament = v),
              labelBuilder: (option) => l.tr(option),
              colors: const {
                'calm': Colors.green,
                'normal': Colors.orange,
                'defensive': Colors.red,
              },
            ),
            const SizedBox(height: 20),

            // Stores
            _SectionTitle(title: l.tr('stores')),
            const SizedBox(height: 8),
            _OptionSelector(
              options: _storesOptions,
              selected: _stores,
              onChanged: (v) => setState(() => _stores = v),
              labelBuilder: (option) => l.tr(option),
              colors: const {
                'low': Colors.red,
                'medium': Colors.orange,
                'high': Colors.green,
              },
            ),
            const SizedBox(height: 20),

            // Supers
            _SectionTitle(title: l.tr('supers')),
            const SizedBox(height: 8),
            _OptionSelector(
              options: _supersOptions,
              selected: _supers,
              onChanged: (v) => setState(() => _supers = v),
              labelBuilder: (option) => l.tr(option),
            ),
            const SizedBox(height: 20),

            // Notes
            _SectionTitle(title: l.tr('notes')),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: l.tr('any_observations'),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),

            // Photo button (placeholder)
            OutlinedButton.icon(
              onPressed: () {
                final l = AppLocalizations.of(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.tr('photo_coming_soon'))),
                );
              },
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(l.tr('add_photo')),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save),
              label: Text(_isSaving ? l.tr('saving') : l.tr('save_inspection')),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
    );
  }
}

class _OptionSelector extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final Map<String, Color>? colors;
  final String Function(String)? labelBuilder;

  const _OptionSelector({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.colors,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = option == selected;
        final color = colors?[option] ?? Theme.of(context).colorScheme.primary;
        final label = labelBuilder != null
            ? labelBuilder!(option)
            : option[0].toUpperCase() + option.substring(1);
        return Material(
          color: isSelected ? color.withAlpha(30) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => onChanged(option),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minWidth: 80, minHeight: 48),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade300,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? color : Colors.grey[700],
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Material(
      color: isSelected ? color.withAlpha(30) : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
