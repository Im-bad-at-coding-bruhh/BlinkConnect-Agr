import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current user
  User? get currentUser => _auth.currentUser;

  /// Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) {
        print('getUserProfile: No current user');
        return null;
      }

      print('getUserProfile: Fetching profile for user ${currentUser!.uid}');

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .get(const GetOptions(source: Source.server));

      if (!doc.exists) {
        print('getUserProfile: No document exists, creating default profile');
        // If document doesn't exist, create it with default values
        Map<String, dynamic> defaultData = {
          'email': currentUser!.email,
          'isFarmer': false,
          'isVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'uid': currentUser!.uid,
        };

        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .set(defaultData);
        return defaultData;
      }

      // Safely cast the data to Map<String, dynamic>
      final data = doc.data();
      if (data == null) {
        print('getUserProfile: Document exists but data is null');
        return null;
      }

      // Ensure we have a Map<String, dynamic>
      if (data is! Map<String, dynamic>) {
        print('getUserProfile: Invalid data type: ${data.runtimeType}');
        return null;
      }

      print('getUserProfile: Retrieved data: $data');

      // Ensure required fields exist with proper types
      final Map<String, dynamic> profileData = {
        'email': data['email'] ?? currentUser!.email,
        'isFarmer': data['isFarmer'] == true,
        'isVerified': data['isVerified'] == true,
        'uid': currentUser!.uid,
      };

      return profileData;
    } catch (e) {
      print('getUserProfile error: $e');
      return null;
    }
  }

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password, {
    bool isFarmer = false,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'isFarmer': isFarmer,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
    String? phoneNumber,
    String? address,
    String? bio,
  }) async {
    try {
      if (currentUser == null) throw 'No user is currently signed in.';

      // Update auth profile
      if (name != null) {
        await currentUser!.updateDisplayName(name);
      }
      if (photoURL != null) {
        await currentUser!.updatePhotoURL(photoURL);
      }

      // Update Firestore profile
      Map<String, dynamic> updateData = {};
      if (name != null) updateData['name'] = name;
      if (photoURL != null) updateData['profileImageUrl'] = photoURL;
      if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
      if (address != null) updateData['address'] = address;
      if (bio != null) updateData['bio'] = bio;

      if (updateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(updateData);
      }
    } catch (e) {
      throw 'Failed to update profile. Please try again.';
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Resend email verification
  Future<void> resendEmailVerification() async {
    try {
      if (currentUser == null) throw 'No user is currently signed in.';
      if (currentUser!.emailVerified) throw 'Email is already verified.';

      await currentUser!.sendEmailVerification();
    } catch (e) {
      throw 'Failed to send verification email. Please try again.';
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      if (currentUser == null) return false;

      // Reload user to get latest email verification status
      await currentUser!.reload();
      return currentUser!.emailVerified;
    } catch (e) {
      return false;
    }
  }

  /// Change username
  Future<void> changeUsername(String newUsername) async {
    try {
      if (currentUser == null) throw 'No user is currently signed in.';

      // Update in Firebase Auth
      await currentUser!.updateDisplayName(newUsername);

      // Update in Firestore
      await _firestore
          .collection('users')
          .doc(currentUser!.uid)
          .update({'name': newUsername});
    } catch (e) {
      throw 'Failed to update username. Please try again.';
    }
  }

  /// Change password
  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      if (currentUser == null) throw 'No user is currently signed in.';

      // Reauthenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: currentUser!.email!,
        password: currentPassword,
      );

      await currentUser!.reauthenticateWithCredential(credential);
      await currentUser!.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'wrong-password':
          message = 'Current password is incorrect.';
          break;
        case 'weak-password':
          message = 'The new password is too weak.';
          break;
        default:
          message = 'Failed to change password. Please try again.';
      }
      throw message;
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Failed to logout. Please try again.';
    }
  }
}
