import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../domain/models/hive.dart';
import '../../../domain/repositories/hive_repository.dart';
import '../../../l10n/app_localizations.dart';

class CreateHiveScreen extends StatefulWidget {
  final int siteId;

  const CreateHiveScreen({super.key, required this.siteId});

  @override
  State<CreateHiveScreen> createState() => _CreateHiveScreenState();
}

class _CreateHiveScreenState extends State<CreateHiveScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  final _nameController = TextEditingController();
  final _queenYearController = TextEditingController();
  final _notesController = TextEditingController();

  String? _queenColor;
  bool _queenMarked = false;
  bool _isSaving = false;

  static const _queenColors = [
    'White',
    'Yellow',
    'Red',
    'Green',
    'Blue',
  ];

  @override
  void dispose() {
    _numberController.dispose();
    _nameController.dispose();
    _queenYearController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final hive = HiveModel(
      siteId: widget.siteId,
      number: int.parse(_numberController.text.trim()),
      name: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : null,
      queenYear: int.tryParse(_queenYearController.text.trim()),
      queenColor: _queenColor?.toLowerCase(),
      queenMarked: _queenMarked,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    try {
      await context.read<HiveRepository>().create(hive);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('error')}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.tr('new_hive')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: '${l.tr('hive_number')} *',
                  hintText: 'e.g. 1',
                  prefixIcon: const Icon(Icons.tag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l.tr('error_required_field');
                  }
                  if (int.tryParse(value.trim()) == null) {
                    return l.tr('error_valid_number');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l.tr('name_optional'),
                  hintText: 'e.g. Sunny Side',
                  prefixIcon: const Icon(Icons.label_outlined),
                ),
              ),
              const SizedBox(height: 24),

              // Queen info section
              Text(
                l.tr('queen_info'),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _queenYearController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l.tr('queen_year'),
                  hintText: 'e.g. 2024',
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final year = int.tryParse(value);
                    if (year == null || year < 2000 || year > 2030) {
                      return l.tr('error_valid_year');
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _queenColor,
                decoration: InputDecoration(
                  labelText: l.tr('queen_color'),
                  prefixIcon: const Icon(Icons.palette_outlined),
                ),
                items: _queenColors
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _colorFromName(c),
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.grey, width: 1),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(c),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() => _queenColor = value);
                },
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: Text(l.tr('queen_marked')),
                value: _queenMarked,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) {
                  setState(() => _queenMarked = value);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: l.tr('notes'),
                  hintText: l.tr('any_additional_info'),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l.tr('save_hive')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _colorFromName(String name) {
    switch (name.toLowerCase()) {
      case 'white':
        return Colors.white;
      case 'yellow':
        return Colors.yellow;
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
