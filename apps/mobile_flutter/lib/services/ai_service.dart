import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ─── Config ──────────────────────────────────────────────────────────────────
const _kApiKey = 'OPENROUTER_API_KEY_HERE';
const _kModel = 'moonshotai/kimi-k2';
const _kVisionModel = 'meta-llama/llama-3.2-11b-vision-instruct:free';
const _kFreeLimit = 3;
const _kPremiumKey = 'ai_premium_v1';
const _kUsageKey = 'ai_usage_v1'; // JSON: {"date":"YYYY-MM-DD","count":N}

const _kSystemPrompt = '''
Du bist ein erfahrener Imker-Assistent und Bienenexperte.
Du hilfst Imkern bei:
- Analyse ihrer Tagebucheinträge und Inspektionen
- Früherkennung von Problemen (Varroa, Krankheiten, Schwarmstimmung)
- Personalisierten Fütterungsempfehlungen (je nach Saison, Wetterlage, Völkerstärke)
- Wetterbasierte Durchsichts-Empfehlungen
- Behandlungsplanung (Oxalsäure, Thymol, etc.)
- Bilderkennung: Krankheiten, Schädlinge, Bienenrassen auf Fotos
- Allgemeinen Imker-Fragen

Antworte immer auf Deutsch. Sei präzise, praxisnah und freundlich.
Nutze konkrete Zahlen und klare Handlungsempfehlungen.
Wenn dir Kontext-Daten zu den Völkern übergeben werden, nutze diese für personalisierte Antworten.
Wenn du dir bei etwas nicht sicher bist, sag es ehrlich.
''';

// ─── Context builder ─────────────────────────────────────────────────────────

class HiveContextData {
  final List<Map<String, dynamic>> hives;
  final List<Map<String, dynamic>> recentEvents; // {date, hive, type, summary}
  final List<Map<String, dynamic>> upcomingTasks; // {due, title}
  final Map<String, dynamic>? varroaSummary; // {hive, rate, trend}

  const HiveContextData({
    required this.hives,
    required this.recentEvents,
    required this.upcomingTasks,
    this.varroaSummary,
  });
}

// ─── Premium ─────────────────────────────────────────────────────────────────

class AiService {
  static Future<bool> isPremium() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kPremiumKey) ?? false;
  }

  static Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPremiumKey, value);
  }

  /// Returns remaining free requests today. -1 = premium (unlimited).
  static Future<int> remainingRequests() async {
    if (await isPremium()) return -1;
    final used = await _usedToday();
    return (_kFreeLimit - used).clamp(0, _kFreeLimit);
  }

  static Future<int> _usedToday() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kUsageKey);
    if (raw == null) return 0;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final today = _dateStr();
      if (map['date'] != today) return 0;
      return (map['count'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _incrementUsage() async {
    final prefs = await SharedPreferences.getInstance();
    final used = await _usedToday();
    await prefs.setString(
        _kUsageKey, jsonEncode({'date': _dateStr(), 'count': used + 1}));
  }

  static String _dateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ─── Context builder ───────────────────────────────────────────────────────

  /// Build a context string from hive data to enrich the AI system prompt.
  static String buildHiveContext(HiveContextData data) {
    final now = DateTime.now();
    final season = _season(now.month);
    final sb = StringBuffer();

    sb.writeln('=== DEINE IMKEREI-DATEN ===');
    sb.writeln(
        'Datum: ${now.day}.${now.month}.${now.year} | Saison: $season');
    sb.writeln();

    if (data.hives.isNotEmpty) {
      sb.writeln('DEINE VÖLKER (${data.hives.length}):');
      for (final h in data.hives) {
        sb.write('  • Volk #${h['number']}');
        if ((h['name'] as String?)?.isNotEmpty == true) {
          sb.write(' "${h['name']}"');
        }
        if (h['queen_year'] != null) sb.write(' | Königin ${h['queen_year']}');
        sb.writeln();
      }
      sb.writeln();
    }

    if (data.recentEvents.isNotEmpty) {
      sb.writeln('LETZTE EREIGNISSE (${data.recentEvents.length}):');
      for (final e in data.recentEvents) {
        sb.writeln(
            '  • ${e['date']} | ${e['hive']} | ${e['type']}: ${e['summary']}');
      }
      sb.writeln();
    }

    if (data.varroaSummary != null) {
      final v = data.varroaSummary!;
      sb.writeln('VARROA-STATUS:');
      sb.writeln(
          '  • ${v['hive']}: ${v['rate']} Milben/Tag | Trend: ${v['trend']}');
      sb.writeln();
    }

    if (data.upcomingTasks.isNotEmpty) {
      sb.writeln('ANSTEHENDE AUFGABEN:');
      for (final t in data.upcomingTasks) {
        sb.writeln('  • ${t['due']} – ${t['title']}');
      }
      sb.writeln();
    }

    sb.writeln('=== ENDE KONTEXT ===');
    return sb.toString();
  }

  static String _season(int month) {
    if (month >= 3 && month <= 5) return 'Frühling';
    if (month >= 6 && month <= 8) return 'Sommer';
    if (month >= 9 && month <= 11) return 'Herbst';
    return 'Winter';
  }

  // ─── Chat ─────────────────────────────────────────────────────────────────

  /// Sends a message and returns the assistant's reply.
  ///
  /// [hiveContext] optional context string injected into the system prompt.
  /// [imageBase64] optional base64-encoded image for vision queries.
  /// [imageMime] MIME type of the image (default: image/jpeg).
  ///
  /// Throws [AiLimitException] if free limit is reached.
  /// Throws [AiException] on API errors.
  static Future<String> chat({
    required List<Map<String, String>> history,
    required String userMessage,
    String? hiveContext,
    String? imageBase64,
    String imageMime = 'image/jpeg',
  }) async {
    final premium = await isPremium();
    if (!premium) {
      final used = await _usedToday();
      if (used >= _kFreeLimit) {
        throw AiLimitException(
            'Tageslimit erreicht ($_kFreeLimit Anfragen). '
            'Upgrade auf Premium für unlimitierte KI-Nutzung.');
      }
    }

    final isVision = imageBase64 != null;
    final model = isVision ? _kVisionModel : _kModel;

    final systemContent = hiveContext != null
        ? '$_kSystemPrompt\n\n$hiveContext'
        : _kSystemPrompt;

    // Build user content: text or multimodal array for vision
    final dynamic userContent = isVision
        ? [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$imageMime;base64,$imageBase64',
              },
            },
            {'type': 'text', 'text': userMessage},
          ]
        : userMessage;

    final messages = <Map<String, dynamic>>[
      {'role': 'system', 'content': systemContent},
      // History is always text-only
      for (final h in history) {'role': h['role']!, 'content': h['content']!},
      {'role': 'user', 'content': userContent},
    ];

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_kApiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://bee-app.example.com',
        'X-Title': 'BeeApp Imker-KI',
      },
      body: jsonEncode({
        'model': model,
        'messages': messages,
        'max_tokens': 1024,
        'temperature': 0.7,
      }),
    );

    if (response.statusCode != 200) {
      throw AiException(
          'API-Fehler ${response.statusCode}: ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final content = (data['choices'] as List?)
        ?.firstOrNull?['message']?['content'] as String?;

    if (content == null || content.isEmpty) {
      throw AiException('Leere Antwort vom KI-Modell');
    }

    await _incrementUsage();
    return content.trim();
  }
}

class AiLimitException implements Exception {
  final String message;
  const AiLimitException(this.message);
}

class AiException implements Exception {
  final String message;
  const AiException(this.message);
}
