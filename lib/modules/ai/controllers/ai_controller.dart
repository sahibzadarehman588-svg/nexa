import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/services/ai_service.dart';
import '../../../data/services/voice_service.dart';

class AIController extends GetxController {
  final AIService _aiService = AIService();
  final VoiceService _voiceService = VoiceService();

  // Reactive state
  final RxBool isLoading = false.obs;
  final RxBool isListening = false.obs;
  final RxBool isSpeaking = false.obs;
  final RxString currentInput = ''.obs;
  final RxList<AIChatMessage> messages = <AIChatMessage>[].obs;

  @override
  void onInit() {
    super.onInit();
    _initializeServices();
    _loadConversationHistory();
  }

  Future<void> _initializeServices() async {
    await _voiceService.initializeSpeech();
    await _voiceService.initializeTts();
  }

  void _loadConversationHistory() {
    messages.value = _aiService.conversationHistory;
  }

  /// Send text message to AI
  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    debugPrint('=== AI MESSAGE SEND DEBUG START ===');
    debugPrint('User message: $message');
    debugPrint('Is API configured: ${_aiService.isConfigured}');

    isLoading.value = true;
    currentInput.value = '';

    try {
      debugPrint('Calling _aiService.sendMessage...');
      final response = await _aiService.sendMessage(message);
      debugPrint('AI response received: $response');
      debugPrint('Conversation history length: ${_aiService.conversationHistory.length}');
      _loadConversationHistory();
      debugPrint('Messages in controller: ${messages.length}');
      debugPrint('=== AI MESSAGE SEND DEBUG END ===');
    } catch (e) {
      debugPrint('=== AI ERROR DEBUG ===');
      debugPrint('Error sending message: $e');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('=== AI ERROR DEBUG END ===');
      Get.snackbar(
        'Error',
        'Failed to get AI response: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Start voice input
  Future<void> startVoiceInput() async {
    if (isListening.value) {
      await stopVoiceInput();
      return;
    }

    // Request microphone permission
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      Get.snackbar(
        'Permission Required',
        'Microphone permission is required for voice input',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final success = await _voiceService.startListening();
    if (success) {
      isListening.value = true;
      
      // Listen to speech results
      _voiceService.speechResults.listen((text) {
        currentInput.value = text;
      });
    } else {
      Get.snackbar(
        'Error',
        'Failed to start voice recognition',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Stop voice input and send the message
  Future<void> stopVoiceInput() async {
    await _voiceService.stopListening();
    isListening.value = false;

    if (currentInput.value.trim().isNotEmpty) {
      await sendMessage(currentInput.value);
    }
  }

  /// Cancel voice input without sending
  Future<void> cancelVoiceInput() async {
    await _voiceService.cancelListening();
    isListening.value = false;
    currentInput.value = '';
  }

  /// Speak AI response
  Future<void> speakResponse(String text) async {
    if (isSpeaking.value) {
      await stopSpeaking();
      return;
    }

    isSpeaking.value = true;
    await _voiceService.speak(text);
    
    // Note: In a real implementation, you'd want to listen to TTS completion
    // to reset isSpeaking. For now, we'll use a simple delay.
    Future.delayed(Duration(milliseconds: text.length * 50), () {
      isSpeaking.value = false;
    });
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
    isSpeaking.value = false;
  }

  /// Clear conversation history
  void clearHistory() {
    _aiService.clearHistory();
    messages.clear();
  }

  /// Check if API is configured
  bool get isConfigured => _aiService.isConfigured;

  @override
  void onClose() {
    _voiceService.dispose();
    super.onClose();
  }
}
