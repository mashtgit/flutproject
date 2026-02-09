class AppException implements Exception {
  final String message;
  final String? code;
  
  AppException(this.message, {this.code});
  
  @override
  String toString() => message;
}

class NetworkException extends AppException {
  NetworkException(super.message) : super(code: 'NETWORK_ERROR');
}

class AuthenticationException extends AppException {
  AuthenticationException(super.message) : super(code: 'AUTH_ERROR');
}

class SubscriptionException extends AppException {
  SubscriptionException(super.message) : super(code: 'SUBSCRIPTION_ERROR');
}