import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_world/src/presentation/controllers/auth_cubit.dart';
import 'package:speech_world/src/presentation/screens/splash/splash_screen.dart';

/// Защита маршрутов, требующих аутентификацию
class AuthGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const AuthGuard({
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated || state is AuthError) {
          // Пользователь не аутентифицирован, перенаправляем на сплэш экран
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        }
      },
      builder: (context, state) {
        if (state is Authenticated) {
          // Пользователь аутентифицирован, показываем контент
          return child;
        } else if (state is AuthLoading) {
          // Показываем загрузочный экран
          return const SplashScreen();
        } else {
          // Показываем fallback или загрузочный экран
          return fallback ?? const SplashScreen();
        }
      },
    );
  }
}

/// Защита маршрутов, доступных только неаутентифицированным пользователям
class GuestGuard extends StatelessWidget {
  final Widget child;
  final Widget? fallback;

  const GuestGuard({
    required this.child,
    this.fallback,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          // Пользователь аутентифицирован, перенаправляем в приложение
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SplashScreen()),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthUnauthenticated || state is AuthError) {
          // Пользователь не аутентифицирован, показываем контент
          return child;
        } else if (state is AuthLoading) {
          // Показываем загрузочный экран
          return const SplashScreen();
        } else {
          // Показываем fallback или загрузочный экран
          return fallback ?? const SplashScreen();
        }
      },
    );
  }
}