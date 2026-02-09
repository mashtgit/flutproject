import 'package:speech_world/src/data/repositories/auth_repository_impl.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';
import 'package:speech_world/src/domain/repositories/auth_repository.dart';

class SignInWithGoogleUseCase {
  final AuthRepository _authRepository;

  SignInWithGoogleUseCase({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl();

  Future<UserEntity> call() async {
    return await _authRepository.signInWithGoogle();
  }
}
