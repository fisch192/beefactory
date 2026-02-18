import 'dart:math' show min;

import 'intent.dart';
import 'number_words.dart';

/// Rule-based voice intent parser supporting German and Italian.
///
/// Usage:
/// ```dart
/// final parser = VoiceParser();
/// final intent = parser.parse('Volk 7 Varroa 3 pro Tag Windel 48 Stunden');
/// ```
class VoiceParser {
  /// Reference date for resolving relative date expressions.
  /// Defaults to [DateTime.now] but can be overridden for testing.
  final DateTime Function() _clock;

  VoiceParser({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  // ---------------------------------------------------------------------------
  // Keyword tables
  // ---------------------------------------------------------------------------

  static const _varroaMethods = <String, String>{
    // DE
    'windel': 'sticky_board',
    'varroawindel': 'sticky_board',
    'bodeneinlage': 'sticky_board',
    'alkoholwaschung': 'alcohol_wash',
    'alkohol': 'alcohol_wash',
    'puderzucker': 'sugar_roll',
    // IT
    'tavoletta': 'sticky_board',
    'cassetto': 'sticky_board',
    'lavaggio alcool': 'alcohol_wash',
    'lavaggio': 'alcohol_wash',
    'zucchero a velo': 'sugar_roll',
  };

  static const _treatmentMethods = <String, String>{
    // DE
    'ameisensäure': 'formic',
    'ameisensaeure': 'formic',
    'oxalsäure': 'oxalic',
    'oxalsaeure': 'oxalic',
    'thymol': 'thymol',
    // IT
    'acido formico': 'formic',
    'acido ossalico': 'oxalic',
    'timolo': 'thymol',
  };

  static const _feedTypes = <String, String>{
    // DE
    'sirup': 'syrup',
    'zuckersirup': 'syrup',
    'futterteig': 'fondant',
    'zucker': 'sugar',
    'zuckerwasser': 'syrup',
    // IT
    'sciroppo': 'syrup',
    'candito': 'fondant',
    'zucchero': 'sugar',
  };

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Parse a speech-to-text transcript and return a structured [ParsedIntent].
  ParsedIntent parse(String transcript) {
    final text = transcript.trim();
    if (text.isEmpty) {
      return ParsedIntent(
        type: VoiceIntentType.unknown,
        confidence: 0.0,
        extractedFields: const {},
        originalText: text,
        summary: 'Empty input',
      );
    }

    final lower = text.toLowerCase();
    final tokens = _tokenize(lower);

    // --- Extract entities ---
    final hiveRef = _extractHiveRef(lower, tokens);
    final siteRef = _extractSiteRef(lower, tokens);
    final targetDate = _extractDate(lower, tokens);
    final quantity = _extractQuantity(lower, tokens);
    final duration = _extractDuration(lower, tokens);
    final varroaMethod = _extractVarroaMethod(lower);
    final treatmentMethod = _extractTreatmentMethod(lower);
    final feedType = _extractFeedType(lower);
    final miteCount = _extractMiteCount(lower, tokens);

    // --- Classify intent (priority order) ---
    VoiceIntentType type;
    Map<String, dynamic> fields;
    String? summary;

    if (_isNote(lower)) {
      type = VoiceIntentType.note;
      // Extract everything after "Notiz"/"Nota" colon or the whole text.
      final body = _extractNoteBody(text);
      fields = {
        'transcript': body,
        'parsedHints': body,
      };
      summary = 'Note${hiveRef != null ? ' for hive $hiveRef' : ''}: $body';
    } else if (_isVarroaMeasurement(lower, miteCount, varroaMethod)) {
      type = VoiceIntentType.varroaMeasurement;
      final durationHours = duration;
      double? normalizedRate;
      if (miteCount != null && durationHours != null && durationHours > 0) {
        normalizedRate =
            (miteCount / (durationHours / 24.0) * 100).roundToDouble() / 100;
      }
      fields = {
        'method': varroaMethod ?? 'unknown',
        if (durationHours != null) 'durationHours': durationHours,
        if (miteCount != null) 'mitesCount': miteCount,
        if (normalizedRate != null) 'normalizedRate': normalizedRate,
      };
      summary =
          'Varroa measurement${hiveRef != null ? ' hive $hiveRef' : ''}: '
          '${miteCount ?? '?'} mites'
          '${varroaMethod != null ? ' ($varroaMethod)' : ''}'
          '${durationHours != null ? ' over ${durationHours}h' : ''}';
    } else if (_isFeeding(lower, feedType, quantity)) {
      type = VoiceIntentType.feeding;
      fields = {
        'feedType': feedType ?? 'unknown',
        if (quantity != null) 'amount': quantity.amount,
        if (quantity != null) 'unit': quantity.unit,
      };
      summary = 'Feeding${hiveRef != null ? ' hive $hiveRef' : ''}: '
          '${quantity != null ? '${quantity.amount} ${quantity.unit} ' : ''}'
          '${feedType ?? 'unknown'}';
    } else if (_isReminder(lower)) {
      // Reminder MUST be checked before treatment, because
      // "Erinnerung Oxalsäure in 14 Tagen" is a reminder about a future
      // treatment, not a treatment event itself.
      type = VoiceIntentType.reminder;
      final title = _extractReminderTitle(text, lower);
      fields = {
        'title': title,
        if (targetDate != null) 'dueAt': targetDate.toIso8601String(),
        if (treatmentMethod != null) 'method': treatmentMethod,
      };
      summary = 'Reminder: $title'
          '${targetDate != null ? ' on ${_formatDate(targetDate)}' : ''}';
    } else if (_isTreatment(lower, treatmentMethod)) {
      type = VoiceIntentType.treatment;
      fields = {
        'method': treatmentMethod ?? 'unknown',
        'notes': text,
      };
      summary =
          'Treatment${hiveRef != null ? ' hive $hiveRef' : ''}: $treatmentMethod';
    } else if (_isSiteTask(lower, siteRef)) {
      type = VoiceIntentType.siteTask;
      final title =
          'Site check: ${siteRef ?? 'unknown'}';
      fields = {
        'title': title,
        if (targetDate != null) 'dueAt': targetDate.toIso8601String(),
      };
      summary = '$title'
          '${targetDate != null ? ' on ${_formatDate(targetDate)}' : ''}';
    } else {
      type = VoiceIntentType.unknown;
      fields = {
        'transcript': text,
        'parsedHints': text,
      };
      summary = 'Unrecognised command – saved as note';
    }

    // --- Confidence scoring ---
    double confidence = 0.0;
    if (type != VoiceIntentType.unknown) {
      confidence = 0.5;
      if (hiveRef != null || siteRef != null) confidence += 0.2;
      if (targetDate != null) confidence += 0.1;
      if (quantity != null) confidence += 0.1;
      if (varroaMethod != null ||
          treatmentMethod != null ||
          feedType != null) {
        confidence += 0.1;
      }
      confidence = min(confidence, 1.0);
    } else {
      // Unknown: base low confidence
      confidence = 0.3;
      if (hiveRef != null || siteRef != null) confidence += 0.1;
    }

    return ParsedIntent(
      type: type,
      confidence: confidence,
      extractedFields: fields,
      originalText: text,
      hiveRef: hiveRef,
      siteRef: siteRef,
      targetDate: targetDate,
      summary: summary,
    );
  }

  // ---------------------------------------------------------------------------
  // Tokenisation
  // ---------------------------------------------------------------------------

  List<String> _tokenize(String lower) {
    // Split on whitespace and common punctuation, keep non-empty tokens.
    return lower
        .replaceAll(RegExp(r'[,;!?]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Entity extraction helpers
  // ---------------------------------------------------------------------------

  /// Extracts hive reference from patterns like "Volk 7", "Volk sieben",
  /// "Alveare 7", "alveare sette".
  String? _extractHiveRef(String lower, List<String> tokens) {
    // Patterns: volk <number>, alveare <number>
    final patterns = [
      RegExp(r'\bvolk\s+(\S+)'),
      RegExp(r'\balveare\s+(\S+)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final raw = match.group(1)!;
        final number = parseNumberToken(raw);
        if (number != null) return number.toString();
        // If it is not a recognisable number, return it raw (might be a name).
        return raw;
      }
    }
    return null;
  }

  /// Extracts site reference from "Stand X" (DE) or "Apiario X" (IT).
  String? _extractSiteRef(String lower, List<String> tokens) {
    final patterns = [
      RegExp(r'\bstand\s+(\S+)'),
      RegExp(r'\bapiario\s+(\S+)'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(lower);
      if (match != null) {
        final raw = match.group(1)!;
        // Capitalise first letter for display.
        return raw[0].toUpperCase() + raw.substring(1);
      }
    }
    return null;
  }

  /// Resolves relative date expressions to an absolute [DateTime].
  DateTime? _extractDate(String lower, List<String> tokens) {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);

    // "heute" / "oggi"
    if (lower.contains('heute') || lower.contains('oggi')) {
      return today;
    }

    // "übermorgen" / "dopodomani"  (must check before "morgen"/"domani")
    if (lower.contains('übermorgen') ||
        lower.contains('uebermorgen') ||
        lower.contains('dopodomani')) {
      return today.add(const Duration(days: 2));
    }

    // "morgen" / "domani"
    if (lower.contains('morgen') || lower.contains('domani')) {
      return today.add(const Duration(days: 1));
    }

    // "in X Tagen" / "tra X giorni"
    final daysPattern = RegExp(r'\b(?:in|tra)\s+(\S+)\s+(?:tagen?|giorni)\b');
    final daysMatch = daysPattern.firstMatch(lower);
    if (daysMatch != null) {
      final n = parseNumberToken(daysMatch.group(1)!);
      if (n != null) return today.add(Duration(days: n));
    }

    // "in X Wochen" / "tra X settimane"
    final weeksPattern =
        RegExp(r'\b(?:in|tra)\s+(\S+)\s+(?:wochen?|settimane?)\b');
    final weeksMatch = weeksPattern.firstMatch(lower);
    if (weeksMatch != null) {
      final n = parseNumberToken(weeksMatch.group(1)!);
      if (n != null) return today.add(Duration(days: n * 7));
    }

    // "nächste Woche" / "la prossima settimana" / "prossima settimana"
    if (RegExp(r'\bn[äa]chste\s+woche\b').hasMatch(lower) ||
        lower.contains('prossima settimana')) {
      // Next Monday
      final daysUntilMonday = (DateTime.monday - today.weekday + 7) % 7;
      final offset = daysUntilMonday == 0 ? 7 : daysUntilMonday;
      return today.add(Duration(days: offset));
    }

    return null;
  }

  /// Extracts quantity + unit from patterns like "6 Kilo", "3 Liter",
  /// "6 chili", "3 litri".
  _Quantity? _extractQuantity(String lower, List<String> tokens) {
    final pattern = RegExp(
        r'\b(\S+)\s+(?:kilo(?:gramm)?|kg|chili|litri?|liter|l)\b');
    final match = pattern.firstMatch(lower);
    if (match != null) {
      final raw = match.group(1)!;
      final number = _parseDouble(raw);
      if (number != null) {
        final unitRaw = match.group(0)!;
        final unit =
            unitRaw.contains(RegExp(r'liter|litri?|\bl\b')) ? 'l' : 'kg';
        return _Quantity(number, unit);
      }
    }
    return null;
  }

  /// Extracts duration in hours from "X Stunden" / "X ore".
  int? _extractDuration(String lower, List<String> tokens) {
    final pattern = RegExp(r'\b(\S+)\s+(?:stunden?|ore)\b');
    final match = pattern.firstMatch(lower);
    if (match != null) {
      final raw = match.group(1)!;
      final number = parseNumberToken(raw);
      return number;
    }
    return null;
  }

  /// Finds the varroa measurement method keyword.
  String? _extractVarroaMethod(String lower) {
    // Check multi-word phrases first, then single words.
    for (final entry in _varroaMethods.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Finds the treatment method keyword.
  String? _extractTreatmentMethod(String lower) {
    for (final entry in _treatmentMethods.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Finds the feed type keyword.
  String? _extractFeedType(String lower) {
    for (final entry in _feedTypes.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }

  /// Extracts mite count from "varroa X pro Tag" / "varroa X al giorno"
  /// or simply "varroa X".
  int? _extractMiteCount(String lower, List<String> tokens) {
    // "varroa X pro tag" / "varroa X al giorno"
    final ratePattern =
        RegExp(r'\bvarroa\s+(\S+)(?:\s+(?:pro\s+tag|al\s+giorno))?\b');
    final match = ratePattern.firstMatch(lower);
    if (match != null) {
      final raw = match.group(1)!;
      final n = parseNumberToken(raw);
      if (n != null) return n;
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Intent classification helpers
  // ---------------------------------------------------------------------------

  bool _isNote(String lower) {
    return RegExp(r'\b(?:notiz|nota)\b').hasMatch(lower);
  }

  bool _isVarroaMeasurement(
      String lower, int? miteCount, String? varroaMethod) {
    // Must mention "varroa" and have at least mite count or method.
    if (!lower.contains('varroa')) return false;
    return miteCount != null || varroaMethod != null;
  }

  bool _isFeeding(String lower, String? feedType, _Quantity? quantity) {
    final hasFeedingKeyword = RegExp(
            r'\b(?:fütterung|fuetterung|futter|nutrizione|alimentazione)\b')
        .hasMatch(lower);
    return (hasFeedingKeyword || feedType != null) &&
        (quantity != null || feedType != null);
  }

  bool _isTreatment(String lower, String? treatmentMethod) {
    final hasTreatmentKeyword =
        RegExp(r'\b(?:behandlung|trattamento)\b').hasMatch(lower);
    return treatmentMethod != null || hasTreatmentKeyword;
  }

  bool _isReminder(String lower) {
    return RegExp(r'\b(?:erinnerung|promemoria|reminder)\b').hasMatch(lower);
  }

  bool _isSiteTask(String lower, String? siteRef) {
    final hasControlKeyword =
        RegExp(r'\b(?:kontrolle|controllo)\b').hasMatch(lower);
    return siteRef != null && hasControlKeyword;
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _extractNoteBody(String text) {
    // Try to extract body after "Notiz ... :" or "Nota ... :"
    final colonIdx = text.indexOf(':');
    if (colonIdx >= 0 && colonIdx < text.length - 1) {
      return text.substring(colonIdx + 1).trim();
    }
    // Remove the leading "Notiz zu Volk X" / "Nota per alveare X" prefix.
    final cleaned = text
        .replaceFirst(
            RegExp(r'^(?:notiz|nota)\s+(?:zu|per|für|fuer)?\s*',
                caseSensitive: false),
            '')
        .trim();
    return cleaned.isNotEmpty ? cleaned : text;
  }

  String _extractReminderTitle(String text, String lower) {
    // Remove the "Erinnerung"/"Promemoria"/"Reminder" prefix and date parts.
    var title = text;
    title = title.replaceFirst(
        RegExp(r'^(?:erinnerung|promemoria|reminder)\s*',
            caseSensitive: false),
        '');
    // Remove date tokens like "in 14 Tagen", "tra 14 giorni",
    // "nächste Woche", etc.
    title = title
        .replaceAll(
            RegExp(
                r'\b(?:in|tra)\s+\S+\s+(?:tagen?|giorni|wochen?|settimane?)\b',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(r'\bn[äa]chste\s+woche\b', caseSensitive: false), '')
        .replaceAll(
            RegExp(r'\b(?:la\s+)?prossima\s+settimana\b',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(r'\b(?:heute|morgen|übermorgen|oggi|domani|dopodomani)\b',
                caseSensitive: false),
            '')
        .trim();
    // Clean up extra whitespace.
    title = title.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return title.isNotEmpty ? title : text;
  }

  double? _parseDouble(String raw) {
    final d = double.tryParse(raw.replaceAll(',', '.'));
    if (d != null) return d;
    final asInt = parseNumberToken(raw);
    return asInt?.toDouble();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Internal quantity value object.
class _Quantity {
  final double amount;
  final String unit;
  const _Quantity(this.amount, this.unit);
}
