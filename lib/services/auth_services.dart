import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> signup({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password.trim(),
          );

      // Save additional user data to Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        "role": role,
      });

      return null;
    } catch (e) {
      print("Signup error: $e");
      return null;
    }
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user?.uid)
          .get();
      return userDoc['role'];
    } catch (e) {
      print("Signin error: $e");
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
      print("User logged out successfully.");
    } catch (e) {
      print("Logout error: $e");
      rethrow; // rethrow so UI can handle errors if needed
    }
  }
}
