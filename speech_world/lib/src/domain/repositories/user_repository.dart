import 'package:speech_world/src/domain/entities/user_entity.dart';
import 'package:speech_world/src/domain/entities/pricing_config_entity.dart';

abstract class UserRepository {
  /// Получает данные пользователя по его UID
  Future<UserEntity?> getUser(String uid);

  /// Получает данные пользователя по ID (синоним getUser, можно удалить один из них)
  Future<UserEntity?> getUserById(String userId);

  /// Создает нового пользователя в Firestore
  Future<UserEntity> createUser(UserEntity user);

  /// Обновляет данные пользователя в Firestore
  Future<UserEntity> updateUser(UserEntity user);

  /// Возвращает Stream для отслеживания изменений данных пользователя
  Stream<UserEntity?> userChanges(String uid);

  /// Логирует транзакцию с кредитами
  Future<void> logCreditTransaction({
    required String userId,
    required int amount,
    required String operation,
    Map<String, dynamic>? details,
  });

  /// Получает текущие настройки ценообразования
  Future<PricingConfigEntity> getPricingConfig();
}