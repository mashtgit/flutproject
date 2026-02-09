class Subscription {
  final String id;
  final String userId;
  final String productId;
  final String status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final bool isActive;
  
  Subscription({
    required this.id,
    required this.userId,
    required this.productId,
    required this.status,
    required this.startDate,
    this.endDate,
    this.trialEndDate,
    required this.isActive,
  });
}