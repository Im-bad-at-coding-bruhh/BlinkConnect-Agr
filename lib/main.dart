import 'package:flutter/material.dart';
import 'package:device_preview/device_preview.dart';
import 'package:provider/provider.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'firebase_options.dart';
import 'pages/theme_provider.dart';
import 'services/cart_service.dart';
import 'pages/product_provider.dart';
import 'pages/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // try {
  //   // Initialize Firebase
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );

  //   // Connect to emulators only in debug mode
  //   assert(() {
  //     FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
  //     FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
  //     FirebaseStorage.instance.useStorageEmulator('localhost', 9199);
  //     return true;
  //   }());

  runApp(
    DevicePreview(
      enabled: true,
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => ThemeProvider()),
          ChangeNotifierProvider(create: (context) => CartService()),
          ChangeNotifierProvider(create: (_) => ProductProvider()),
        ],
        child: const MyApp(),
      ),
    ),
  );
  // } catch (e) {
  //   print('Failed to initialize Firebase: $e');
  //   // Show error UI or handle the error appropriately
  //   runApp(
  //     MaterialApp(
  //       home: Scaffold(
  //         body: Center(
  //           child: Text('Failed to initialize app: $e'),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          locale: DevicePreview.locale(context),
          builder: DevicePreview.appBuilder,
          theme: themeProvider.isDarkMode
              ? themeProvider.darkTheme
              : ThemeData.light(),
          debugShowCheckedModeBanner: false,
          home: const SplashScreen(), // Using the existing SplashScreen
        );
      },
    );
  }
}
