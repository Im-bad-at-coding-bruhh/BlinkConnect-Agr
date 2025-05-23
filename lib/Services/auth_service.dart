// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   /// Get current user
//   User? get currentUser => _auth.currentUser;

//   /// Auth state changes stream
//   Stream<User?> get authStateChanges => _auth.authStateChanges();

//   /// Get user profile data
//   Future<Map<String, dynamic>?> getUserProfile() async {
//     try {
//       if (currentUser == null) return null;

//       DocumentSnapshot doc =
//           await _firestore.collection('users').doc(currentUser!.uid).get();

//       if (!doc.exists) return null;
//       return doc.data() as Map<String, dynamic>?;
//     } catch (e) {
//       throw 'Failed to get user profile. Please try again.';
//     }
//   }

//   /// Sign in with email and password
//   Future<UserCredential> signInWithEmailAndPassword(
//     String email,
//     String password,
//   ) async {
//     try {
//       final result = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       if (!result.user!.emailVerified) {
//         await signOut();
//         throw 'Please verify your email before signing in.';
//       }

//       return result;
//     } on FirebaseAuthException catch (e) {
//       String message;
//       switch (e.code) {
//         case 'user-not-found':
//           message = 'No user found with this email.';
//           break;
//         case 'wrong-password':
//           message = 'Wrong password provided.';
//           break;
//         case 'invalid-email':
//           message = 'The email address is invalid.';
//           break;
//         case 'user-disabled':
//           message = 'This user account has been disabled.';
//           break;
//         default:
//           message = 'An error occurred. Please try again.';
//       }
//       throw message;
//     }
//   }

//   /// Register with email and password
//   Future<UserCredential> registerWithEmailAndPassword(
//     String email,
//     String password,
//     String name,
//     bool isFarmer,
//   ) async {
//     try {
//       final result = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );

//       // Send email verification
//       await result.user!.sendEmailVerification();

//       // Create user document in Firestore
//       await _firestore.collection('users').doc(result.user!.uid).set({
//         'name': name,
//         'email': email,
//         'isFarmer': isFarmer,
//         'isVerified': false,
//         'createdAt': FieldValue.serverTimestamp(),
//         'phoneNumber': '',
//         'address': '',
//         'bio': '',
//         'profileImageUrl': '',
//       });

//       return result;
//     } on FirebaseAuthException catch (e) {
//       String message;
//       switch (e.code) {
//         case 'weak-password':
//           message = 'The password provided is too weak.';
//           break;
//         case 'email-already-in-use':
//           message = 'An account already exists for that email.';
//           break;
//         case 'invalid-email':
//           message = 'The email address is invalid.';
//           break;
//         default:
//           message = 'An error occurred. Please try again.';
//       }
//       throw message;
//     }
//   }

//   /// Sign out
//   Future<void> signOut() async {
//     try {
//       await _auth.signOut();
//     } catch (e) {
//       throw 'Failed to sign out. Please try again.';
//     }
//   }

//   /// Update user profile
//   Future<void> updateUserProfile({
//     String? name,
//     String? photoURL,
//     String? phoneNumber,
//     String? address,
//     String? bio,
//   }) async {
//     try {
//       if (currentUser == null) throw 'No user is currently signed in.';

//       // Update auth profile
//       if (name != null) {
//         await currentUser!.updateDisplayName(name);
//       }
//       if (photoURL != null) {
//         await currentUser!.updatePhotoURL(photoURL);
//       }

//       // Update Firestore profile
//       Map<String, dynamic> updateData = {};
//       if (name != null) updateData['name'] = name;
//       if (photoURL != null) updateData['profileImageUrl'] = photoURL;
//       if (phoneNumber != null) updateData['phoneNumber'] = phoneNumber;
//       if (address != null) updateData['address'] = address;
//       if (bio != null) updateData['bio'] = bio;

//       if (updateData.isNotEmpty) {
//         await _firestore
//             .collection('users')
//             .doc(currentUser!.uid)
//             .update(updateData);
//       }
//     } catch (e) {
//       throw 'Failed to update profile. Please try again.';
//     }
//   }

//   /// Reset password
//   Future<void> resetPassword(String email) async {
//     try {
//       await _auth.sendPasswordResetEmail(email: email);
//     } on FirebaseAuthException catch (e) {
//       String message;
//       switch (e.code) {
//         case 'user-not-found':
//           message = 'No user found with this email.';
//           break;
//         case 'invalid-email':
//           message = 'The email address is invalid.';
//           break;
//         default:
//           message = 'An error occurred. Please try again.';
//       }
//       throw message;
//     }
//   }

//   /// Resend email verification
//   Future<void> resendEmailVerification() async {
//     try {
//       if (currentUser == null) throw 'No user is currently signed in.';
//       if (currentUser!.emailVerified) throw 'Email is already verified.';

//       await currentUser!.sendEmailVerification();
//     } catch (e) {
//       throw 'Failed to send verification email. Please try again.';
//     }
//   }

//   /// Check if email is verified
//   Future<bool> isEmailVerified() async {
//     try {
//       if (currentUser == null) return false;

//       // Reload user to get latest email verification status
//       await currentUser!.reload();
//       return currentUser!.emailVerified;
//     } catch (e) {
//       return false;
//     }
//   }

//   /// Change username
//   Future<void> changeUsername(String newUsername) async {
//     try {
//       if (currentUser == null) throw 'No user is currently signed in.';

//       // Update in Firebase Auth
//       await currentUser!.updateDisplayName(newUsername);

//       // Update in Firestore
//       await _firestore
//           .collection('users')
//           .doc(currentUser!.uid)
//           .update({'name': newUsername});
//     } catch (e) {
//       throw 'Failed to update username. Please try again.';
//     }
//   }

//   /// Change password
//   Future<void> changePassword(
//       String currentPassword, String newPassword) async {
//     try {
//       if (currentUser == null) throw 'No user is currently signed in.';

//       // Reauthenticate user before changing password
//       final credential = EmailAuthProvider.credential(
//         email: currentUser!.email!,
//         password: currentPassword,
//       );

//       await currentUser!.reauthenticateWithCredential(credential);
//       await currentUser!.updatePassword(newPassword);
//     } on FirebaseAuthException catch (e) {
//       String message;
//       switch (e.code) {
//         case 'wrong-password':
//           message = 'Current password is incorrect.';
//           break;
//         case 'weak-password':
//           message = 'The new password is too weak.';
//           break;
//         default:
//           message = 'Failed to change password. Please try again.';
//       }
//       throw message;
//     }
//   }

//   /// Logout user
//   Future<void> logout() async {
//     try {
//       await _auth.signOut();
//     } catch (e) {
//       throw 'Failed to logout. Please try again.';
//     }
//   }
// }
