/// API Configuration for different environments
/// 
/// Configuration for connecting to Node.js backend API
/// Backend URL depends on platform and environment
class ApiConfig {
  /// Development environment (local testing)
  /// 
  /// For Android emulator use 10.0.2.2 (maps to localhost on host)
  /// For iOS simulator use localhost
  static String get devBaseUrl {
    // Default for Android emulator
    return 'http://10.0.2.2:3000';
    
    // For iOS simulator use:
    // return 'http://localhost:3000';
    
    // For physical device (same network):
    // return 'http://192.168.1.XXX:3000'; // Your computer IP
  }
  
  /// Production environment (deployed backend)
  /// 
  /// Replace with actual Cloud Run URL after deployment
  /// Example: https://speech-world-backend-xxx-uc.a.run.app
  static const String prodBaseUrl = 'https://your-api-domain.com';
  
  /// Current environment
  static bool get isProduction {
    const isProd = bool.fromEnvironment('dart.vm.product');
    return isProd;
  }
  
  /// Get base URL based on environment
  static String get baseUrl {
    return isProduction ? prodBaseUrl : devBaseUrl;
  }
  
  /// WebSocket base URL
  static String get wsBaseUrl {
    final httpUrl = baseUrl;
    // Replace http with ws for WebSocket connection
    return httpUrl.replaceFirst('http', 'ws');
  }
  
  /// API endpoints prefix
  static const String apiPrefix = '/api';
  
  /// Full API URL
  static String get apiUrl => '$baseUrl$apiPrefix';
  
  // ═══════════════════════════════════════════════════════════
  // API Endpoints
  // ═══════════════════════════════════════════════════════════
  
  /// Auth endpoints
  static const String authVerify = '/auth/verify';
  static const String authCustomToken = '/auth/custom-token';
  
  /// User endpoints
  static String userProfile(String uid) => '/users/$uid/profile';
  static String userStats(String uid) => '/users/$uid/stats';
  static const String usersList = '/users';
  
  /// Health check
  static const String health = '/health';
  
  /// Get full URL for endpoint
  static String url(String endpoint) => '$apiUrl$endpoint';
}
