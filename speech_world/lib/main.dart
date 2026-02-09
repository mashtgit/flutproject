import 'package:flutter/material.dart';
import 'src/core/services/firebase_service.dart';
import 'src/core/services/analytics_service.dart';
import 'src/core/services/crashlytics_service.dart';
import 'src/app/app.dart';

/// Главная точка входа в приложение Speech World
/// 
/// Инициализирует Firebase, аналитику и другие сервисы
/// перед запуском основного приложения
Future<void> main() async {
  // Убеждаемся, что Flutter initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Инициализация Firebase и основных сервисов
    await _initializeServices();
    
    // Запуск приложения
    runApp(const SpeechWorldApp());
  } catch (e, stackTrace) {
    // Логирование ошибок инициализации
    debugPrint('Error initializing app: $e');
    debugPrint('Stack trace: $stackTrace');
    
    // В случае ошибки инициализации Firebase, запускаем приложение без Firebase
    runApp(const SpeechWorldApp());
  }
}

/// Инициализация всех необходимых сервисов
Future<void> _initializeServices() async {
  try {
    // Инициализация Firebase
    await FirebaseService.initialize();
    debugPrint('Firebase initialized successfully');
    
    // Инициализация аналитики
    await AnalyticsService.initialize();
    debugPrint('Analytics service initialized successfully');
    
    // Инициализация Crashlytics
    await CrashlyticsService.initialize();
    debugPrint('Crashlytics service initialized successfully');
    
  } catch (e) {
    debugPrint('Service initialization error: $e');
    // Не прерываем запуск приложения, если сервисы не инициализировались
  }
}

/// Корневой виджет приложения
/// 
/// Обеспечивает необходимую конфигурацию и провайдеры
/// для всего приложения
class SpeechWorldApp extends StatelessWidget {
  const SpeechWorldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Speech World',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF0F7FF),
          surface: const Color(0xFFF0F7FF),
          primary: const Color(0xFFFFE500),
        ),

        // 1. Глобальные скругления для всех Карточек (Card)
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0, // На макете тени очень мягкие
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(32.0), // Большое скругление как на скрине
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // Глобальные отступы карточек
        ),

        // 2. Глобальные скругления и отступы для Кнопок
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFE500),
            foregroundColor: Colors.black,
            minimumSize: const Size(88, 56), // Высота кнопок
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28.0), // Овальные кнопки
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),

        // 3. Глобальная настройка Полей ввода (TextField)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF5F7F9), // Цвет внутри поля
          contentPadding: const EdgeInsets.all(20), // Внутренние отступы текста
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24.0), // Скругление поля ввода
            borderSide: BorderSide.none,
          ),
        ),
      ),
      home: const App(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}

/// Виджет для обработки глобальных ошибок
class ErrorBoundary extends StatelessWidget {
  final Widget child;
  final String? error;

  const ErrorBoundary({
    super.key,
    required this.child,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'An error occurred',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Перезапуск приложения
                    main();
                  },
                  child: const Text('Restart App'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return child;
  }
}
