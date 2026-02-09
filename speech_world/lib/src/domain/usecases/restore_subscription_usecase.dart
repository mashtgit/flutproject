import '../entities/subscription.dart';
import '../repositories/subscription_repository.dart';

class RestoreSubscriptionUseCase {
  final SubscriptionRepository repository;

  RestoreSubscriptionUseCase(this.repository);

  Future<Subscription> call(String userId) async {
    final subscription = await repository.getUserSubscription(userId);
    if (subscription == null) {
      throw Exception('No subscription found to restore');
    }
    return await repository.updateSubscription(subscription);
  }
}
