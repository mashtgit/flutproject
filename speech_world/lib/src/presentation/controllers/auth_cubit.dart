import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_world/src/domain/repositories/auth_repository.dart';

import '../../domain/entities/auth_user_entity.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepository;
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final SharedPreferences _preferences;

  AuthCubit({
    required AuthRepository authRepository,
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required SharedPreferences preferences,
  }) : _authRepository = authRepository,
       _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _preferences = preferences,
       super(AuthInitial());

  /// Вход с Google
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    debugPrint('=== Starting Google Sign-In ===');

    try {
      // Начинаем процесс аутентификации
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('User cancelled Google Sign-In');
        emit(AuthError(message: 'Пользователь отменил вход'));
        return;
      }

      debugPrint('Google Sign-In successful for: ${googleUser.email}');

      // Получаем аутентификационные данные от Google
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Создаем учетные данные Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Аутентифицируемся в Firebase
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      debugPrint('Firebase auth successful for user: ${user?.uid}');

      if (user != null) {
        // Use Google email if Firebase email is empty (can happen on first sign-in)
        final String userEmail = user.email ?? googleUser.email;
        final String userName = user.displayName ?? googleUser.displayName ?? 'User';
        final String? userPhoto = user.photoURL ?? googleUser.photoUrl;
        
        debugPrint('User email: $userEmail, name: $userName');
        
        // Сохраняем информацию о пользователе
        await _saveUserToPreferences(user, email: userEmail, name: userName, photoUrl: userPhoto);

        // Создаем или обновляем профиль пользователя в Firestore
        // Работает как для новых, так и для существующих пользователей
        debugPrint('Creating/updating user profile for: ${user.uid}');
        await _authRepository.createUserProfile(
          userId: user.uid,
          email: userEmail,
          name: userName,
          photoUrl: userPhoto,
        );

        // Получаем полную информацию о пользователе
        debugPrint('Retrieving user profile for: ${user.uid}');
        AuthUserEntity authUser;
        try {
          authUser = await _authRepository.getUser(user.uid);
        } catch (e) {
          // Если профиль не найден или произошла ошибка чтения Firestore,
          // не блокируем навигацию — создаём временный профиль и продолжаем.
          debugPrint('⚠️  Failed to load user profile from Firestore: $e');
          debugPrint('Using fallback AuthUserEntity built from Firebase User');
          authUser = AuthUserEntity(
            id: user.uid,
            email: userEmail,
            name: userName,
            photoUrl: userPhoto,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            isActive: true,
            credits: 50, // Starter credits for new users
            subscription: {
              'planId': 'free',
              'status': 'active', // Changed from 'expired' to 'active'
              'validUntil': null,
            },
          );

          // Попытка фонового восстановления/создания профиля в Firestore
          _authRepository
              .createUserProfile(
                userId: user.uid,
                email: userEmail,
                name: userName,
                photoUrl: userPhoto,
              )
              .then((_) {
                debugPrint(
                  'Background createUserProfile succeeded for ${user.uid}',
                );
              })
              .catchError((err) {
                debugPrint('Background createUserProfile failed: $err');
              });
        }

        debugPrint('=== Google Sign-In Completed Successfully ===');
        debugPrint('User: ${authUser.id}, Email: ${authUser.email}');
        emit(Authenticated(user: authUser));
      } else {
        emit(AuthError(message: 'Не удалось получить данные пользователя'));
      }
    } catch (e) {
      debugPrint('=== Google Sign-In Error ===');
      debugPrint('Error: $e');
      emit(AuthError(message: _getErrorMessage(e)));
    }
  }

  /// Выход из системы
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await _clearUserFromPreferences();
      emit(AuthUnauthenticated());
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      emit(AuthError(message: 'Ошибка при выходе из системы'));
    }
  }

  /// Проверка аутентификации при запуске
  Future<void> checkAuthStatus() async {
    emit(AuthLoading());
    debugPrint('=== Checking Auth Status ===');

    try {
      final User? currentUser = _firebaseAuth.currentUser;

      if (currentUser != null) {
        // Пользователь уже аутентифицирован
        debugPrint('Current user found: ${currentUser.uid}');
        final AuthUserEntity authUser = await _authRepository.getUser(currentUser.uid);
        debugPrint('User profile loaded: ${authUser.id}');
        emit(Authenticated(user: authUser));
      } else {
        // Проверяем сохраненные данные
        final String? savedUserId = _preferences.getString('user_id');

        if (savedUserId != null) {
          debugPrint('Attempting to load saved user: $savedUserId');
          final AuthUserEntity authUser = await _authRepository.getUser(savedUserId);
          debugPrint('Saved user profile loaded: ${authUser.id}');
          emit(Authenticated(user: authUser));
        } else {
          debugPrint('No authenticated user found');
          emit(AuthUnauthenticated());
        }
      }
    } catch (e) {
      debugPrint('Auth Status Check Error: $e');
      emit(AuthUnauthenticated());
    }
  }

  /// Сохранение пользователя в SharedPreferences
  Future<void> _saveUserToPreferences(User user, {String? email, String? name, String? photoUrl}) async {
    await _preferences.setString('user_id', user.uid);
    await _preferences.setString('user_email', email ?? user.email ?? '');
    await _preferences.setString('user_name', name ?? user.displayName ?? '');
    await _preferences.setString('user_photo', photoUrl ?? user.photoURL ?? '');
    await _preferences.setBool('is_authenticated', true);
  }

  /// Очистка данных пользователя
  Future<void> _clearUserFromPreferences() async {
    await _preferences.remove('user_id');
    await _preferences.remove('user_email');
    await _preferences.remove('user_name');
    await _preferences.remove('user_photo');
    await _preferences.setBool('is_authenticated', false);
  }

  /// Получение сообщения об ошибке
  String _getErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'account-exists-with-different-credential':
          return 'Аккаунт с таким email уже существует с другим провайдером';
        case 'invalid-credential':
          return 'Неверные учетные данные';
        case 'operation-not-allowed':
          return 'Операция не разрешена';
        case 'email-already-in-use':
          return 'Email уже используется';
        case 'invalid-email':
          return 'Неверный формат email';
        case 'weak-password':
          return 'Слабый пароль';
        case 'user-disabled':
          return 'Пользователь заблокирован';
        case 'user-not-found':
          return 'Пользователь не найден';
        case 'wrong-password':
          return 'Неверный пароль';
        default:
          return 'Ошибка аутентификации: ${error.code}';
      }
    } else if (error is SignInWithGoogleException) {
      return error.message;
    } else {
      return 'Неизвестная ошибка: $error';
    }
  }

  @override
  Future<void> close() {
    _googleSignIn.disconnect();
    return super.close();
  }
}

class SignInWithGoogleException implements Exception {
  final String message;

  SignInWithGoogleException(this.message);
}