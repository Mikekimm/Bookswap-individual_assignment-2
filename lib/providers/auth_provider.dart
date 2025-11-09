import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

// Print logs help track when users sign in/out and when auth state changes.


class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    print('AuthProvider: Initializing authentication listener');
    _authService.authStateChanges.listen((User? firebaseUser) async {
      print('AuthProvider: Auth state changed - User: ${firebaseUser?.email ?? "null"}');
      if (firebaseUser != null) {
        _user = await _authService.getUserData(firebaseUser.uid);
        print('AuthProvider: User data loaded for ${_user?.email}');
      } else {
        _user = null;
        print('AuthProvider: User logged out');
      }
      notifyListeners();
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Sign up timed out. Please check your internet connection.');
        },
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    print('AuthProvider: Starting sign in for $email');
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authService.signIn(email: email, password: password).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Sign in timed out. Please check your internet connection.');
        },
      );
      print('AuthProvider: Sign in successful for user ${_user?.email}');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      print('AuthProvider: Sign in failed - $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> resendVerificationEmail() async {
    try {
      await _authService.resendVerificationEmail();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshUserData() async {
    try {
      final firebaseUser = _authService.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();
        _user = await _authService.getUserData(firebaseUser.uid);
        
        // Update emailVerified status in Firestore
        if (_user != null && _user!.emailVerified != firebaseUser.emailVerified) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .update({'emailVerified': firebaseUser.emailVerified});
          
          _user = _user!.copyWith(emailVerified: firebaseUser.emailVerified);
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
