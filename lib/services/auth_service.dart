import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password and save details
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String role,
    required String? department,
    required String? className,
    required String? prn,
  }) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = userCredential.user!.uid;

    final userData = {
      'name': name,
      'role': role,
      'class': className,
      'department': department,
      'email': email,
      if (role == 'student') 'prn': prn,
    };

    // Save to users collection
    await _firestore.collection('users').doc(uid).set(userData);

    // Save to department hierarchy if applicable
    if (department != null && className != null) {
      await _firestore
          .collection('departments')
          .doc(department.toLowerCase())
          .collection('classes')
          .doc(className)
          .collection('students')
          .doc(uid)
          .set(userData);

      // Ensure department and class documents exist
      await _firestore
          .collection('departments')
          .doc(department.toLowerCase())
          .set({'name': department}, SetOptions(merge: true));

      await _firestore
          .collection('departments')
          .doc(department.toLowerCase())
          .collection('classes')
          .doc(className)
          .set({'name': className}, SetOptions(merge: true));
    }

    return userCredential;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['role'] as String?;
      }
    } catch (e) {
      // Handle error or return null
      print('Error fetching user role: $e');
    }
    return null;
  }

  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.data();
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    return null;
  }
}
