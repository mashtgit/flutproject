import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/firebase_service.dart';
import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';
import '../models/subscription_model.dart';

/// Repository для работы с подписками через API и Firestore
/// 
/// Использует HTTP запросы к backend API и Firestore для real-time данных
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final FirebaseFirestore _firestore;

  SubscriptionRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseService.firestore;

  @override
  Future<Subscription> createSubscription(
    String userId,
    String productId,
  ) async {
    try {
      // Implement payment processing via backend API
      // For now, create subscription directly in Firestore
      final subscriptionRef = _firestore.collection('subscriptions').doc();
      final now = DateTime.now();
      
      final subscriptionData = {
        'id': subscriptionRef.id,
        'userId': userId,
        'productId': productId,
        'status': 'active',
        'startDate': Timestamp.fromDate(now),
        'endDate': null,
        'trialEndDate': null,
        'isActive': true,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      };
      
      await subscriptionRef.set(subscriptionData);
      
      // Update user's subscription field
      await _firestore.collection('users').doc(userId).update({
        'subscription': {
          'planId': productId,
          'status': 'active',
          'validUntil': null,
        },
        'updatedAt': Timestamp.fromDate(now),
      });
      
      return SubscriptionModel.fromJson({
        ...subscriptionData,
        'startDate': now.toIso8601String(),
      });
    } catch (e) {
      debugPrint('[SubscriptionRepository] Failed to create subscription: $e');
      throw Exception('Failed to create subscription: $e');
    }
  }

  @override
  Future<Subscription?> getUserSubscription(String userId) async {
    try {
      // Try to get subscription from Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return null;

      final userData = userDoc.data() as Map<String, dynamic>;
      
      // Check if user has subscription data
      if (userData.containsKey('subscription')) {
        final subscriptionData = userData['subscription'] as Map<String, dynamic>;
        final now = DateTime.now();
        
        // Map subscription data to Subscription entity
        return SubscriptionModel(
          id: '${userId}_subscription',
          userId: userId,
          productId: subscriptionData['planId'] ?? 'free',
          status: subscriptionData['status'] ?? 'expired',
          startDate: now,
          endDate: subscriptionData['validUntil'] != null
              ? (subscriptionData['validUntil'] as Timestamp).toDate()
              : null,
          trialEndDate: null,
          isActive: subscriptionData['status'] == 'active',
        );
      }
      
      // Try to get from subscriptions collection
      final subscriptionQuery = await _firestore
          .collection('subscriptions')
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();
      
      if (subscriptionQuery.docs.isNotEmpty) {
        final doc = subscriptionQuery.docs.first;
        final data = doc.data();
        return SubscriptionModel.fromJson({
          'id': doc.id,
          'userId': data['userId'],
          'productId': data['productId'],
          'status': data['status'],
          'startDate': (data['startDate'] as Timestamp).toDate().toIso8601String(),
          'endDate': data['endDate'] != null
              ? (data['endDate'] as Timestamp).toDate().toIso8601String()
              : null,
          'trialEndDate': data['trialEndDate'] != null
              ? (data['trialEndDate'] as Timestamp).toDate().toIso8601String()
              : null,
          'isActive': data['isActive'],
        });
      }
      
      return null;
    } catch (e) {
      debugPrint('[SubscriptionRepository] Failed to get subscription: $e');
      return null;
    }
  }

  @override
  Future<Subscription> updateSubscription(Subscription subscription) async {
    try {
      final subscriptionModel = subscription as SubscriptionModel;
      final now = DateTime.now();
      
      // Update in subscriptions collection
      await _firestore
          .collection('subscriptions')
          .doc(subscription.id)
          .update({
            'status': subscription.status,
            'isActive': subscription.isActive,
            'endDate': subscription.endDate != null
                ? Timestamp.fromDate(subscription.endDate!)
                : null,
            'updatedAt': Timestamp.fromDate(now),
          });
      
      // Update user's subscription field
      await _firestore.collection('users').doc(subscription.userId).update({
        'subscription': {
          'planId': subscription.productId,
          'status': subscription.status,
          'validUntil': subscription.endDate != null
              ? Timestamp.fromDate(subscription.endDate!)
              : null,
        },
        'updatedAt': Timestamp.fromDate(now),
      });

      return subscriptionModel;
    } catch (e) {
      debugPrint('[SubscriptionRepository] Failed to update subscription: $e');
      throw Exception('Failed to update subscription: $e');
    }
  }

  @override
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      final now = DateTime.now();
      
      // Get subscription to find userId
      final subDoc = await _firestore
          .collection('subscriptions')
          .doc(subscriptionId)
          .get();
      
      if (!subDoc.exists) {
        throw Exception('Subscription not found');
      }
      
      final userId = subDoc.data()?['userId'] as String?;
      
      // Update subscription
      await _firestore.collection('subscriptions').doc(subscriptionId).update({
        'status': 'cancelled',
        'isActive': false,
        'endDate': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      });
      
      // Update user's subscription
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'subscription': {
            'planId': 'free',
            'status': 'expired',
            'validUntil': null,
          },
          'updatedAt': Timestamp.fromDate(now),
        });
      }
    } catch (e) {
      debugPrint('[SubscriptionRepository] Failed to cancel subscription: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  @override
  Future<bool> isSubscriptionActive(String userId) async {
    try {
      final subscription = await getUserSubscription(userId);
      return subscription?.isActive ?? false;
    } catch (e) {
      debugPrint('[SubscriptionRepository] Error checking subscription: $e');
      return false;
    }
  }
}