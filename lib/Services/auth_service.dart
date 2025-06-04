import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
          'isActive': true,
          'user_type': 'buyer',
          'username': currentUser!.email?.split('@')[0] ?? 'user',
          'createdAt': FieldValue.serverTimestamp(),
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
        'isActive': data['isActive'] == true,
        'user_type': data['user_type'] ?? 'buyer',
        'username':
            data['username'] ?? currentUser!.email?.split('@')[0] ?? 'user',
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
    String? username,
    String? region,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore with the required structure
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'isActive': true,
        'user_type': isFarmer ? 'farmer' : 'buyer',
        'username': username ??
            email.split('@')[0], // Use email prefix if username not provided
        'createdAt': FieldValue.serverTimestamp(),
        'region': region ?? 'Unknown', // Add region field
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

  /// Sign in with Google
  Future<UserCredential> signInWithGoogle() async {
    try {
      print('Starting Google Sign In process...');

      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      print(
          'Google Sign In result: ${googleUser != null ? 'Success' : 'Aborted'}');

      if (googleUser == null) {
        print('Google Sign In was aborted by user');
        throw 'Google sign in was cancelled';
      }

      print('Getting Google auth details...');
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      print('Got Google auth details');

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('Created Firebase credential');

      // Sign in to Firebase with the Google credential
      print('Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      print('Successfully signed in to Firebase');

      // Check if this is a new user
      final isNewUser = userCredential.additionalUserInfo?.isNewUser ?? false;
      print('Is new user: $isNewUser');

      if (isNewUser) {
        print('Creating new user profile in Firestore...');
        // Create user profile in Firestore for new users
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'isActive': true,
          'user_type': 'buyer', // Default to buyer for Google sign-in
          'username': userCredential.user!.displayName ??
              userCredential.user!.email?.split('@')[0] ??
              'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
        print('New user profile created in Firestore');
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      print(
          'Firebase Auth Error during Google Sign In: ${e.code} - ${e.message}');
      String message;
      switch (e.code) {
        case 'account-exists-with-different-credential':
          message =
              'An account already exists with the same email address but different sign-in credentials.';
          break;
        case 'invalid-credential':
          message = 'The credential is invalid or has expired.';
          break;
        case 'operation-not-allowed':
          message = 'Google Sign In is not enabled. Please contact support.';
          break;
        case 'user-disabled':
          message = 'This user account has been disabled.';
          break;
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'wrong-password':
          message = 'Wrong password provided.';
          break;
        case 'invalid-verification-code':
          message = 'The verification code is invalid.';
          break;
        case 'invalid-verification-id':
          message = 'The verification ID is invalid.';
          break;
        default:
          message =
              'An error occurred during Google Sign In. Please try again.';
      }
      throw message;
    } catch (e) {
      print('Error during Google Sign In: $e');
      throw 'Failed to sign in with Google. Please try again.';
    }
  }
}
