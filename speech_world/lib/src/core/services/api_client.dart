import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import 'api_interceptor.dart';

/// HTTP клиент для работы с backend API
/// 
/// Использует Dio с базовой конфигурацией и interceptors
/// для автоматической обработки JWT токенов и ошибок
class ApiClient {
  static Dio? _dio;
  
  /// Получить singleton instance Dio
  static Dio get instance {
    _dio ??= _createDio();
    return _dio!;
  }
  
  /// Создать новый instance Dio
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.apiUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    
    // Добавляем interceptor для JWT и логирования
    dio.interceptors.add(ApiInterceptor());
    
    // Логирование в debug mode
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => debugPrint('[DIO] $object'),
        ),
      );
    }
    
    return dio;
  }
  
  /// Сбросить instance (например, при logout)
  static void reset() {
    _dio?.close();
    _dio = null;
  }
  
  /// GET request
  static Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return instance.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  /// POST request
  static Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return instance.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  /// PUT request
  static Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return instance.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
  
  /// DELETE request
  static Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return instance.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
    );
  }
}
