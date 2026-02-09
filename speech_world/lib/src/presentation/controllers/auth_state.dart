part of 'auth_cubit.dart';

/// Состояние аутентификации
abstract class AuthState {}

/// Начальное состояние
class AuthInitial extends AuthState {}

/// Состояние загрузки
class AuthLoading extends AuthState {}

/// Пользователь аутентифицирован
class Authenticated extends AuthState {
  final AuthUserEntity user;
  
  Authenticated({required this.user});
}

/// Пользователь не аутентифицирован
class AuthUnauthenticated extends AuthState {}

/// Ошибка аутентификации
class AuthError extends AuthState {
  final String message;
  
  AuthError({required this.message});
}