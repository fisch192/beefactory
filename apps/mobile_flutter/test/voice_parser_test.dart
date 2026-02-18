import 'package:flutter_test/flutter_test.dart';

import 'package:bee_app/domain/voice/intent.dart';
import 'package:bee_app/domain/voice/number_words.dart';
import 'package:bee_app/domain/voice/voice_parser.dart';

void main() {
  // Fixed clock so date assertions are deterministic.
  // Wednesday 2026-02-18
  final fixedNow = DateTime(2026, 2, 18, 10, 0, 0);
  late VoiceParser parser;

  setUp(() {
    parser = VoiceParser(clock: () => fixedNow);
  });

  // ==========================================================================
  // German commands
  // ==========================================================================
  group('German commands', () {
    test('parses note for hive', () {
      final result =
          parser.parse('Notiz zu Volk 7: Brutbild gut, 2 Spielnäpfchen');
      expect(result.type, VoiceIntentType.note);
      expect(result.hiveRef, '7');
      expect(result.extractedFields['transcript'],
          'Brutbild gut, 2 Spielnäpfchen');
      expect(result.confidence, greaterThanOrEqualTo(0.5));
      expect(result.summary, contains('Note'));
      expect(result.summary, contains('hive 7'));
    });

    test('parses varroa measurement', () {
      final result =
          parser.parse('Volk 7 Varroa 3 pro Tag Windel 48 Stunden');
      expect(result.type, VoiceIntentType.varroaMeasurement);
      expect(result.hiveRef, '7');
      expect(result.extractedFields['mitesCount'], 3);
      expect(result.extractedFields['method'], 'sticky_board');
      expect(result.extractedFields['durationHours'], 48);
      expect(result.extractedFields['normalizedRate'], isNotNull);
      expect(result.confidence, greaterThanOrEqualTo(0.7));
    });

    test('parses varroa with alcohol wash', () {
      final result =
          parser.parse('Volk 3 Varroa 12 Alkoholwaschung');
      expect(result.type, VoiceIntentType.varroaMeasurement);
      expect(result.hiveRef, '3');
      expect(result.extractedFields['mitesCount'], 12);
      expect(result.extractedFields['method'], 'alcohol_wash');
    });

    test('parses feeding', () {
      final result =
          parser.parse('Volk 2 Fütterung 6 Kilo Sirup heute');
      expect(result.type, VoiceIntentType.feeding);
      expect(result.hiveRef, '2');
      expect(result.extractedFields['amount'], 6.0);
      expect(result.extractedFields['unit'], 'kg');
      expect(result.extractedFields['feedType'], 'syrup');
      expect(result.targetDate, DateTime(2026, 2, 18));
    });

    test('parses feeding with liters', () {
      final result =
          parser.parse('Volk 5 Fütterung 3 Liter Zuckersirup');
      expect(result.type, VoiceIntentType.feeding);
      expect(result.hiveRef, '5');
      expect(result.extractedFields['amount'], 3.0);
      expect(result.extractedFields['unit'], 'l');
      expect(result.extractedFields['feedType'], 'syrup');
    });

    test('parses treatment', () {
      final result = parser.parse('Volk 4 Behandlung Ameisensäure');
      expect(result.type, VoiceIntentType.treatment);
      expect(result.hiveRef, '4');
      expect(result.extractedFields['method'], 'formic');
    });

    test('parses treatment reminder with date', () {
      final result =
          parser.parse('Erinnerung Oxalsäure in 14 Tagen');
      expect(result.type, VoiceIntentType.reminder);
      expect(result.extractedFields['method'], 'oxalic');
      expect(result.targetDate, DateTime(2026, 3, 4));
      expect(result.extractedFields['dueAt'],
          DateTime(2026, 3, 4).toIso8601String());
      expect(result.confidence, greaterThanOrEqualTo(0.6));
    });

    test('parses site task', () {
      final result =
          parser.parse('Stand Meran Kontrolle nächste Woche');
      expect(result.type, VoiceIntentType.siteTask);
      expect(result.siteRef, 'Meran');
      // 2026-02-18 is Wednesday, so next Monday is 2026-02-23.
      expect(result.targetDate, DateTime(2026, 2, 23));
      expect(result.confidence, greaterThanOrEqualTo(0.7));
    });

    test('parses "morgen" as tomorrow', () {
      final result = parser.parse('Erinnerung Thymol morgen');
      expect(result.type, VoiceIntentType.reminder);
      expect(result.targetDate, DateTime(2026, 2, 19));
    });

    test('parses "übermorgen" as day after tomorrow', () {
      final result = parser.parse('Erinnerung Kontrolle übermorgen');
      expect(result.type, VoiceIntentType.reminder);
      expect(result.targetDate, DateTime(2026, 2, 20));
    });
  });

  // ==========================================================================
  // Italian commands
  // ==========================================================================
  group('Italian commands', () {
    test('parses note', () {
      final result =
          parser.parse('Nota per alveare 7: covata buona');
      expect(result.type, VoiceIntentType.note);
      expect(result.hiveRef, '7');
      expect(result.extractedFields['transcript'], 'covata buona');
    });

    test('parses varroa measurement', () {
      final result =
          parser.parse('Alveare 7 varroa 3 al giorno tavoletta 48 ore');
      expect(result.type, VoiceIntentType.varroaMeasurement);
      expect(result.hiveRef, '7');
      expect(result.extractedFields['mitesCount'], 3);
      expect(result.extractedFields['method'], 'sticky_board');
      expect(result.extractedFields['durationHours'], 48);
    });

    test('parses feeding', () {
      final result =
          parser.parse('Alveare 2 nutrizione 6 chili sciroppo oggi');
      expect(result.type, VoiceIntentType.feeding);
      expect(result.hiveRef, '2');
      expect(result.extractedFields['amount'], 6.0);
      expect(result.extractedFields['unit'], 'kg');
      expect(result.extractedFields['feedType'], 'syrup');
      expect(result.targetDate, DateTime(2026, 2, 18));
    });

    test('parses treatment', () {
      final result =
          parser.parse('Alveare 1 trattamento acido formico');
      expect(result.type, VoiceIntentType.treatment);
      expect(result.hiveRef, '1');
      expect(result.extractedFields['method'], 'formic');
    });

    test('parses treatment reminder', () {
      final result =
          parser.parse('Promemoria acido ossalico tra 14 giorni');
      expect(result.type, VoiceIntentType.reminder);
      expect(result.extractedFields['method'], 'oxalic');
      expect(result.targetDate, DateTime(2026, 3, 4));
    });

    test('parses site task', () {
      final result =
          parser.parse('Apiario Merano controllo la prossima settimana');
      expect(result.type, VoiceIntentType.siteTask);
      expect(result.siteRef, 'Merano');
      expect(result.targetDate, DateTime(2026, 2, 23));
    });

    test('parses "domani" as tomorrow', () {
      final result =
          parser.parse('Promemoria acido formico domani');
      expect(result.type, VoiceIntentType.reminder);
      expect(result.targetDate, DateTime(2026, 2, 19));
    });

    test('parses "tra X settimane"', () {
      final result =
          parser.parse('Promemoria controllo tra 2 settimane');
      expect(result.type, VoiceIntentType.reminder);
      expect(result.targetDate, DateTime(2026, 3, 4));
    });
  });

  // ==========================================================================
  // Edge cases
  // ==========================================================================
  group('Edge cases', () {
    test('written number words DE: "Volk sieben Varroa drei pro Tag"', () {
      final result =
          parser.parse('Volk sieben Varroa drei pro Tag Windel achtundvierzig Stunden');
      expect(result.type, VoiceIntentType.varroaMeasurement);
      expect(result.hiveRef, '7');
      expect(result.extractedFields['mitesCount'], 3);
      expect(result.extractedFields['durationHours'], 48);
    });

    test('written number words IT: "alveare sette varroa tre"', () {
      final result =
          parser.parse('Alveare sette varroa tre al giorno tavoletta quarantotto ore');
      expect(result.type, VoiceIntentType.varroaMeasurement);
      expect(result.hiveRef, '7');
      expect(result.extractedFields['mitesCount'], 3);
      expect(result.extractedFields['durationHours'], 48);
    });

    test('low confidence for ambiguous input', () {
      final result = parser.parse('Das Wetter war gut heute');
      expect(result.type, VoiceIntentType.unknown);
      expect(result.confidence, lessThan(0.6));
      expect(result.isLowConfidence, isTrue);
    });

    test('empty input returns unknown with zero confidence', () {
      final result = parser.parse('');
      expect(result.type, VoiceIntentType.unknown);
      expect(result.confidence, 0.0);
    });

    test('note takes priority over other matches', () {
      // "Notiz" keyword should win even if "varroa" is mentioned.
      final result = parser.parse('Notiz zu Volk 3: Varroa-Situation beobachten');
      expect(result.type, VoiceIntentType.note);
      expect(result.hiveRef, '3');
    });

    test('treatment without explicit method still classifies as treatment', () {
      final result = parser.parse('Volk 1 Behandlung durchgeführt');
      expect(result.type, VoiceIntentType.treatment);
      expect(result.hiveRef, '1');
    });

    test('feeding with fondant', () {
      final result = parser.parse('Volk 10 Fütterung 2 Kilo Futterteig');
      expect(result.type, VoiceIntentType.feeding);
      expect(result.hiveRef, '10');
      expect(result.extractedFields['feedType'], 'fondant');
      expect(result.extractedFields['amount'], 2.0);
    });

    test('mixed language still produces a result (best effort)', () {
      // German "Volk" + Italian "varroa ... al giorno"
      final result = parser.parse('Volk 5 varroa 4 al giorno');
      expect(result.type, VoiceIntentType.varroaMeasurement);
      expect(result.hiveRef, '5');
      expect(result.extractedFields['mitesCount'], 4);
    });

    test('toJson produces valid map', () {
      final result = parser.parse('Volk 7 Varroa 3 pro Tag Windel 48 Stunden');
      final json = result.toJson();
      expect(json['type'], 'varroaMeasurement');
      expect(json['confidence'], isA<double>());
      expect(json['hiveRef'], '7');
      expect(json['extractedFields'], isA<Map>());
      expect(json['originalText'], isNotEmpty);
    });

    test('backendEventType returns correct enum string', () {
      final note = parser.parse('Notiz zu Volk 1: test');
      expect(note.backendEventType, 'NOTE');

      final varroa = parser.parse('Volk 1 Varroa 3 Windel');
      expect(varroa.backendEventType, 'VARROA_MEASUREMENT');

      final feeding = parser.parse('Volk 1 Fütterung 2 Kilo Sirup');
      expect(feeding.backendEventType, 'FEEDING');

      final treatment = parser.parse('Volk 1 Oxalsäure');
      expect(treatment.backendEventType, 'TREATMENT');

      final reminder = parser.parse('Erinnerung morgen');
      expect(reminder.backendEventType, 'TASK_CREATED');

      final unknown = parser.parse('Hallo Welt');
      expect(unknown.backendEventType, isNull);
    });
  });

  // ==========================================================================
  // Number words unit tests
  // ==========================================================================
  group('Number words', () {
    test('parseNumberToken handles digit strings', () {
      expect(parseNumberToken('42'), 42);
      expect(parseNumberToken('0'), 0);
    });

    test('parseNumberToken handles German words', () {
      expect(parseNumberToken('eins'), 1);
      expect(parseNumberToken('zwölf'), 12);
      expect(parseNumberToken('dreißig'), 30);
      expect(parseNumberToken('hundert'), 100);
    });

    test('parseNumberToken handles Italian words', () {
      expect(parseNumberToken('uno'), 1);
      expect(parseNumberToken('dodici'), 12);
      expect(parseNumberToken('trenta'), 30);
      expect(parseNumberToken('cento'), 100);
    });

    test('parseNumberToken returns null for unrecognised input', () {
      expect(parseNumberToken('foobar'), isNull);
      expect(parseNumberToken(''), isNull);
    });
  });

  // ==========================================================================
  // ParsedIntent model tests
  // ==========================================================================
  group('ParsedIntent model', () {
    test('isLowConfidence threshold', () {
      const low = ParsedIntent(
        type: VoiceIntentType.unknown,
        confidence: 0.3,
        extractedFields: {},
        originalText: 'test',
      );
      expect(low.isLowConfidence, isTrue);

      const high = ParsedIntent(
        type: VoiceIntentType.note,
        confidence: 0.8,
        extractedFields: {},
        originalText: 'test',
      );
      expect(high.isLowConfidence, isFalse);
    });

    test('copyWith preserves and overrides fields', () {
      const original = ParsedIntent(
        type: VoiceIntentType.note,
        confidence: 0.7,
        extractedFields: {'a': 1},
        originalText: 'hello',
        hiveRef: '5',
      );
      final copy = original.copyWith(confidence: 0.9, hiveRef: '10');
      expect(copy.type, VoiceIntentType.note);
      expect(copy.confidence, 0.9);
      expect(copy.hiveRef, '10');
      expect(copy.originalText, 'hello');
      expect(copy.extractedFields, {'a': 1});
    });
  });
}
