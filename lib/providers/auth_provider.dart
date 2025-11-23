import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  String? _role;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  String? get role => _role;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _fetchUserRole(user.uid);
      } else {
        _role = null;
      }
      notifyListeners();
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    _role = await _authService.getUserRole(uid);
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.signInWithEmailAndPassword(email: email, password: password);
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _handleAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String role,
    String? department,
    String? className,
    String? prn,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
        role: role,
        department: department,
        className: className,
        prn: prn,
      );
      _setLoading(false);
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _handleAuthError(e);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _role = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserData() async {
    if (_user == null) return null;
    return await _authService.getUserData(_user!.uid);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
