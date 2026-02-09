import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final DateTime createdAt;
  final int credits;
  final Map<String, dynamic> subscription;

  const UserEntity({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.credits,
    required this.subscription,
  });

  UserEntity copyWith({
    String? id,
    String? email,
    DateTime? createdAt,
    int? credits,
    Map<String, dynamic>? subscription,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      credits: credits ?? this.credits,
      subscription: subscription ?? this.subscription,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        createdAt,
        credits,
        subscription,
      ];

  /// @5>1@07>20=85 87 Map (4;O Firestore)
  factory UserEntity.fromMap(Map<String, dynamic> map, String docId) {
    return UserEntity(
      id: docId,
      email: map['email'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      credits: map['credits'] ?? 0,
      subscription: map['subscription'] ?? {
        'planId': 'free',
        'status': 'expired',
        'validUntil': null,
      },
    );
  }

  /// @5>1@07>20=85 2 Map (4;O Firestore)
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'createdAt': Timestamp.fromDate(createdAt),
      'credits': credits,
      'subscription': subscription,
    };
  }
}