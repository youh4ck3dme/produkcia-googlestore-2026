import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceCaptureService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('Speech recognition error: $error'),
        onStatus: (status) => debugPrint('Speech recognition status: $status'),
        debugLogging: kDebugMode,
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech recognition: $e');
      return false;
    }
  }

  /// Check if speech recognition is available on this device
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _speechToText.isAvailable;
  }

  /// Listen for speech input with timeout
  Future<String?> listenForExpense({
    Duration timeout = const Duration(seconds: 30),
    String language = 'sk-SK',
    Function(String)? onPartialResult,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    final completer = Completer<String?>();
    String finalResult = '';
    bool hasFinalResult = false;

    _speechToText.listen(
      onResult: (result) {
        final recognizedWords = result.recognizedWords.trim();
        if (recognizedWords.isNotEmpty) {
          finalResult = recognizedWords;
          onPartialResult?.call(finalResult);
        }

        if (result.finalResult) {
          hasFinalResult = true;
          completer.complete(finalResult.isNotEmpty ? finalResult : null);
        }
      },
      listenFor: timeout,
      pauseFor: const Duration(seconds: 5),
      localeId: language,
      onSoundLevelChange: (level) {
        // Could be used for visual feedback
      },
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      ),
    );

    // Set up timeout
    Timer(timeout, () {
      if (!completer.isCompleted) {
        _speechToText.stop();
        completer.complete(hasFinalResult && finalResult.isNotEmpty ? finalResult : null);
      }
    });

    return completer.future;
  }

  /// Stop listening
  void stopListening() {
    _speechToText.stop();
  }

  /// Cancel listening
  void cancelListening() {
    _speechToText.cancel();
  }



  /// Check if currently listening
  bool get isListening => _speechToText.isListening;

  /// Clean up resources
  void dispose() {
    _speechToText.cancel();
    _isInitialized = false;
  }
}

// Provider for the voice capture service
final voiceCaptureServiceProvider = Provider<VoiceCaptureService>((ref) {
  final service = VoiceCaptureService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
