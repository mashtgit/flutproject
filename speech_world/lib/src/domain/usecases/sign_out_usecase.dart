import 'package:speech_world/src/data/repositories/auth_repository_impl.dart';
import 'package:speech_world/src/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _authRepository;

  SignOutUseCase({AuthRepository? authRepository})
      : _authRepository = authRepository ?? AuthRepositoryImpl();

  Future<void> call() async {
    await _authRepository.signOut();
  }
}
