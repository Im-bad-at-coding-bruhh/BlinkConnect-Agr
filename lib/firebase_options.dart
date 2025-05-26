import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBt6qDhbT5_V8RViKYGidi5vYDlb8hMKUY',
    appId: '1:486950115709:web:278984b807b35870619414',
    messagingSenderId: '486950115709',
    projectId: 'blinkconnect-agri',
    authDomain: 'blinkconnect-agri.firebaseapp.com',
    storageBucket: 'blinkconnect-agri.firebasestorage.app',
    measurementId: 'G-SZZLMQH9Z8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBt6qDhbT5_V8RViKYGidi5vYDlb8hMKUY',
    appId: '1:486950115709:android:9020be0f26c32fca619414',
    messagingSenderId: '486950115709',
    projectId: 'blinkconnect-agri',
    storageBucket: 'blinkconnect-agri.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBt6qDhbT5_V8RViKYGidi5vYDlb8hMKUY',
    appId: '1:486950115709:ios:be952424f0b772e8619414',
    messagingSenderId: '486950115709',
    projectId: 'blinkconnect-agri',
    storageBucket: 'blinkconnect-agri.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID',
    iosBundleId: 'com.BlinkConnect.apps',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBt6qDhbT5_V8RViKYGidi5vYDlb8hMKUY',
    appId: '1:486950115709:macos:YOUR_MACOS_APP_ID',
    messagingSenderId: '486950115709',
    projectId: 'blinkconnect-agri',
    storageBucket: 'blinkconnect-agri.firebasestorage.app',
    iosBundleId: 'com.BlinkConnect.apps',
  );
}
