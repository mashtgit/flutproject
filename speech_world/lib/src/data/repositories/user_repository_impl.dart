import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:speech_world/src/core/services/firebase_service.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';
import 'package:speech_world/src/domain/entities/credit_log_entity.dart';
import 'package:speech_world/src/domain/entities/pricing_config_entity.dart';
import 'package:speech_world/src/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
  final FirebaseFirestore _firestore;

  UserRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  @override
  Future<UserEntity?> getUser(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return _mapDocToUserEntity(docSnapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Future<UserEntity?> getUserById(String userId) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(userId).get();
      if (docSnapshot.exists) {
        return _mapDocToUserEntity(docSnapshot);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user by ID: $e');
    }
  }

  @override
  Future<UserEntity> createUser(UserEntity user) async {
    try {
      debugPrint('Creating user with ID: ${user.id}, email: ${user.email}');
      final userRef = _firestore.collection('users').doc(user.id);
      await userRef.set(user.toMap());

      // Verify write by reading the document back
      final verify = await userRef.get();
      if (verify.exists) {
        debugPrint(
          'User write verified in Firestore: ${user.id} -> ${verify.data()}',
        );
      } else {
        debugPrint('⚠️  User write NOT found after set for ID: ${user.id}');
      }
      debugPrint('User created successfully: ${user.id}');
      return user;
    } catch (e) {
      debugPrint('Failed to create user: $e');
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<UserEntity> updateUser(UserEntity user) async {
    try {
      final userRef = _firestore.collection('users').doc(user.id);
      await userRef.update(user.toMap());
      return user;
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  @override
  Stream<UserEntity?> userChanges(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((docSnapshot) {
      if (docSnapshot.exists) {
        return _mapDocToUserEntity(docSnapshot);
      }
      return null;
    });
  }

  /// Логирует транзакцию с кредитами
  @override
  Future<void> logCreditTransaction({
    required String userId,
    required int amount,
    required String operation,
    Map<String, dynamic>? details,
  }) async {
    try {
      final logRef = _firestore.collection('credit_logs').doc();
      final log = CreditLogEntity(
        id: logRef.id,
        userId: userId,
        amount: amount,
        operation: operation,
        timestamp: DateTime.now(),
        details: details ?? {},
      );
      await logRef.set(log.toMap());
      debugPrint('Credit transaction logged: $userId, $amount, $operation');
    } catch (e) {
      throw Exception('Failed to log credit transaction: $e');
    }
  }

  /// Получает текущие настройки ценообразования
  @override
  Future<PricingConfigEntity> getPricingConfig() async {
    try {
      final docSnapshot = await _firestore.collection('config').doc('pricing').get();
      if (docSnapshot.exists) {
        return _mapDocToPricingConfigEntity(docSnapshot);
      }
      // Возвращаем дефолтные значения, если документ не найден
      return const PricingConfigEntity(
        id: 'pricing',
        textTranslateCost: 1,
        liveSpeechToSpeechCostPerSec: 2,
        imageAnalysisCostPerImage: 10,
      );
    } catch (e) {
      throw Exception('Failed to get pricing config: $e');
    }
  }

  // --- Приватные методы маппинга ---

  UserEntity _mapDocToUserEntity(DocumentSnapshot doc) {
    return UserEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  PricingConfigEntity _mapDocToPricingConfigEntity(DocumentSnapshot doc) {
    return PricingConfigEntity.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }
}