import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Interceptor для добавления JWT токена к запросам
/// 
/// Автоматически добавляет Firebase ID Token к каждому запросу
/// и обрабатывает 401 ошибки (token expired)
class ApiInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      // Получаем текущего пользователя
      final user = FirebaseAuth.instance.currentUser;
      
      if (user != null) {
        // Получаем свежий ID token
        final token = await user.getIdToken(true);
        
        // Добавляем токен в заголовок
        options.headers['Authorization'] = 'Bearer $token';
        
        if (kDebugMode) {
          debugPrint('[API] Added auth token for ${options.path}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[API] Failed to get auth token: $e');
      }
    }
    
    return handler.next(options);
  }
  
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Можно добавить обработку ответов здесь
    return handler.next(response);
  }
  
  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Обработка 401 Unauthorized — токен истек
    if (err.response?.statusCode == 401) {
      if (kDebugMode) {
        debugPrint('[API] 401 Unauthorized — token expired or invalid');
      }
      
      // Здесь можно добавить логику refresh token или logout
      // Например, отправить событие в AuthCubit для re-authentication
    }
    
    return handler.next(err);
  }
}
