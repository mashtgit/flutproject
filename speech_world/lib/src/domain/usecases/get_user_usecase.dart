import 'package:speech_world/src/data/repositories/user_repository_impl.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';
import 'package:speech_world/src/domain/repositories/user_repository.dart';

class GetUserUseCase {
  final UserRepository _userRepository;

  GetUserUseCase({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepositoryImpl();

  Future<UserEntity?> call(String uid) async {
    return await _userRepository.getUser(uid);
  }
}
