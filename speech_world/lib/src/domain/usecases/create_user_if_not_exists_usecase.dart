import 'package:speech_world/src/data/repositories/user_repository_impl.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';
import 'package:speech_world/src/domain/repositories/user_repository.dart';

class CreateUserIfNotExistsUseCase {
  final UserRepository _userRepository;

  CreateUserIfNotExistsUseCase({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepositoryImpl();

  Future<UserEntity> call(UserEntity user) async {
    try {
      final existingUser = await _userRepository.getUser(user.id);
      if (existingUser != null) {
        // Пользователь существует, обновляем данные если нужно
        // В данном случае, обновляем email и подпиську
        final updatedUser = existingUser.copyWith(
          email: user.email, // Обновляем email, если он изменился
          subscription: user.subscription, // Обновляем подпиську
        );
        return await _userRepository.updateUser(updatedUser);
      } else {
        // Пользователь не существует, создаем нового
        final newUser = user.copyWith(
          createdAt: DateTime.now(), // Устанавливаем дату создания
        );
        return await _userRepository.createUser(newUser);
      }
    } catch (e) {
      throw Exception('Failed to create or get user: $e');
    }
  }
}