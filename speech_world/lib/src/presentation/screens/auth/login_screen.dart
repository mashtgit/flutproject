import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_world/src/presentation/controllers/auth_cubit.dart';
import 'package:speech_world/src/presentation/widgets/common/app_button.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Вход'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Заголовок
            const Text(
              'Добро пожаловать в Speech World!',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Войдите, чтобы начать практиковать английский язык',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),

            // Кнопка Google Sign-In
            AppButton(
              onPressed: () {
                context.read<AuthCubit>().signInWithGoogle();
              },
              text: 'Войти с Google',
              backgroundColor: const Color(0xFF4285F4),
            ),
            const SizedBox(height: 16),

            // Кнопка регистрации
            AppButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              text: 'Создать аккаунт',
              backgroundColor: Colors.white,
              textColor: const Color(0xFF4285F4),
            ),
            const SizedBox(height: 32),

            // Информация о безопасности
            const Text(
              'Ваши данные безопасны. Мы используем Firebase Authentication для защиты вашей информации.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}