// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // final FirebaseAuth _auth = FirebaseAuth.instance;
  // final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  // User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  // Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    // try {
    //   if (currentUser == null) return null;

    //   DocumentSnapshot doc =
    //       await _firestore.collection('users').doc(currentUser!.uid).get();

    //   return doc.data() as Map<String, dynamic>?;
    // } catch (e) {
    //   rethrow;
    // }
    return null;
  }

  // Sign in with email and password
  Future<dynamic> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // try {
    //   return await _auth.signInWithEmailAndPassword(
    //     email: email,
    //     password: password,
    //   );
    // } on FirebaseAuthException catch (e) {
    //   String message;
    //   switch (e.code) {
    //     case 'user-not-found':
    //       message = 'No user found with this email.';
    //       break;
    //     case 'wrong-password':
    //       message = 'Wrong password provided.';
    //       break;
    //     case 'invalid-email':
    //       message = 'The email address is invalid.';
    //       break;
    //     case 'user-disabled':
    //       message = 'This user account has been disabled.';
    //       break;
    //     default:
    //       message = 'An error occurred. Please try again.';
    //   }
    //   throw message;
    // }
    return null;
  }

  // Register with email and password
  Future<dynamic> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
    bool isFarmer,
  ) async {
    // try {
    //   UserCredential result = await _auth.createUserWithEmailAndPassword(
    //     email: email,
    //     password: password,
    //   );

    //   // Create user document in Firestore
    //   await _firestore.collection('users').doc(result.user!.uid).set({
    //     'name': name,
    //     'email': email,
    //     'isFarmer': isFarmer,
    //     'isVerified': false,
    //     'createdAt': FieldValue.serverTimestamp(),
    //     'phoneNumber': '',
    //     'address': '',
    //     'bio': '',
    //     'profileImageUrl': '',
    //   });

    //   return result;
    // } on FirebaseAuthException catch (e) {
    //   String message;
    //   switch (e.code) {
    //     case 'weak-password':
    //     message = 'The password provided is too weak.';
    //     break;
    //     case 'email-already-in-use':
    //     message = 'An account already exists for that email.';
    //     break;
    //     case 'invalid-email':
    //     message = 'The email address is invalid.';
    //     break;
    //     default:
    //     message = 'An error occurred. Please try again.';
    //   }
    //   throw message;
    // }
    return null;
  }

  // Sign out
  Future<void> signOut() async {
    // try {
    //   return await _auth.signOut();
    // } catch (e) {
    //   throw 'Failed to sign out. Please try again.';
    // }
  }

  // Update user profile
  Future<void> updateUserProfile({
    String? name,
    String? photoURL,
    String? phoneNumber,
    String? address,
    String? bio,
  }) async {
    // try {
    //   if (currentUser == null) throw 'No user is currently signed in.';

    //   // Update auth profile
    //   if (name != null) {
    //     await currentUser!.updateDisplayName(name);
    //   }
    //   if (photoURL != null) {
    //     await currentUser!.updatePhotoURL(photoURL);
    //   }

    //   // Update Firestore profile
    //   Map<String, dynamic> updateData = {};
    //   if (name != null) updateData['name'] = name;
    //   if (photoURL != null) updateData['profileImageUrl'] = photoURL;
    //   if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
    //   if (address != null) updateData['address'] = address;
    //   if (bio != null) updateData['bio'] = bio;

    //   if (updateData.isNotEmpty) {
    //     await _firestore
    //         .collection('users')
    //         .doc(currentUser!.uid)
    //         .update(updateData);
    //   }
    // } catch (e) {
    //   throw 'Failed to update profile. Please try again.';
    // }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    // try {
    //   await _auth.sendPasswordResetEmail(email: email);
    // } on FirebaseAuthException catch (e) {
    //   String message;
    //   switch (e.code) {
    //     case 'user-not-found':
    //     message = 'No user found with this email.';
    //     break;
    //     case 'invalid-email':
    //     message = 'The email address is invalid.';
    //     break;
    //     default:
    //     message = 'An error occurred. Please try again.';
    //   }
    //   throw message;
    // }
  }
}
