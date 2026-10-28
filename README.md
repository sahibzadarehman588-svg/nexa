# NEXIA - Next-Generation Intelligent Assistant

> One App. One Intelligent Assistant.

NEXIA is a production-quality Flutter application that combines Firebase services, AI capabilities, and smart management features into a unified productivity platform.

## Features

### Core Features
- **Authentication**: Secure Firebase Auth with email/password, signup, logout, and password reset
- **Product Management**: Full CRUD operations with image upload, categories, and expiry tracking
- **Smart Scanner**: OCR-powered product scanning with automatic data extraction
- **Expiry Management**: Track expired and expiring products with notifications
- **Inventory Overview**: Comprehensive statistics, health scores, and category breakdowns
- **Task Management**: Create, edit, complete, and delete tasks with priority and due dates
- **Dashboard**: Real-time statistics and quick access to all features

### AI Features
- **AI Chat Assistant**: Context-aware AI assistant using your actual Firebase data
- **Voice AI Assistant**: Speech-to-text and text-to-speech for hands-free interaction
- **Document AI**: OCR text extraction with AI-powered summarization
- **Receipt Scanner**: Intelligent receipt parsing with item extraction and AI analysis

## Technology Stack

- **Framework**: Flutter 3.10.4+
- **State Management**: GetX 4.6.6
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **AI**: OpenAI-compatible API integration
- **OCR**: Google ML Kit Text Recognition
- **Speech**: speech_to_text, flutter_tts
- **Notifications**: flutter_local_notifications

## Getting Started

### Prerequisites
- Flutter SDK 3.10.4 or higher
- Dart SDK 3.10.4 or higher
- Firebase project with enabled services
- OpenAI API key (for AI features)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd nexa
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   - Add Android/iOS/Web apps to your Firebase project
   - Download `google-services.json` (Android) or `GoogleService-Info.plist` (iOS)
   - Place configuration files in the appropriate platform directories
   - Run: `flutterfire configure` (or manually add firebase_options.dart)

4. **Configure AI (Optional)**
   - Get an OpenAI API key from [platform.openai.com](https://platform.openai.com)
   - Run the app and navigate to AI Chat
   - Enter your API key in the settings
   - See [AI_SETUP.md](AI_SETUP.md) for detailed instructions

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
  core/
    constants/      # App constants, Firebase constants
    theme/          # App colors, text styles, theme
    routes/         # Route definitions and pages
    utils/          # Date utilities, validators
  data/
    models/         # Data models (User, Product, Task, etc.)
    services/       # Firebase, AI, OCR, Storage services
  modules/
    auth/           # Authentication screens
    home/           # Dashboard
    products/       # Product management
    scanner/        # Smart scanner
    expiry/         # Expiry management
    inventory/      # Inventory overview
    tasks/          # Task management
    ai_chat/        # AI chat assistant
    voice_assistant/ # Voice AI assistant
    document_ai/    # Document AI
    receipt_scanner/# Receipt scanner
    notification/   # Notification settings
  main.dart
```

## Firebase Configuration

### Required Services
- **Firebase Authentication**: For user authentication
- **Cloud Firestore**: For data storage
- **Firebase Storage**: For image uploads
- **Firebase Cloud Messaging**: For push notifications

### Security Rules

Apply the recommended security rules from [SECURITY.md](SECURITY.md) to ensure proper data isolation and access control.

## AI Features Setup

AI features require an OpenAI-compatible API key. See [AI_SETUP.md](AI_SETUP.md) for:
- Supported AI providers
- Setup instructions
- Model recommendations
- Cost estimation
- Troubleshooting

## Development

### Running Tests
```bash
flutter test
```

### Code Analysis
```bash
flutter analyze
```

### Build for Production
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Documentation

- [SECURITY.md](SECURITY.md) - Security best practices and Firebase rules
- [AI_SETUP.md](AI_SETUP.md) - AI service configuration guide

## Phase Completion Status

- ✅ Phase 1: Project inspection, architecture, dependencies, theme, routing
- ✅ Phase 2: Firebase + Authentication
- ✅ Phase 3: Dashboard
- ✅ Phase 4: Product Management + Firestore
- ✅ Phase 5: Expiry Management + Notifications
- ✅ Phase 6: Smart Product Scanner + OCR
- ✅ Phase 7: Inventory Overview
- ✅ Phase 8: Smart Tasks
- ✅ Phase 9: AI Assistant
- ✅ Phase 10: Voice AI Assistant
- ✅ Phase 11: Document AI
- ✅ Phase 12: Receipt Scanner
- ✅ Phase 13: AI integration refinement + security
- ✅ Phase 14: Testing, UI polish, and performance

## Contributing

This is a production application. All changes should:
1. Pass `flutter analyze` with no issues
2. Pass all tests
3. Follow existing code style and patterns
4. Preserve existing functionality
5. Include appropriate error handling

## License

Proprietary - All rights reserved

## Support

For issues or questions, please refer to the documentation files or contact the development team.

## Version

Current version: 1.0.0+1
