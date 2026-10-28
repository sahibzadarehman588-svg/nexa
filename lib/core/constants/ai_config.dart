/// AI Configuration
/// 
/// IMPORTANT: Replace 'YOUR_GEMINI_API_KEY_HERE' with your actual Google Gemini API key.
/// Get your API key from: https://makersuite.google.com/app/apikey
/// 
/// SECURITY NOTE: 
/// - Never commit your actual API key to version control
/// - In production, consider using environment variables or a secure backend
class AIConfig {
  /// Your Google Gemini API Key
  /// Get it from: https://makersuite.google.com/app/apikey
  static const String geminiApiKey = 'API KeyS';
  
  /// Check if API key is configured
  static bool get isConfigured {
    return geminiApiKey.isNotEmpty &&
           geminiApiKey != 'YOUR_GEMINI_API_KEY_HERE';
  }
  
  /// AI Model Configuration
  static const String model = 'gemini-3.8-flash';
  
  /// Temperature for response generation (0.0 - 1.0)
  /// Higher values = more creative, Lower values = more focused
  static const double temperature = 0.7;
  
  /// Maximum tokens in response
  static const int maxTokens = 1024;
  
  /// System prompt for AI assistant
  static const String systemPrompt = '''
You are NEXIA, a helpful and intelligent assistant. You are part of a productivity app that helps users manage tasks, inventory, expenses, and documents.

Your role is to:
- Help users with productivity questions
- Provide helpful suggestions for task management
- Assist with inventory and expense tracking
- Be friendly, concise, and practical
- Keep responses brief and actionable

If you don't know something specific about the user's data, ask them to provide more context.
''';
}
