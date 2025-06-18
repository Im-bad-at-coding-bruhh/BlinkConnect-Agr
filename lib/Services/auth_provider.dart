import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import 'auth_service.dart';
import '../Pages/user_provider.dart';
import '../main.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  firebase_auth.User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAdmin = false;

  AuthProvider() {
    _init();
  }

  firebase_auth.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _isAdmin;

  void _init() {
    _authService.authStateChanges.listen((firebase_auth.User? user) async {
      _user = user;
      if (user != null) {
        final profile = await _authService.getUserProfile();
        if (profile != null) {
          final userProvider = Provider.of<UserProvider>(
            navigatorKey.currentContext!,
            listen: false,
          );
          userProvider.setUser(User(
            id: user.uid,
            username: profile['username'] as String,
            email: profile['email'] as String,
            role: profile['user_type'] as String,
          ));

          // Check admin status
          final adminDoc = await FirebaseFirestore.instance
              .collection('admins')
              .doc(user.uid)
              .get();
          _isAdmin = adminDoc.exists;
        }
      }
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);

      // Check admin status after successful sign in
      if (_user != null) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(_user!.uid)
            .get();
        _isAdmin = adminDoc.exists;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password,
      {bool isFarmer = false, String? username, String? region}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.registerWithEmailAndPassword(
        email,
        password,
        isFarmer: isFarmer,
        username: username,
        region: region,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      userProvider.clearUser();
      await _authService.signOut();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.resetPassword(email);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile(
      {String? name,
      String? photoURL,
      String? phoneNumber,
      String? address,
      String? bio}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.updateUserProfile(
        name: name,
        photoURL: photoURL,
        phoneNumber: phoneNumber,
        address: address,
        bio: bio,
      );
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.changePassword(currentPassword, newPassword);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_user == null) {
      print('AuthProvider: No user is signed in');
      return null;
    }
    try {
      print('AuthProvider: Getting profile for user ${_user!.uid}');
      final profile = await _authService.getUserProfile();
      if (profile == null) {
        print('AuthProvider: Failed to get user profile');
        _error = 'Failed to get user profile';
        notifyListeners();
        return null;
      }
      print('AuthProvider: Successfully retrieved profile: $profile');
      return profile;
    } catch (e) {
      print('AuthProvider error: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithGoogle();

      // Check admin status after successful Google sign in
      if (_user != null) {
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(_user!.uid)
            .get();
        _isAdmin = adminDoc.exists;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
