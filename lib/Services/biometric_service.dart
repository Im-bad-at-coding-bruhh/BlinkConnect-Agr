import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Constants for storage keys - using the same keys as before
  static const String _kBiometricEnabledKey = 'biometric_enabled';
  static const String _kStoredEmailKey = 'stored_email';
  static const String _kStoredPasswordKey = 'stored_password';

  /// Checks if the device has biometric capabilities.
  Future<bool> get isBiometricAvailable async {
    try {
      final bool canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      print(
          '[BiometricService] Device support check - Can check: $canCheckBiometrics, Supported: $isDeviceSupported');
      return canCheckBiometrics && isDeviceSupported;
    } catch (e) {
      print('[BiometricService] Error checking availability: $e');
      return false;
    }
  }

  /// Checks if the user has previously enabled biometric login.
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bool enabled = prefs.getBool(_kBiometricEnabledKey) ?? false;
      print('[BiometricService] Checking biometric enabled status...');
      print(
          '[BiometricService] Raw value from SharedPreferences: ${prefs.getBool(_kBiometricEnabledKey)}');
      print('[BiometricService] Final enabled status: $enabled');
      return enabled;
    } catch (e) {
      print('[BiometricService] Error checking biometric enabled status: $e');
      return false;
    }
  }

  /// Retrieves the stored email and password.
  Future<Map<String, String>?> getStoredCredentials() async {
    try {
      final email = await _secureStorage.read(key: _kStoredEmailKey);
      final password = await _secureStorage.read(key: _kStoredPasswordKey);

      print('[BiometricService] Checking stored credentials...');
      print('[BiometricService] Email exists: ${email != null}');
      print('[BiometricService] Password exists: ${password != null}');

      if (email != null && password != null) {
        print('[BiometricService] Found complete credentials for: $email');
        return {'email': email, 'password': password};
      }
      print('[BiometricService] No complete credentials found');
      return null;
    } catch (e) {
      print('[BiometricService] Error retrieving stored credentials: $e');
      return null;
    }
  }

  /// Enables biometric login by storing credentials and setting the flag.
  Future<void> enableBiometrics(String email, String password) async {
    try {
      print('[BiometricService] Starting biometric enable process...');

      // First store the credentials
      await _secureStorage.write(key: _kStoredEmailKey, value: email);
      await _secureStorage.write(key: _kStoredPasswordKey, value: password);

      // Then enable the feature
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBiometricEnabledKey, true);

      print(
          '[BiometricService] Credentials stored and biometrics enabled for: $email');
      await debugBiometricState();
    } catch (e) {
      print('[BiometricService] Error enabling biometrics: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  /// Disables biometric login by clearing credentials and the flag.
  Future<void> disableBiometrics() async {
    try {
      print('[BiometricService] Starting biometric disable process...');

      // First clear the credentials
      await _secureStorage.delete(key: _kStoredEmailKey);
      await _secureStorage.delete(key: _kStoredPasswordKey);

      // Then disable the feature
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBiometricEnabledKey, false);

      print('[BiometricService] Credentials cleared and biometrics disabled');
      await debugBiometricState();
    } catch (e) {
      print('[BiometricService] Error disabling biometrics: $e');
      rethrow; // Rethrow to handle in UI
    }
  }

  /// Prompts the user for biometric authentication.
  Future<bool> authenticate(
      {String reason = 'Please authenticate to access your account'}) async {
    try {
      print('[BiometricService] Starting biometric authentication...');
      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      print('[BiometricService] Authentication result: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('[BiometricService] Error during authentication: $e');
      return false;
    }
  }

  /// Prints the current state of stored biometric data for debugging.
  Future<void> debugBiometricState() async {
    print('🔍 === BIOMETRIC SERVICE STATE ===');
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kBiometricEnabledKey);
      final email = await _secureStorage.read(key: _kStoredEmailKey);
      final password = await _secureStorage.read(key: _kStoredPasswordKey);

      print('  - Raw Biometric Enabled Flag: $enabled');
      print('  - Stored Email: ${email ?? 'null'}');
      print('  - Stored Password: ${password != null ? 'Exists' : 'null'}');

      final isAvailable = await isBiometricAvailable;
      print('  - Device Support Available: $isAvailable');
    } catch (e) {
      print('  - Error during debug: $e');
    }
    print('🔍 =============================');
  }
}
