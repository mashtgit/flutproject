import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreditLogEntity extends Equatable {
  final String id;
  final String userId;
  final int amount;
  final String operation;
  final DateTime timestamp;
  final Map<String, dynamic> details;

  const CreditLogEntity({
    required this.id,
    required this.userId,
    required this.amount,
    required this.operation,
    required this.timestamp,
    required this.details,
  });

  CreditLogEntity copyWith({
    String? id,
    String? userId,
    int? amount,
    String? operation,
    DateTime? timestamp,
    Map<String, dynamic>? details,
  }) {
    return CreditLogEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      operation: operation ?? this.operation,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        amount,
        operation,
        timestamp,
        details,
      ];

  /// Преобразование из Map (для Firestore)
  factory CreditLogEntity.fromMap(Map<String, dynamic> map, String docId) {
    return CreditLogEntity(
      id: docId,
      userId: map['userId'] ?? '',
      amount: map['amount'] ?? 0,
      operation: map['operation'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      details: map['details'] ?? {},
    );
  }

  /// Преобразование в Map (для Firestore)
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'operation': operation,
      'timestamp': Timestamp.fromDate(timestamp),
      'details': details,
    };
  }
}