import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/ai_config.dart';

class AIChatMessage {
  final String role; // 'user' or 'model'
  final String content;
  final DateTime timestamp;

  AIChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final List<AIChatMessage> _conversationHistory = [];

  /// Check if API key is configured
  bool get isConfigured => AIConfig.isConfigured;

  /// Get conversation history
  List<AIChatMessage> get conversationHistory => List.unmodifiable(_conversationHistory);

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }

  /// Summarize document text
  Future<String> summarizeDocument(String text) async {
    if (!isConfigured) {
      return 'Error: Gemini API key is not configured. Please add your API key in lib/core/constants/ai_config.dart';
    }

    try {
      final prompt = '''Please summarize the following text concisely:

$text

Provide a brief summary in 2-3 sentences.''';

      // Use sendMessage without adding to conversation history
      final messages = [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        },
      ];

      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/${AIConfig.model}:generateContent?key=${AIConfig.geminiApiKey}'
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': messages,
          'generationConfig': {
            'temperature': AIConfig.temperature,
            'maxOutputTokens': AIConfig.maxTokens,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('ERROR: Document summarization API request timed out');
          throw Exception('Request timeout');
        },
      );

      debugPrint('Gemini API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
            final summary = content['parts'][0]['text'] as String;
            return summary;
          }
        }
        
        return 'Error: Invalid response format from API';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('Gemini API Error: ${errorData['error']['message']}');
        return 'Error: ${errorData['error']['message'] ?? 'Failed to get response from API'}';
      }
    } catch (e) {
      debugPrint('AIService Error: $e');
      return 'Error: Failed to connect to AI service. Please check your internet connection.';
    }
  }

  /// Send message to Gemini API and get response
  Future<String> sendMessage(String userMessage) async {
    debugPrint('=== AI SERVICE sendMessage START ===');
    debugPrint('isConfigured: $isConfigured');
    debugPrint('Model: ${AIConfig.model}');

    if (!isConfigured) {
      debugPrint('ERROR: API key not configured');
      return 'Error: Gemini API key is not configured. Please add your API key in lib/core/constants/ai_config.dart';
    }

    try {
      // Add user message to history
      _conversationHistory.add(AIChatMessage(
        role: 'user',
        content: userMessage,
      ));
      debugPrint('User message added to history. History length: ${_conversationHistory.length}');

      // Prepare messages for API
      final messages = [
        {
          'role': 'user',
          'parts': [
            {'text': AIConfig.systemPrompt}
          ]
        },
        for (final msg in _conversationHistory)
          {
            'role': msg.role,
            'parts': [
              {'text': msg.content}
            ]
          },
      ];
      debugPrint('Messages prepared for API. Total messages: ${messages.length}');

      // Make API request
      final apiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/${AIConfig.model}:generateContent?key=${AIConfig.geminiApiKey}';
      debugPrint('Sending API request to: ${AIConfig.model}');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': messages,
          'generationConfig': {
            'temperature': AIConfig.temperature,
            'maxOutputTokens': AIConfig.maxTokens,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('ERROR: API request timed out after 30 seconds');
          throw Exception('Request timeout');
        },
      );

      debugPrint('Gemini API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Response data keys: ${data.keys}');

        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final content = data['candidates'][0]['content'];
          if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
            final aiResponse = content['parts'][0]['text'] as String;
            debugPrint('AI Response received successfully');

            // Add AI response to history
            _conversationHistory.add(AIChatMessage(
              role: 'model',
              content: aiResponse,
            ));
            debugPrint('AI response added to history. History length: ${_conversationHistory.length}');

            debugPrint('=== AI SERVICE sendMessage SUCCESS ===');
            return aiResponse;
          }
        }

        debugPrint('ERROR: Invalid response format');
        return 'Error: Invalid response format from API';
      } else {
        final errorData = jsonDecode(response.body);
        debugPrint('ERROR: API request failed');
        debugPrint('Error message: ${errorData['error']['message']}');
        return 'Error: ${errorData['error']['message'] ?? 'Failed to get response from API'}';
      }
    } catch (e, stackTrace) {
      debugPrint('=== AI SERVICE EXCEPTION ===');
      debugPrint('Exception: $e');
      debugPrint('Exception type: ${e.runtimeType}');
      debugPrint('Stack trace: $stackTrace');
      debugPrint('=== AI SERVICE EXCEPTION END ===');
      return 'Error: Failed to connect to AI service. Please check your internet connection.';
    }
  }

  /// Stream response from Gemini API (for real-time typing effect)
  Stream<String> sendMessageStream(String userMessage) async* {
    if (!isConfigured) {
      yield 'Error: Gemini API key is not configured. Please add your API key in lib/core/constants/ai_config.dart';
      return;
    }

    try {
      // Add user message to history
      _conversationHistory.add(AIChatMessage(
        role: 'user',
        content: userMessage,
      ));

      // Prepare messages for API
      final messages = [
        {
          'role': 'user',
          'parts': [
            {'text': AIConfig.systemPrompt}
          ]
        },
        for (final msg in _conversationHistory)
          {
            'role': msg.role,
            'parts': [
              {'text': msg.content}
            ]
          },
      ];

      // Make API request
      final response = await http.post(
        Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/${AIConfig.model}:streamGenerateContent?key=${AIConfig.geminiApiKey}'
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': messages,
          'generationConfig': {
            'temperature': AIConfig.temperature,
            'maxOutputTokens': AIConfig.maxTokens,
          },
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('ERROR: Stream API request timed out');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final lines = response.body.split('\n');
        String fullResponse = '';

        for (final line in lines) {
          if (line.startsWith('data: ')) {
            try {
              final data = jsonDecode(line.substring(6));
              if (data['candidates'] != null && data['candidates'].isNotEmpty) {
                final content = data['candidates'][0]['content'];
                if (content != null && content['parts'] != null && content['parts'].isNotEmpty) {
                  final text = content['parts'][0]['text'] as String;
                  fullResponse += text;
                  yield text;
                }
              }
            } catch (e) {
              debugPrint('Error parsing stream chunk: $e');
            }
          }
        }

        // Add final AI response to history
        if (fullResponse.isNotEmpty) {
          _conversationHistory.add(AIChatMessage(
            role: 'model',
            content: fullResponse,
          ));
        }
      } else {
        final errorData = jsonDecode(response.body);
        yield 'Error: ${errorData['error']['message'] ?? 'Failed to get response from API'}';
      }
    } catch (e) {
      debugPrint('AIService Stream Error: $e');
      yield 'Error: Failed to connect to AI service. Please check your internet connection.';
    }
  }
}
