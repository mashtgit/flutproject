import 'package:flutter/foundation.dart' show debugPrint;
import 'package:speech_world/src/data/repositories/user_repository_impl.dart';
import 'package:speech_world/src/domain/entities/pricing_config_entity.dart';
import 'package:speech_world/src/domain/repositories/user_repository.dart';

class GetPricingConfigUseCase {
  final UserRepository _userRepository;

  GetPricingConfigUseCase({UserRepository? userRepository})
      : _userRepository = userRepository ?? UserRepositoryImpl();

  Future<PricingConfigEntity> call() async {
    try {
      return await _userRepository.getPricingConfig();
    } catch (e) {
      // Возвращаем конфигурацию с дефолтными ценами в случае ошибки
      debugPrint('Failed to get pricing config: $e. Using defaults.');
      return const PricingConfigEntity(
        id: 'default_config',
        textTranslateCost: 1, // Примерная стоимость
        liveSpeechToSpeechCostPerSec: 2, // Примерная стоимость
        imageAnalysisCostPerImage: 10, // Примерная стоимость
      );
    }
  }
}