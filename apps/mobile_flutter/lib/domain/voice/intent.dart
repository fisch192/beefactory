/// Voice intent types matching the backend EventType enum where applicable.
enum VoiceIntentType {
  note,
  varroaMeasurement,
  feeding,
  treatment,
  reminder,
  siteTask,
  inspection,
  unknown,
}

/// Result of parsing a voice transcript into a structured intent.
class ParsedIntent {
  final VoiceIntentType type;

  /// Confidence score between 0.0 and 1.0.
  /// Values below 0.6 are considered low confidence.
  final double confidence;

  /// Structured fields extracted from the transcript, keyed by field name.
  /// Contents depend on [type]:
  ///
  /// - NOTE: { transcript: String, parsedHints: String }
  /// - VARROA_MEASUREMENT: { method: String, durationHours: int?,
  ///     mitesCount: int?, normalizedRate: double? }
  /// - FEEDING: { feedType: String, amount: double?, unit: String? }
  /// - TREATMENT: { method: String, notes: String? }
  /// - REMINDER / SITE_TASK: { title: String, dueAt: String (ISO-8601) }
  final Map<String, dynamic> extractedFields;

  /// The original speech-to-text transcript.
  final String originalText;

  /// Hive number extracted from text, e.g. "7" from "Volk 7".
  final String? hiveRef;

  /// Site name extracted from text, e.g. "Meran" from "Stand Meran".
  final String? siteRef;

  /// Resolved target date (for reminders, tasks, etc.).
  final DateTime? targetDate;

  /// Human-readable summary suitable for a confirmation UI.
  final String? summary;

  const ParsedIntent({
    required this.type,
    required this.confidence,
    required this.extractedFields,
    required this.originalText,
    this.hiveRef,
    this.siteRef,
    this.targetDate,
    this.summary,
  });

  bool get isLowConfidence => confidence < 0.6;

  /// Serialise to JSON-compatible map (e.g. for API submission).
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'confidence': confidence,
        'extractedFields': extractedFields,
        'originalText': originalText,
        if (hiveRef != null) 'hiveRef': hiveRef,
        if (siteRef != null) 'siteRef': siteRef,
        if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
        if (summary != null) 'summary': summary,
      };

  /// Convenience: backend EventType string matching the schema enum.
  String? get backendEventType {
    switch (type) {
      case VoiceIntentType.note:
        return 'NOTE';
      case VoiceIntentType.varroaMeasurement:
        return 'VARROA_MEASUREMENT';
      case VoiceIntentType.feeding:
        return 'FEEDING';
      case VoiceIntentType.treatment:
        return 'TREATMENT';
      case VoiceIntentType.reminder:
        return 'TASK_CREATED';
      case VoiceIntentType.siteTask:
        return 'TASK_CREATED';
      case VoiceIntentType.inspection:
        return 'INSPECTION';
      case VoiceIntentType.unknown:
        return null;
    }
  }

  @override
  String toString() =>
      'ParsedIntent(type=$type, confidence=$confidence, hive=$hiveRef, '
      'site=$siteRef, date=$targetDate, fields=$extractedFields)';

  ParsedIntent copyWith({
    VoiceIntentType? type,
    double? confidence,
    Map<String, dynamic>? extractedFields,
    String? originalText,
    String? hiveRef,
    String? siteRef,
    DateTime? targetDate,
    String? summary,
  }) {
    return ParsedIntent(
      type: type ?? this.type,
      confidence: confidence ?? this.confidence,
      extractedFields: extractedFields ?? this.extractedFields,
      originalText: originalText ?? this.originalText,
      hiveRef: hiveRef ?? this.hiveRef,
      siteRef: siteRef ?? this.siteRef,
      targetDate: targetDate ?? this.targetDate,
      summary: summary ?? this.summary,
    );
  }
}
