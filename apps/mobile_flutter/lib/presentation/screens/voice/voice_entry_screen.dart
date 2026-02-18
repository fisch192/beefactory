import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../domain/voice/intent.dart';
import '../../../domain/voice/voice_service.dart';
import '../../../data/remote/events_api.dart';
import '../../../l10n/app_localizations.dart';
import '../community/community_feed_screen.dart';
import 'voice_confirmation_widget.dart';

/// Full voice entry screen with push-to-talk, language toggle, STT result
/// display, parsed intent confirmation, and action buttons.
class VoiceEntryScreen extends StatefulWidget {
  /// Optional pre-selected hive for context.
  final String? hiveId;

  const VoiceEntryScreen({super.key, this.hiveId});

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen>
    with SingleTickerProviderStateMixin {
  late final VoiceService _voiceService;
  late final AnimationController _pulseController;

  String _language = 'de';
  String _partialText = '';
  ParsedIntent? _intent;
  bool _editingFields = false;

  // Editable copies of intent fields for the edit mode.
  late Map<String, dynamic> _editableFields;

  StreamSubscription<String>? _partialSub;
  StreamSubscription<ParsedIntent>? _intentSub;
  StreamSubscription<String>? _errorSub;
  StreamSubscription<VoiceServiceState>? _stateSub;

  @override
  void initState() {
    super.initState();

    _voiceService = VoiceService();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _initVoiceService();
  }

  Future<void> _initVoiceService() async {
    final available = await _voiceService.initialize();
    if (!available && mounted) {
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('voice_not_available')),
          backgroundColor: Colors.red,
        ),
      );
    }

    _partialSub = _voiceService.partialResults.listen((text) {
      if (mounted) setState(() => _partialText = text);
    });

    _intentSub = _voiceService.intentResults.listen((intent) {
      if (mounted) {
        setState(() {
          _intent = intent;
          _editableFields = Map.of(intent.extractedFields);
        });
      }
    });

    _errorSub = _voiceService.errors.listen((error) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('error')}: $error'), backgroundColor: Colors.red),
        );
      }
    });

    _stateSub = _voiceService.stateStream.listen((state) {
      if (mounted) {
        setState(() {});
        if (state == VoiceServiceState.listening) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });
  }

  @override
  void dispose() {
    _partialSub?.cancel();
    _intentSub?.cancel();
    _errorSub?.cancel();
    _stateSub?.cancel();
    _pulseController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  String _statusText(AppLocalizations l) {
    switch (_voiceService.state) {
      case VoiceServiceState.idle:
        return l.tr('voice_ready');
      case VoiceServiceState.listening:
        return l.tr('voice_listening');
      case VoiceServiceState.processing:
        return l.tr('voice_processing');
    }
  }

  Color get _statusColor {
    switch (_voiceService.state) {
      case VoiceServiceState.idle:
        return Colors.grey;
      case VoiceServiceState.listening:
        return Colors.red;
      case VoiceServiceState.processing:
        return kHoneyAmber;
    }
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleListening() async {
    if (_voiceService.state == VoiceServiceState.listening) {
      await _voiceService.stopListening();
    } else if (_voiceService.state == VoiceServiceState.idle) {
      setState(() {
        _intent = null;
        _partialText = '';
        _editingFields = false;
      });
      await _voiceService.startListening(language: _language);
    }
  }

  Future<void> _retry() async {
    setState(() {
      _intent = null;
      _partialText = '';
      _editingFields = false;
    });
    await _voiceService.startListening(language: _language);
  }

  Future<void> _save() async {
    final intent = _intent;
    if (intent == null) return;

    final eventsApi = context.read<EventsApi>();
    final eventType = intent.backendEventType ?? 'NOTE';

    try {
      await eventsApi.createEvent({
        'type': eventType,
        if (widget.hiveId != null) 'hive_id': widget.hiveId,
        'payload': {
          ..._editableFields,
          'original_text': intent.originalText,
          'confidence': intent.confidence,
          'source': 'voice',
          if (intent.hiveRef != null) 'hive_ref': intent.hiveRef,
          if (intent.siteRef != null) 'site_ref': intent.siteRef,
          if (intent.targetDate != null)
            'target_date': intent.targetDate!.toIso8601String(),
        },
      });

      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('entry_saved')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('error')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveAsNote() async {
    final intent = _intent;
    if (intent == null) return;

    final eventsApi = context.read<EventsApi>();
    try {
      await eventsApi.createEvent({
        'type': 'NOTE',
        if (widget.hiveId != null) 'hive_id': widget.hiveId,
        'payload': {
          'text': intent.originalText,
          'source': 'voice',
          'low_confidence': true,
        },
      });

      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l.tr('entry_saved')),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l.tr('error')}: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.watch(context);
    final isListening = _voiceService.state == VoiceServiceState.listening;
    final isProcessing = _voiceService.state == VoiceServiceState.processing;

    return Scaffold(
      backgroundColor: kHoneyAmberSurface,
      appBar: AppBar(
        title: Text(l.tr('voice_entry')),
        backgroundColor: kHoneyAmber,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Language toggle
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'de', label: Text('DE')),
              ButtonSegment(value: 'it', label: Text('IT')),
            ],
            selected: {_language},
            onSelectionChanged: (selection) {
              setState(() => _language = selection.first);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }
                return kHoneyAmberDark;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return kHoneyAmber;
                }
                return Colors.white;
              }),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status indicator
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: _statusColor.withValues(alpha: 0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusText(l),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _statusColor,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const SizedBox(height: 24),

                    // Push-to-talk button
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final scale = isListening
                              ? 1.0 + _pulseController.value * 0.15
                              : 1.0;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: isListening
                                    ? Colors.red
                                    : isProcessing
                                        ? kHoneyAmber
                                        : kHoneyAmberDark,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isListening
                                            ? Colors.red
                                            : kHoneyAmber)
                                        .withValues(alpha: 0.4),
                                    blurRadius: isListening ? 20 : 8,
                                    spreadRadius: isListening ? 4 : 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                isListening
                                    ? Icons.stop
                                    : isProcessing
                                        ? Icons.hourglass_top
                                        : Icons.mic,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isListening
                          ? l.tr('voice_tap_stop')
                          : isProcessing
                              ? l.tr('voice_processing_wait')
                              : l.tr('voice_tap_speak'),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Partial transcript
                    if (isListening && _partialText.isNotEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _partialText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF3E2723),
                          ),
                        ),
                      ),

                    // Intent result
                    if (_intent != null) ...[
                      _buildResultSection(l),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(AppLocalizations l) {
    final intent = _intent!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Original transcript
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.tr('transcript'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  intent.originalText,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF3E2723),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Parsed intent summary
        if (intent.summary != null) ...[
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.tr('recognized_intent'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    intent.summary!,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF3E2723),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Confidence bar
        Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l.tr('confidence'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${(intent.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _confidenceColor(intent.confidence),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: intent.confidence,
                    backgroundColor: Colors.grey.withValues(alpha: 0.15),
                    color: _confidenceColor(intent.confidence),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Extracted fields as chips
        if (_editingFields) ...[
          _buildEditableFields(),
        ] else ...[
          VoiceConfirmationWidget(
            intent: intent,
            extractedFields: _editableFields,
            onEdit: () => setState(() => _editingFields = true),
          ),
        ],
        const SizedBox(height: 16),

        // Low confidence warning
        if (intent.isLowConfidence)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l.tr('low_confidence_warning'),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _saveAsNote,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: Text(l.tr('save_as_note')),
                  ),
                ),
              ],
            ),
          ),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(l.tr('nochmal')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: kHoneyAmberDark,
                  side: const BorderSide(color: kHoneyAmberLight),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon:
                    const Icon(Icons.close, size: 18, color: Colors.grey),
                label: Text(l.tr('cancel'),
                    style: const TextStyle(color: Colors.grey)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: Text(l.tr('save')),
            style: ElevatedButton.styleFrom(
              backgroundColor: kHoneyAmber,
              foregroundColor: Colors.white,
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
        const SizedBox(height: 8),
        if (_editingFields)
          SizedBox(
            height: 44,
            child: TextButton(
              onPressed: () => setState(() => _editingFields = false),
              child: Text(l.tr('stop_editing')),
            ),
          ),
      ],
    );
  }

  Widget _buildEditableFields() {
    final l = AppLocalizations.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit, size: 16, color: kHoneyAmber),
                const SizedBox(width: 4),
                Text(
                  l.tr('edit_fields'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ..._editableFields.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextFormField(
                  initialValue: entry.value.toString(),
                  decoration: InputDecoration(
                    labelText: entry.key,
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
                    isDense: true,
                  ),
                  onChanged: (value) {
                    _editableFields[entry.key] = value;
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
