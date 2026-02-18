import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/community_provider.dart';
import 'community_feed_screen.dart';

/// Modal dialog for importing a community comment into the user's diary.
///
/// Allows choosing the import type (NOTE, TASK, TREATMENT, VARROA_MEASUREMENT)
/// and prefills relevant fields from the comment text.
class ImportDialog extends StatefulWidget {
  final String commentId;
  final String commentBody;
  final String commentAuthor;

  const ImportDialog({
    super.key,
    required this.commentId,
    required this.commentBody,
    required this.commentAuthor,
  });

  /// Show the import dialog as a modal bottom sheet and return true if
  /// the import was successful.
  static Future<bool?> show(
    BuildContext context, {
    required String commentId,
    required String commentBody,
    required String commentAuthor,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ImportDialog(
        commentId: commentId,
        commentBody: commentBody,
        commentAuthor: commentAuthor,
      ),
    );
  }

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  ImportType _selectedType = ImportType.note;
  final _hiveIdController = TextEditingController();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  bool _importing = false;
  bool _didPrefill = false;

  @override
  void initState() {
    super.initState();
    // Prefill the notes field with the comment body.
    _notesController.text = widget.commentBody;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didPrefill) {
      _didPrefill = true;
      final l = AppLocalizations.of(context);
      _titleController.text =
          '${l.tr('from_community')} ${widget.commentBody.length > 50 ? '${widget.commentBody.substring(0, 50)}...' : widget.commentBody}';
    }
  }

  @override
  void dispose() {
    _hiveIdController.dispose();
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  IconData _iconForType(ImportType type) {
    switch (type) {
      case ImportType.note:
        return Icons.edit_note;
      case ImportType.task:
        return Icons.task_alt;
      case ImportType.treatment:
        return Icons.medical_services;
      case ImportType.varroaMeasurement:
        return Icons.bug_report;
    }
  }

  String _labelForType(ImportType type, AppLocalizations l) {
    switch (type) {
      case ImportType.note:
        return l.tr('note');
      case ImportType.task:
        return l.tr('task_title');
      case ImportType.treatment:
        return l.tr('treatment');
      case ImportType.varroaMeasurement:
        return l.tr('varroa_measurement');
    }
  }

  Future<void> _doImport() async {
    final l = AppLocalizations.of(context);
    if (_hiveIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('enter_hive_id')),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _importing = true);

    final additionalFields = <String, dynamic>{};

    switch (_selectedType) {
      case ImportType.note:
        additionalFields['text'] = _notesController.text.trim();
      case ImportType.task:
        additionalFields['title'] = _titleController.text.trim();
        additionalFields['description'] = _notesController.text.trim();
      case ImportType.treatment:
        additionalFields['notes'] = _notesController.text.trim();
      case ImportType.varroaMeasurement:
        additionalFields['notes'] = _notesController.text.trim();
    }

    final provider = context.read<CommunityProvider>();
    final success = await provider.importToDiary(
      commentId: widget.commentId,
      commentBody: widget.commentBody,
      importType: _selectedType,
      hiveId: _hiveIdController.text.trim(),
      additionalFields: additionalFields,
    );

    if (!mounted) return;

    setState(() => _importing = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('import_success')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.postError ?? l.tr('import_error')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
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
            const SizedBox(height: 16),

            // Title
            Text(
              l.tr('import_to_diary'),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Kommentar von ${widget.commentAuthor}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 20),

            // Source text preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kHoneyAmberSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: kHoneyAmberLight.withValues(alpha: 0.3)),
              ),
              child: Text(
                widget.commentBody,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 20),

            // Import type selection
            Text(
              l.tr('choose_import_type'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3E2723),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ImportType.values.map((type) {
                final selected = type == _selectedType;
                return ChoiceChip(
                  avatar: Icon(
                    _iconForType(type),
                    size: 18,
                    color: selected ? Colors.white : kHoneyAmberDark,
                  ),
                  label: Text(_labelForType(type, l)),
                  selected: selected,
                  selectedColor: kHoneyAmber,
                  backgroundColor: Colors.grey[100],
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.grey[800],
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  onSelected: (_) => setState(() => _selectedType = type),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Hive ID field
            TextFormField(
              controller: _hiveIdController,
              decoration: InputDecoration(
                labelText: l.tr('hive_id_required'),
                hintText: l.tr('hive_id_hint'),
                prefixIcon: const Icon(Icons.hive, color: kHoneyAmber),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kHoneyAmber, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Title field (for tasks)
            if (_selectedType == ImportType.task) ...[
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l.tr('task_title'),
                  prefixIcon:
                      const Icon(Icons.title, color: kHoneyAmber),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: kHoneyAmber, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: _selectedType == ImportType.note
                    ? l.tr('note_text')
                    : l.tr('remarks'),
                filled: true,
                fillColor: Colors.grey[50],
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
            ),
            const SizedBox(height: 24),

            // Import button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _importing ? null : _doImport,
                icon: _importing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(_iconForType(_selectedType)),
                label: Text(_importing
                    ? l.tr('importing')
                    : l.tr('import_as').replaceAll('{type}', _labelForType(_selectedType, l))),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kHoneyAmber,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      kHoneyAmber.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
