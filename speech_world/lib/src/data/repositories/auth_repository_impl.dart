import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:speech_world/src/data/repositories/user_repository_impl.dart';
import 'package:speech_world/src/domain/entities/auth_user_entity.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';
import 'package:speech_world/src/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            clientId: kIsWeb
                ? '137235369956-ehr5ldr7vcf41f5vvgpgfl6bhdb6gpl1.apps.googleusercontent.com'
                : null,
          );

  @override
  Future<User?> getCurrentUser() async {
    return _firebaseAuth.currentUser;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    try {
      // Запускаем процесс входа через Google
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // Пользователь отменил вход
        throw Exception('Google sign in was cancelled');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      // Входим в Firebase с учетными данными Google
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Возвращаем базовую сущность пользователя
      // Дополнительные данные (credits, subscription) будут загружены/созданы в UseCase
      return UserEntity(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          userCredential.user!.metadata.creationTime!.millisecondsSinceEpoch,
        ),
        credits: 0, // Будет обновлено после проверки Firestore
        subscription: {
          'planId': 'free',
          'status': 'expired',
          'validUntil': null,
        },
      );
    } catch (e) {
      throw Exception('Failed to sign in with Google: $e');
    }
  }

  @override
  Future<UserEntity> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user == null) {
        throw Exception('Failed to sign in with email and password');
      }

      return UserEntity(
        id: userCredential.user!.uid,
        email: userCredential.user!.email ?? '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          userCredential.user!.metadata.creationTime!.millisecondsSinceEpoch,
        ),
        credits: 0,
        subscription: {
          'planId': 'free',
          'status': 'expired',
          'validUntil': null,
        },
      );
    } on FirebaseAuthException catch (e) {
      throw Exception('Failed to sign in: ${e.message}');
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  @override
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String name,
    String? photoUrl,
  }) async {
    try {
      debugPrint('Creating user profile for: $userId ($email)');
      final userRepo = UserRepositoryImpl();

      // New users get 'free' subscription + 50 starter credits
      final userEntity = UserEntity(
        id: userId,
        email: email,
        createdAt: DateTime.now(),
        credits: 50, // Starter credits for new users
        subscription: {
          'planId': 'free',
          'status': 'active', // Changed from 'expired' to 'active'
          'validUntil': null,
        },
      );
      await userRepo.createUser(userEntity);

      // Verify the document was written to Firestore
      final created = await userRepo.getUserById(userId);
      if (created != null) {
        debugPrint(
          '✅ Verified user profile in Firestore for ID: $userId with ${created.credits} credits',
        );
      } else {
        debugPrint('⚠️  User profile not found after creation for ID: $userId');
      }
      debugPrint(
        '✅ User profile created successfully: $userId with 50 credits and free subscription',
      );
    } catch (e) {
      debugPrint('Failed to create user profile: $e');
      throw Exception('Failed to create user profile: $e');
    }
  }

  @override
  Future<AuthUserEntity> getUser(String userId) async {
    try {
      debugPrint('Getting user profile for: $userId');
      final userRepo = UserRepositoryImpl();
      final userEntity = await userRepo.getUser(userId);

      if (userEntity == null) {
        debugPrint('User profile not found: $userId');
        throw Exception('User profile not found for $userId');
      }

      debugPrint('User profile found: $userId, email: ${userEntity.email}');
      return AuthUserEntity(
        id: userEntity.id,
        email: userEntity.email,
        name: userEntity.email.split(
          '@',
        )[0], // Используем email как имя по умолчанию
        photoUrl: null,
        createdAt: userEntity.createdAt,
        updatedAt: userEntity.createdAt,
        isActive:
            true, // Предполагаем, что если пользователь найден, он активен
        credits: userEntity.credits,
        subscription: userEntity.subscription,
      );
    } catch (e) {
      debugPrint('Failed to get user: $e');
      throw Exception('Failed to get user: $e');
    }
  }

  @override
  Stream<User?> get userChanges {
    return _firebaseAuth.authStateChanges();
  }

  @override
  String get currentUserUid => _firebaseAuth.currentUser?.uid ?? '';

  @override
  bool get isSignedIn => _firebaseAuth.currentUser != null;
}
