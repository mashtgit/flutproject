import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_world/firebase_options.dart';

/// Переключатель для использования Firebase эмуляторов
///
/// true = локальные эмуляторы (для разработки)
/// false = реальный Firebase (для production)
const bool useEmulator = false; // Disabled for testing with production Firebase

/// Database ID for Firestore
/// Using 'default' instead of '(default)' as configured in project
const String firestoreDatabaseId = 'default';

class FirebaseService {
  static FirebaseFirestore? _firestore;
  
  static Future<void> initialize() async {
    try {
      // Инициализируем Firebase с опциями для конкретной платформы
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Log info about selected Firebase project and initialized apps
      try {
        final options = DefaultFirebaseOptions.currentPlatform;
        debugPrint(
          '🔥 Firebase initialized successfully (projectId=${options.projectId})',
        );
        debugPrint('   Firebase apps count: ${Firebase.apps.length}');
      } catch (_) {
        debugPrint('🔥 Firebase initialized successfully');
      }

      // Configure Firestore with custom database ID
      _configureFirestore();

      // Настройка эмуляторов для разработки
      if (useEmulator) {
        await _configureEmulators();
      } else {
        debugPrint('🌐 Using PRODUCTION Firebase');
        debugPrint('📁 Firestore Database ID: $firestoreDatabaseId');
      }
    } catch (e) {
      debugPrint('❌ Firebase initialization error: $e');
      // Не прерываем запуск приложения, если Firebase не инициализировался
      throw FirebaseException(
        plugin: 'firebase_core',
        code: 'initialization_failed',
        message: 'Failed to initialize Firebase: $e',
      );
    }
  }

  /// Configure Firestore instance with custom database ID
  static void _configureFirestore() {
    try {
      // Create Firestore instance with databaseId 'default'
      _firestore = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: firestoreDatabaseId,
      );
      debugPrint('✅ Firestore configured with databaseId: $firestoreDatabaseId');
    } catch (e) {
      debugPrint('⚠️  Failed to configure Firestore with custom databaseId: $e');
      // Fallback to default instance
      _firestore = FirebaseFirestore.instance;
    }
  }

  /// Настройка локальных Firebase эмуляторов
  static Future<void> _configureEmulators() async {
    try {
      // Для Android Emulator используем 10.0.2.2 вместо localhost
      final emulatorHost = defaultTargetPlatform == TargetPlatform.android
          ? '10.0.2.2'
          : 'localhost';

      debugPrint('🎮 Configuring Firebase Emulators for $emulatorHost');

      // Настройка Auth Emulator
      try {
        FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
        debugPrint('✅ Auth Emulator: $emulatorHost:9099');
      } catch (e) {
        debugPrint('⚠️  Auth Emulator error: $e');
      }

      // Настройка Firestore Emulator
      try {
        FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
        debugPrint('✅ Firestore Emulator: $emulatorHost:8080');
      } catch (e) {
        debugPrint('⚠️  Firestore Emulator error: $e');
      }

      debugPrint('🎮 Firebase Emulators configured successfully');
    } catch (e) {
      debugPrint('❌ Error configuring emulators: $e');
      rethrow;
    }
  }

  // Получение экземпляров Firebase сервисов
  static FirebaseAuth get auth => FirebaseAuth.instance;
  
  /// Get Firestore instance with configured database ID
  static FirebaseFirestore get firestore {
    // Return configured instance if available, otherwise default
    return _firestore ?? FirebaseFirestore.instance;
  }

  // Проверка, инициализирован ли Firebase
  static bool get isInitialized => Firebase.apps.isNotEmpty;

  // Проверка, используются ли эмуляторы
  static bool get isUsingEmulator => useEmulator;
}
