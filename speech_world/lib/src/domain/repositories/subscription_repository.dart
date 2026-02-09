import '../entities/subscription.dart';

abstract class SubscriptionRepository {
  Future<Subscription> createSubscription(String userId, String productId);
  Future<Subscription?> getUserSubscription(String userId);
  Future<Subscription> updateSubscription(Subscription subscription);
  Future<void> cancelSubscription(String subscriptionId);
  Future<bool> isSubscriptionActive(String userId);
}
