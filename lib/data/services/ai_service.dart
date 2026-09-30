import 'dart:convert';
import 'package:http/http.dart' as http;

abstract class AIServiceInterface {
  Future<String> chat(String userMessage);
  Future<String> summarizeDocument(String text);
  Future<String> getProductSuggestions(String partialName);
  void configureApiKey(String apiKey);
}

class AIService implements AIServiceInterface {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String? _apiKey;
  String _baseUrl = 'https://api.openai.com/v1/chat/completions'; // Default to OpenAI, can be configured
  
  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty;

  @override
  void configureApiKey(String apiKey) {
    _apiKey = apiKey;
  }

  void configureBaseUrl(String baseUrl) {
    _baseUrl = baseUrl;
  }

  @override
  Future<String> chat(String userMessage) async {
    if (!isConfigured) {
      throw Exception('AI service is not configured. Please set the API key.');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'You are SAFA, a helpful AI assistant for managing products, expiry dates, and daily tasks. Provide concise and practical responses.',
            },
            {
              'role': 'user',
              'content': userMessage,
            },
          ],
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('AI service request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('AI chat failed: $e');
    }
  }

  @override
  Future<String> summarizeDocument(String text) async {
    if (!isConfigured) {
      throw Exception('AI service is not configured. Please set the API key.');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Summarize the following document text in a concise manner, highlighting key information.',
            },
            {
              'role': 'user',
              'content': text,
            },
          ],
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('AI service request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Document summarization failed: $e');
    }
  }

  @override
  Future<String> getProductSuggestions(String partialName) async {
    // This would typically call a different endpoint or use a different AI model
    // For now, return a simple response
    if (!isConfigured) {
      throw Exception('AI service is not configured. Please set the API key.');
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': 'Suggest 5 product names that start with or contain the given partial name. Return only the names, one per line.',
            },
            {
              'role': 'user',
              'content': partialName,
            },
          ],
          'max_tokens': 100,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('AI service request failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Product suggestions failed: $e');
    }
  }
}
