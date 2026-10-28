import 'package:firebase_core/firebase_core.dart' as firebase_core;
import '../../firebase_options.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await firebase_core.Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
    } catch (e) {
      throw Exception('Firebase initialization failed: $e');
    }
  }
}
