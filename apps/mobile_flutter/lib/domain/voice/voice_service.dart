import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'intent.dart';
import 'voice_parser.dart';

/// Lifecycle state of the [VoiceService].
enum VoiceServiceState {
  /// No active recording or processing.
  idle,

  /// Microphone is active, streaming partial transcripts.
  listening,

  /// STT finished; running the [VoiceParser] on the final transcript.
  processing,
}

/// High-level service that wraps the `speech_to_text` plugin and
/// automatically pipes the final transcript through [VoiceParser].
///
/// Usage:
/// ```dart
/// final svc = VoiceService();
/// await svc.initialize();
///
/// svc.onPartialResult = (text) => print('Partial: $text');
/// svc.onFinalIntent  = (intent) => print('Intent:  $intent');
///
/// await svc.startListening(language: 'de');
/// // ... user speaks ...
/// await svc.stopListening();
/// ```
class VoiceService {
  VoiceService({
    SpeechToText? speechToText,
    VoiceParser? parser,
  })  : _stt = speechToText ?? SpeechToText(),
        _parser = parser ?? VoiceParser();

  final SpeechToText _stt;
  final VoiceParser _parser;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  VoiceServiceState _state = VoiceServiceState.idle;
  VoiceServiceState get state => _state;

  final StreamController<VoiceServiceState> _stateController =
      StreamController<VoiceServiceState>.broadcast();

  /// Stream of state changes.
  Stream<VoiceServiceState> get stateStream => _stateController.stream;

  // ---------------------------------------------------------------------------
  // Partial results
  // ---------------------------------------------------------------------------

  final StreamController<String> _partialController =
      StreamController<String>.broadcast();

  /// Stream of partial (intermediate) transcription results while the
  /// microphone is active.
  Stream<String> get partialResults => _partialController.stream;

  /// Optional callback for partial results (alternative to the stream).
  void Function(String partialText)? onPartialResult;

  // ---------------------------------------------------------------------------
  // Final intent
  // ---------------------------------------------------------------------------

  final StreamController<ParsedIntent> _intentController =
      StreamController<ParsedIntent>.broadcast();

  /// Stream that emits a [ParsedIntent] once the user stops speaking and the
  /// transcript has been parsed.
  Stream<ParsedIntent> get intentResults => _intentController.stream;

  /// Optional callback invoked with the final [ParsedIntent].
  void Function(ParsedIntent intent)? onFinalIntent;

  // ---------------------------------------------------------------------------
  // Error
  // ---------------------------------------------------------------------------

  final StreamController<String> _errorController =
      StreamController<String>.broadcast();

  /// Stream of error messages from the STT engine.
  Stream<String> get errors => _errorController.stream;

  /// Optional error callback.
  void Function(String error)? onError;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  bool _initialized = false;

  /// Initialize the speech-to-text engine. Must be called once before
  /// [startListening]. Returns `true` if the engine is available.
  Future<bool> initialize() async {
    _initialized = await _stt.initialize(
      onError: _handleError,
      onStatus: _handleStatus,
    );
    return _initialized;
  }

  /// Whether the STT engine was successfully initialised.
  bool get isAvailable => _initialized;

  /// Start listening for speech input.
  ///
  /// [language] should be a BCP-47 locale string, typically `'de-DE'` or
  /// `'it-IT'`. Short forms `'de'` and `'it'` are expanded automatically.
  ///
  /// Throws [StateError] if called while already listening or if the engine
  /// has not been initialised.
  Future<void> startListening({String language = 'de'}) async {
    if (!_initialized) {
      throw StateError('VoiceService not initialised. Call initialize() first.');
    }
    if (_state == VoiceServiceState.listening) {
      throw StateError('Already listening.');
    }

    final locale = _normalizeLocale(language);

    _setState(VoiceServiceState.listening);

    await _stt.listen(
      onResult: _handleResult,
      localeId: locale,
      listenMode: ListenMode.dictation,
      cancelOnError: true,
      partialResults: true,
    );
  }

  /// Stop listening and trigger final parsing.
  ///
  /// If the engine has already delivered a final result, this is a no-op
  /// on the STT side but will still ensure the state transitions correctly.
  Future<void> stopListening() async {
    if (_state != VoiceServiceState.listening) return;
    await _stt.stop();
    // If the STT engine already delivered a final result via the callback,
    // the state may have transitioned already. If not, we stay in listening
    // until the status callback fires.
  }

  /// Cancel the current listening session without producing a result.
  Future<void> cancel() async {
    await _stt.cancel();
    _setState(VoiceServiceState.idle);
  }

  /// Release resources. After calling this the service cannot be reused.
  void dispose() {
    _stateController.close();
    _partialController.close();
    _intentController.close();
    _errorController.close();
  }

  // ---------------------------------------------------------------------------
  // Internal callbacks
  // ---------------------------------------------------------------------------

  String _lastPartial = '';

  void _handleResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords;

    if (!result.finalResult) {
      _lastPartial = text;
      _partialController.add(text);
      onPartialResult?.call(text);
      return;
    }

    // Final result received.
    _setState(VoiceServiceState.processing);

    final transcript = text.isNotEmpty ? text : _lastPartial;
    _lastPartial = '';

    if (transcript.isEmpty) {
      _setState(VoiceServiceState.idle);
      return;
    }

    final intent = _parser.parse(transcript);
    _intentController.add(intent);
    onFinalIntent?.call(intent);

    _setState(VoiceServiceState.idle);
  }

  void _handleError(dynamic error) {
    final message = error is String ? error : error.toString();
    _errorController.add(message);
    onError?.call(message);
    _setState(VoiceServiceState.idle);
  }

  void _handleStatus(String status) {
    // The speech_to_text plugin fires status strings like
    // "listening", "notListening", "done".
    if (status == 'done' || status == 'notListening') {
      if (_state == VoiceServiceState.listening) {
        // If we haven't received a final result yet, just go idle.
        // A final result may still arrive via _handleResult.
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _setState(VoiceServiceState next) {
    if (_state == next) return;
    _state = next;
    _stateController.add(next);
  }

  String _normalizeLocale(String lang) {
    final l = lang.toLowerCase().trim();
    switch (l) {
      case 'de':
        return 'de-DE';
      case 'it':
        return 'it-IT';
      case 'en':
        return 'en-US';
      default:
        return l;
    }
  }
}
