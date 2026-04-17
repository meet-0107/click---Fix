import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

/// Manages Firebase Authentication state and exposes it to the widget tree
/// via ChangeNotifier (Provider pattern).
class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<User?>? _authSubscription;

  User? _user;
  bool _isLoading = true; // Start true so AuthWrapper shows loading
  String? _errorMessage;
  String _userRole = 'user';
  Map<String, dynamic>? _userData;

  // --- Getters ---
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  String? get errorMessage => _errorMessage;
  String get userRole => _userRole;
  Map<String, dynamic>? get userData => _userData;
  bool get isAdmin => _userRole == 'admin';
  bool get isTechnician => _userRole == 'technician';
  bool get isUser => _userRole == 'user';

  AuthProvider() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      _user = user;
      if (user != null) {
        await _fetchUserRole();
      } else {
        _userRole = 'user';
        _userData = null;
      }
      _isLoading = false; // Done loading after first auth check
      notifyListeners();
    });
  }

  /// Fetch user role and data from Firestore.
  Future<void> _fetchUserRole() async {
    if (_user == null) return;
    try {
      _userData = await _firestoreService.getUser(_user!.uid);
      _userRole = _userData?['role'] ?? 'user';
    } catch (e) {
      _userRole = 'user';
    }
  }

  /// Sign in with email and password.
  Future<String?> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _fetchUserRole();
      _setLoading(false);
      return _userRole;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _setLoading(false);
      return null;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return null;
    }
  }

  /// Create a new account.
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    String role = 'user',
    String? pincode,
    String? specialty,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();
      _user = _auth.currentUser;

      if (_user != null) {
        final userData = <String, dynamic>{
          'uid': _user!.uid,
          'name': name,
          'email': email,
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (role == 'technician') {
          userData['pincode'] = pincode ?? '';
          userData['specialty'] = specialty ?? '';
          userData['phone'] = '';
          userData['isAvailable'] = true;
        }

        await _firestore.collection('users').doc(_user!.uid).set(userData);
        _userRole = role;
        _userData = userData;
      }

      _setLoading(false);
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = _mapAuthError(e.code);
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      _setLoading(false);
      return false;
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _auth.signOut();
    _userRole = 'user';
    _userData = null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
