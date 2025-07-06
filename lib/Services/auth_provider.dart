import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  String? _username;
  String? _userType;
  String? _profilePhotoUrl;

  AuthProvider() {
    _init();
  }

  firebase_auth.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;
  bool get isAdmin => _isAdmin;
  String? get username => _username;
  String? get userType => _userType;
  String? get profilePhotoUrl => _profilePhotoUrl;

  void _init() {
    _authService.authStateChanges.listen((firebase_auth.User? user) {
      _user = user;
      if (user == null) {
        _username = null;
        _userType = null;
        _profilePhotoUrl = null;
        _isAdmin = false;
        notifyListeners();
        return;
      }
      // When user is authenticated, load all their data and notify once.
      _loadUserData(user);
    });
  }

  Future<void> _loadUserData(firebase_auth.User user) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        _username = data['username'];
        _userType = data['user_type'];
        _profilePhotoUrl = data['photo_url'];
      }

      final adminDoc = await FirebaseFirestore.instance
          .collection('admins')
          .doc(user.uid)
          .get();
      _isAdmin = adminDoc.exists;
    } catch (e) {
      print("Error loading user data: $e");
      _username = null;
      _userType = null;
      _profilePhotoUrl = null;
      _isAdmin = false;
    } finally {
      // After all user data is loaded (or has failed to load), notify all listeners.
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _authService.signInWithEmailAndPassword(email, password);
      // The authStateChanges listener in _init() will handle loading user data.
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
      // The authStateChanges listener in _init() will handle loading user data.
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

      // Clear stored biometric credentials
      const secureStorage = FlutterSecureStorage();
      await secureStorage.delete(key: 'stored_email');
      await secureStorage.delete(key: 'stored_password');

      // Disable biometric authentication
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);

      final userProvider = Provider.of<UserProvider>(
        navigatorKey.currentContext!,
        listen: false,
      );
      userProvider.clearUser();
      await _authService.signOut();

      _username = null;
      _userType = null;
      _profilePhotoUrl = null;
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

      final userCredential = await _authService.signInWithGoogle();

      // Check admin status after successful Google sign in
      if (userCredential.user != null) {
        _user = userCredential.user;
        await _loadUserData(_user!);
        print(
            'AuthProvider: User signed in with Google, checking admin status...');
        final adminDoc = await FirebaseFirestore.instance
            .collection('admins')
            .doc(userCredential.user!.uid)
            .get();
        _isAdmin = adminDoc.exists;
        print('AuthProvider: Admin status: $_isAdmin');
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      print('AuthProvider: Error during Google sign in: $e');
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
