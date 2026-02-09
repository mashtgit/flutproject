import '../entities/user_entity.dart';
import '../repositories/user_repository.dart';

class GetProfileUseCase {
  final UserRepository repository;

  GetProfileUseCase(this.repository);

  Future<UserEntity?> call(String userId) async {
    return await repository.getUserById(userId);
  }
}
