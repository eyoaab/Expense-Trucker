import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthRepository? _authRepository;
  bool _isLoading = false;
  UserModel? _userData;
  String? _errorMessage;

  // Lazy initialize the repository
  AuthRepository get authRepository {
    _authRepository ??= AuthRepository();
    return _authRepository!;
  }

  AuthProvider() {
    _initialize();
  }

  // Getters
  bool get isLoading => _isLoading;
  UserModel? get userData => _userData;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => authRepository.currentUser != null;
  User? get currentUser => authRepository.currentUser;

  Future<void> _initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = authRepository.currentUser;
      if (user != null) {
        _userData = await authRepository.getUserData(user.uid);
      }
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await authRepository.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _userData = await authRepository.getUserData(userCredential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await authRepository.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      if (userCredential.user != null) {
        _userData = await authRepository.getUserData(userCredential.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final userCredential = await authRepository.signInWithGoogle();

      if (userCredential?.user != null) {
        _userData = await authRepository.getUserData(userCredential!.user!.uid);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.signOut();
      _userData = null;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.sendPasswordResetEmail(email);
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

  // Update user profile
  Future<bool> updateUserProfile({
    required String name,
    String? photoUrl,
    String? preferredCurrency,
  }) async {
    if (_userData == null) return false;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.updateUserProfile(
        uid: _userData!.uid,
        name: name,
        photoUrl: photoUrl,
        preferredCurrency: preferredCurrency,
      );

      _userData = await authRepository.getUserData(_userData!.uid);
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

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.updatePassword(newPassword);
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

  // Delete account
  Future<bool> deleteAccount() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authRepository.deleteAccount();
      _userData = null;
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
}
