import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  factory VoiceService() => _instance;
  VoiceService._internal();

  // Speech to Text
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeechInitialized = false;
  String _lastWords = '';
  final StreamController<String> _speechResultsController = StreamController<String>.broadcast();

  // Text to Speech
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;

  // Getters
  bool get isListening => _isListening;
  bool get isSpeechInitialized => _isSpeechInitialized;
  bool get isTtsInitialized => _isTtsInitialized;
  String get lastWords => _lastWords;
  Stream<String> get speechResults => _speechResultsController.stream;

  /// Initialize speech recognition
  Future<bool> initializeSpeech() async {
    if (_isSpeechInitialized) return true;

    try {
      _isSpeechInitialized = await _speechToText.initialize(
        onError: (error) {
          debugPrint('Speech recognition error: $error');
          _isListening = false;
        },
        onStatus: (status) {
          debugPrint('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            _isListening = false;
          }
        },
      );
      debugPrint('Speech recognition initialized: $_isSpeechInitialized');
      return _isSpeechInitialized;
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      return false;
    }
  }

  /// Initialize text-to-speech
  Future<bool> initializeTts() async {
    if (_isTtsInitialized) return true;

    try {
      await _flutterTts.setSharedInstance(true);
      _isTtsInitialized = true;
      
      // Configure TTS
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      
      debugPrint('Text-to-speech initialized: $_isTtsInitialized');
      return _isTtsInitialized;
    } catch (e) {
      debugPrint('Error initializing text-to-speech: $e');
      return false;
    }
  }

  /// Start listening to voice input
  Future<bool> startListening() async {
    if (!_isSpeechInitialized) {
      final initialized = await initializeSpeech();
      if (!initialized) {
        debugPrint('Failed to initialize speech recognition');
        return false;
      }
    }

    if (_isListening) {
      debugPrint('Already listening');
      return false;
    }

    try {
      await _speechToText.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          _speechResultsController.add(_lastWords);
          debugPrint('Speech result: $_lastWords');
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          autoPunctuation: true,
          partialResults: true,
          localeId: 'en_US',
          cancelOnError: true,
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
        ),
      );
      _isListening = true;
      debugPrint('Started listening');
      return true;
    } catch (e) {
      debugPrint('Error starting speech recognition: $e');
      return false;
    }
  }

  /// Stop listening to voice input
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      debugPrint('Stopped listening');
    } catch (e) {
      debugPrint('Error stopping speech recognition: $e');
    }
  }

  /// Cancel listening immediately
  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
      debugPrint('Cancelled listening');
    } catch (e) {
      debugPrint('Error cancelling speech recognition: $e');
    }
  }

  /// Speak text using text-to-speech
  Future<void> speak(String text) async {
    if (!_isTtsInitialized) {
      final initialized = await initializeTts();
      if (!initialized) {
        debugPrint('Failed to initialize text-to-speech');
        return;
      }
    }

    try {
      await _flutterTts.speak(text);
      debugPrint('Speaking: $text');
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    try {
      await _flutterTts.stop();
      debugPrint('Stopped speaking');
    } catch (e) {
      debugPrint('Error stopping speech: $e');
    }
  }

  /// Set speech rate (0.0 - 1.0)
  Future<void> setSpeechRate(double rate) async {
    try {
      await _flutterTts.setSpeechRate(rate);
    } catch (e) {
      debugPrint('Error setting speech rate: $e');
    }
  }

  /// Set language for TTS
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      debugPrint('Error setting language: $e');
    }
  }

  /// Get available languages for speech recognition
  Future<List<String>> getAvailableLanguages() async {
    if (!_isSpeechInitialized) {
      await initializeSpeech();
    }
    final locales = await _speechToText.locales();
    return locales.map((locale) => locale.localeId).toList();
  }

  /// Dispose resources
  void dispose() {
    _speechResultsController.close();
    _flutterTts.stop();
  }
}
