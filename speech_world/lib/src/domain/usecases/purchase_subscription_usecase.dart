import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class PurchaseSubscriptionUseCase {
  final SubscriptionRepository repository;

  PurchaseSubscriptionUseCase(this.repository);

  Future<Subscription> call(String userId, String productId) async {
    return await repository.createSubscription(userId, productId);
  }
}
