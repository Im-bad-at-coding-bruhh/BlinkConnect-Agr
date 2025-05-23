// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/foundation.dart';
// import 'firebase_options.dart';

// class FirebaseInit {
//   static Future<void> initialize() async {
//     try {
//       if (kIsWeb) {
//         await Firebase.initializeApp(
//           options: const FirebaseOptions(
//               apiKey: "AIzaSyBt6qDhbT5_V8RViKYGidi5vYDlb8hMKUY",
//               authDomain: "blinkconnect-agri.firebaseapp.com",
//               projectId: "blinkconnect-agri",
//               storageBucket: "blinkconnect-agri.firebasestorage.app",
//               messagingSenderId: "486950115709",
//               appId: "1:486950115709:web:278984b807b35870619414",
//               measurementId: "G-SZZLMQH9Z8"),
//         );
//       } else {
//         await Firebase.initializeApp(
//           options: DefaultFirebaseOptions.currentPlatform,
//         );
//       }
//     } catch (e) {
//       debugPrint('Firebase initialization error: $e');
//       rethrow;
//     }
//   }
// }
