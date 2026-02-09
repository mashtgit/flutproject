/// Сущность пользователя приложения для слоя аутентификации
class AuthUserEntity {
  final String id;
  final String email;
  final String name;
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int credits;
  final Map<String, dynamic> subscription;

  const AuthUserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    required this.credits,
    required this.subscription,
  });

  /// Создание пользователя из Map (для Firestore)
  factory AuthUserEntity.fromMap(Map<String, dynamic> map, String id) {
    return AuthUserEntity(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      photoUrl: map['photo_url'],
      createdAt: (map['createdAt'] as DateTime?) ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as DateTime?) ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
      credits: map['credits'] ?? 0,
      subscription: map['subscription'] ?? {
        'planId': 'free',
        'status': 'expired',
        'validUntil': null,
      },
    );
  }

  /// Преобразование пользователя в Map (для Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'photo_url': photoUrl,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isActive': isActive,
      'credits': credits,
      'subscription': subscription,
    };
  }

  /// Копирование пользователя с измененными полями
  AuthUserEntity copyWith({
    String? id,
    String? email,
    String? name,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? credits,
    Map<String, dynamic>? subscription,
  }) {
    return AuthUserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      credits: credits ?? this.credits,
      subscription: subscription ?? this.subscription,
    );
  }

  @override
  String toString() {
    return 'AuthUserEntity(id: $id, email: $email, name: $name, photoUrl: $photoUrl, createdAt: $createdAt, updatedAt: $updatedAt, isActive: $isActive, credits: $credits, subscription: $subscription)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is AuthUserEntity &&
           other.id == id &&
           other.email == email &&
           other.name == name &&
           other.photoUrl == photoUrl &&
           other.createdAt == createdAt &&
           other.updatedAt == updatedAt &&
           other.isActive == isActive &&
           other.credits == credits &&
           other.subscription == subscription;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           email.hashCode ^
           name.hashCode ^
           photoUrl.hashCode ^
           createdAt.hashCode ^
           updatedAt.hashCode ^
           isActive.hashCode ^
           credits.hashCode ^
           subscription.hashCode;
  }
}