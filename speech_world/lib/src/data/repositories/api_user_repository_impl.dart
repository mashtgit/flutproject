import 'package:flutter/foundation.dart';
import 'package:speech_world/src/core/config/api_config.dart';
import 'package:speech_world/src/core/services/api_client.dart';
import 'package:speech_world/src/domain/entities/pricing_config_entity.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';
import 'package:speech_world/src/domain/repositories/user_repository.dart';

/// Repository для работы с User API через backend
/// 
/// Использует HTTP запросы к Node.js backend вместо прямого доступа к Firestore
class ApiUserRepositoryImpl implements UserRepository {
  @override
  Future<UserEntity?> getUser(String uid) async {
    try {
      final response = await ApiClient.get(
        ApiConfig.userProfile,
      );
      
      if (response.statusCode == 200 && response.data != null) {
        return _mapApiResponseToUserEntity(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[ApiUserRepository] Failed to get user: $e');
      // Fallback to null — caller should handle error
      return null;
    }
  }
  
  @override
  Future<UserEntity?> getUserById(String userId) async {
    // API uses same endpoint for profile
    return getUser(userId);
  }
  
  @override
  Future<UserEntity> createUser(UserEntity user) async {
    try {
      debugPrint('[ApiUserRepository] Creating user via API: ${user.id}');
      
      final response = await ApiClient.post(
        ApiConfig.userProfile,
        data: {
          'email': user.email,
          'displayName': user.email.split('@')[0], // Default name from email
          'photoURL': null,
          'credits': user.credits,
          'subscription': user.subscription,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('[ApiUserRepository] User created successfully via API');
        return user;
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiUserRepository] Failed to create user via API: $e');
      throw Exception('Failed to create user: $e');
    }
  }
  
  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      debugPrint('[ApiUserRepository] Updating user via API: ${user.id}');
      
      final response = await ApiClient.put(
        ApiConfig.userProfile,
        data: {
          'displayName': user.email.split('@')[0],
          'photoURL': null,
          'credits': user.credits,
          'subscription': user.subscription,
        },
      );
      
      if (response.statusCode == 200) {
        debugPrint('[ApiUserRepository] User updated successfully via API');
        return user;
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[ApiUserRepository] Failed to update user via API: $e');
      throw Exception('Failed to update user: $e');
    }
  }
  
  @override
  Stream<UserEntity?> userChanges(String uid) {
    // API doesn't support real-time streams
    // For real-time updates, use Firestore directly or polling
    // Return empty stream — caller should use Firestore for realtime
    debugPrint('[ApiUserRepository] userChanges not supported via API, use Firestore for realtime');
    return Stream.empty();
  }
  
  @override
  Future<void> logCreditTransaction({
    required String userId,
    required int amount,
    required String operation,
    Map<String, dynamic>? details,
  }) async {
    try {
      // Implement credit transaction logging via API
      // This would require a new endpoint: POST /api/users/:uid/credits/log
      debugPrint('[ApiUserRepository] Credit transaction logging not implemented in API yet');
    } catch (e) {
      debugPrint('[ApiUserRepository] Failed to log credit transaction: $e');
    }
  }
  
  @override
  Future<PricingConfigEntity> getPricingConfig() async {
    try {
      // Implement pricing config endpoint in backend
      // For now, return default values
      debugPrint('[ApiUserRepository] getPricingConfig not implemented in API yet, using defaults');
      return const PricingConfigEntity(
        id: 'pricing',
        textTranslateCost: 1,
        liveSpeechToSpeechCostPerSec: 2,
        imageAnalysisCostPerImage: 10,
      );
    } catch (e) {
      debugPrint('[ApiUserRepository] Failed to get pricing config: $e');
      // Return defaults on error
      return const PricingConfigEntity(
        id: 'pricing',
        textTranslateCost: 1,
        liveSpeechToSpeechCostPerSec: 2,
        imageAnalysisCostPerImage: 10,
      );
    }
  }
  
  /// Map API response to UserEntity
  UserEntity? _mapApiResponseToUserEntity(Map<String, dynamic> data) {
    try {
      final uid = data['uid'] as String?;
      final email = data['email'] as String?;
      
      if (uid == null || email == null) {
        return null;
      }
      
      // Handle Firestore Timestamp from backend
      DateTime createdAt = DateTime.now();
      if (data['createdAt'] != null) {
        // Backend sends Timestamp which converts to Map with seconds and nanoseconds
        if (data['createdAt'] is Map) {
          final timestamp = data['createdAt'] as Map<String, dynamic>;
          final seconds = timestamp['_seconds'] as int?;
          if (seconds != null) {
            createdAt = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
          }
        } else if (data['createdAt'] is String) {
          createdAt = DateTime.parse(data['createdAt']);
        }
      }
      
      return UserEntity(
        id: uid,
        email: email,
        createdAt: createdAt,
        credits: data['credits'] ?? 0,
        subscription: data['subscription'] ?? {
          'planId': 'free',
          'status': 'expired',
          'validUntil': null,
        },
      );
    } catch (e) {
      debugPrint('[ApiUserRepository] Failed to map user entity: $e');
      return null;
    }
  }
}
