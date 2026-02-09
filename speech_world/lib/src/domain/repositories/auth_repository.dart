import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_world/src/domain/entities/auth_user_entity.dart';
import 'package:speech_world/src/domain/entities/user_entity.dart';

abstract class AuthRepository {
  /// Returns the currently signed-in user, or null if there isn't one.
  Future<User?> getCurrentUser();

  /// Signs in with Google.
  /// Throws an exception if the sign-in process fails or is cancelled.
  Future<UserEntity> signInWithGoogle();

  /// Signs in with email and password.
  /// Throws an exception if the sign-in process fails.
  Future<UserEntity> signIn({required String email, required String password});

  /// Signs out the current user.
  /// Throws an exception if the sign-out process fails.
  Future<void> signOut();

  /// Returns a [Stream] of the currently signed-in user.
  /// The stream emits a [User] object if a user is signed in, and null if not.
  Stream<User?> get userChanges;

  /// Returns the UID of the currently signed-in user, or an empty string if not signed in.
  String get currentUserUid;

  /// Checks if there is a currently signed-in user.
  bool get isSignedIn => currentUserUid.isNotEmpty;

  /// Creates user profile in Firestore
  Future<void> createUserProfile({
    required String userId,
    required String email,
    required String name,
    String? photoUrl,
  });

  /// Gets user profile from Firestore
  Future<AuthUserEntity> getUser(String userId);

  // Future<void> signUp({required String email, required String password});
  // Future<void> sendPasswordResetEmail({required String email});
}