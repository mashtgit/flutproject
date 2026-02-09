import 'package:firebase_auth/firebase_auth.dart';

class AuthFirebaseSource {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
  
  Future<UserCredential> signUp(String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(email: email, password: password);
  }
  
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  User? getCurrentUser() {
    return _auth.currentUser;
  }
  
  Future<bool> isSignedIn() async {
    final user = _auth.currentUser;
    return user != null;
  }
}