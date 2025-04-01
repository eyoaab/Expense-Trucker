import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  static Future<void> initialize() async {
    try {
      // During development, we might not have Firebase configured properly,
      // so we'll make initialization optional
      if (kDebugMode) {
        try {
          await Firebase.initializeApp();
          debugPrint('Firebase initialized successfully');
        } catch (e) {
          debugPrint('Firebase initialization skipped in debug mode: $e');
          // Don't rethrow in debug mode - allow the app to continue
        }
      } else {
        // In production, Firebase must be properly initialized
        await Firebase.initializeApp();
        debugPrint('Firebase initialized successfully');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }
}
