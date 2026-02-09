import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_world/src/data/repositories/api_user_repository_impl.dart';
import 'package:speech_world/src/data/repositories/user_repository_impl.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';
import 'package:speech_world/src/domain/repositories/user_repository.dart';
import 'package:speech_world/src/domain/usecases/create_user_if_not_exists_usecase.dart';
import 'package:speech_world/src/domain/usecases/get_pricing_config_usecase.dart';
import 'package:speech_world/src/presentation/states/user_state.dart';

/// Cubit для управления состоянием пользователя
/// 
/// Использует API Repository для операций create/update/delete
/// и Firestore Repository для real-time streaming
class UserCubit extends Cubit<UserState> {
  // API Repository для CRUD операций (через backend)
  final UserRepository _apiUserRepository;
  // Firestore Repository для real-time streams
  final UserRepository _firestoreUserRepository;
  
  final CreateUserIfNotExistsUseCase _createUserIfNotExistsUseCase;
  final GetPricingConfigUseCase _getPricingConfigUseCase;

  UserCubit({
    UserRepository? apiUserRepository,
    UserRepository? firestoreUserRepository,
    CreateUserIfNotExistsUseCase? createUserIfNotExistsUseCase,
    GetPricingConfigUseCase? getPricingConfigUseCase,
  })  : _apiUserRepository = apiUserRepository ?? ApiUserRepositoryImpl(),
        _firestoreUserRepository = firestoreUserRepository ?? UserRepositoryImpl(),
        _createUserIfNotExistsUseCase =
            createUserIfNotExistsUseCase ?? CreateUserIfNotExistsUseCase(),
        _getPricingConfigUseCase =
            getPricingConfigUseCase ?? GetPricingConfigUseCase(),
        super(UserInitial());

  /// Загрузить пользователя
  /// 
  /// Использует API для получения данных, с fallback на Firestore
  Future<void> loadUser(String uid) async {
    emit(UserLoading());
    try {
      // Сначала пробуем получить через API
      final user = await _apiUserRepository.getUser(uid);
      
      if (user != null) {
        // Загружаем конфигурацию цен
        final config = await _getPricingConfigUseCase();
        emit(UserLoadedWithConfig(user: user, config: config));
      } else {
        // Fallback: пробуем Firestore
        final firestoreUser = await _firestoreUserRepository.getUser(uid);
        if (firestoreUser != null) {
          final config = await _getPricingConfigUseCase();
          emit(UserLoadedWithConfig(user: firestoreUser, config: config));
        } else {
          emit(const UserError(message: 'User not found'));
        }
      }
    } catch (e) {
      emit(UserError(message: e.toString()));
    }
  }

  /// Создать пользователя через API
  Future<void> createUserIfNeeded(UserEntity user) async {
    emit(UserLoading());
    try {
      // Проверяем существует ли пользователь через API
      final existingUser = await _apiUserRepository.getUser(user.id);
      
      if (existingUser != null) {
        // Пользователь уже существует
        final config = await _getPricingConfigUseCase();
        emit(UserLoadedWithConfig(user: existingUser, config: config));
        return;
      }
      
      // Создаем через API
      final createdUser = await _apiUserRepository.createUser(user);
      final config = await _getPricingConfigUseCase();
      emit(UserLoadedWithConfig(user: createdUser, config: config));
    } catch (e) {
      // Fallback: пробуем через Firestore
      try {
        final createdOrExistingUser = await _createUserIfNotExistsUseCase(user);
        final config = await _getPricingConfigUseCase();
        emit(UserLoadedWithConfig(user: createdOrExistingUser, config: config));
      } catch (fallbackError) {
        emit(UserError(message: 'Failed to create user: $e'));
      }
    }
  }

  /// Альтернативный метод создания пользователя
  Future<void> createNewUserIfNotExists(String uid, String email) async {
    emit(UserLoading());
    try {
      // Проверяем существование через API
      var existingUser = await _apiUserRepository.getUser(uid);

      if (existingUser == null) {
        // Создаем нового пользователя
        final newUser = UserEntity(
          id: uid,
          email: email,
          createdAt: DateTime.now(),
          credits: 0,
          subscription: {
            'planId': 'free',
            'status': 'expired',
            'validUntil': null,
          },
        );
        
        final createdUser = await _apiUserRepository.createUser(newUser);
        final config = await _getPricingConfigUseCase();
        emit(UserLoadedWithConfig(user: createdUser, config: config));
      } else {
        // Пользователь уже существует
        final config = await _getPricingConfigUseCase();
        emit(UserLoadedWithConfig(user: existingUser, config: config));
      }
    } catch (e) {
      // Fallback: используем Firestore
      try {
        final firestoreUser = await _firestoreUserRepository.getUser(uid);
        if (firestoreUser == null) {
          final newUser = UserEntity(
            id: uid,
            email: email,
            createdAt: DateTime.now(),
            credits: 0,
            subscription: {
              'planId': 'free',
              'status': 'expired',
              'validUntil': null,
            },
          );
          final createdUser = await _firestoreUserRepository.createUser(newUser);
          final config = await _getPricingConfigUseCase();
          emit(UserLoadedWithConfig(user: createdUser, config: config));
        } else {
          final config = await _getPricingConfigUseCase();
          emit(UserLoadedWithConfig(user: firestoreUser, config: config));
        }
      } catch (fallbackError) {
        emit(UserError(message: e.toString()));
      }
    }
  }

  /// Обновить пользователя через API
  Future<void> updateUser(UserEntity user) async {
    emit(UserLoading());
    try {
      final updatedUser = await _apiUserRepository.updateUser(user);
      final config = await _getPricingConfigUseCase();
      emit(UserLoadedWithConfig(user: updatedUser, config: config));
    } catch (e) {
      // Fallback: пробуем Firestore
      try {
        final updatedUser = await _firestoreUserRepository.updateUser(user);
        final config = await _getPricingConfigUseCase();
        emit(UserLoadedWithConfig(user: updatedUser, config: config));
      } catch (fallbackError) {
        emit(UserError(message: e.toString()));
      }
    }
  }

  /// Демо метод: списание 1 кредита
  Future<void> decrementCredits() async {
    if (state is UserLoadedWithConfig) {
      final currentState = state as UserLoadedWithConfig;
      if (currentState.user.credits > 0) {
        final updatedUser = currentState.user.copyWith(
          credits: currentState.user.credits - 1,
        );
        await updateUser(updatedUser);
      } else {
        emit(const UserError(message: 'Недостаточно кредитов'));
        // Возвращаемся в предыдущее состояние
        Future.delayed(const Duration(seconds: 2), () {
          if (state is UserError) {
            emit(currentState);
          }
        });
      }
    } else {
      emit(const UserError(message: 'Пользователь не загружен'));
    }
  }

  /// Подписка на изменения пользователя (через Firestore)
  Stream<UserEntity?> userChanges(String uid) {
    // Real-time только через Firestore
    return _firestoreUserRepository.userChanges(uid);
  }

  void clearUser() {
    emit(UserInitial());
  }
}
