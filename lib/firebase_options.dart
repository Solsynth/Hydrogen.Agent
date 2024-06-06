// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        return windows;
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
    apiKey: 'AIzaSyBKfIQpTouj5rXnlzkEieSlbAzepm4mgJE',
    appId: '1:961776991058:web:b91d12f2892a5609f4188b',
    messagingSenderId: '961776991058',
    projectId: 'solian-0x001',
    authDomain: 'solian-0x001.firebaseapp.com',
    storageBucket: 'solian-0x001.appspot.com',
    measurementId: 'G-XY3HHKG0PE',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDvFNudXYs29uDtcCv6pFR8h5tXBs90FYk',
    appId: '1:961776991058:android:a8d3f7995b0b8e86f4188b',
    messagingSenderId: '961776991058',
    projectId: 'solian-0x001',
    storageBucket: 'solian-0x001.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCzQIyiYKoYHTpGXhN-IjgMML8z797WVD8',
    appId: '1:961776991058:ios:727229d368cc47e1f4188b',
    messagingSenderId: '961776991058',
    projectId: 'solian-0x001',
    storageBucket: 'solian-0x001.appspot.com',
    iosBundleId: 'dev.solsynth.solian',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCzQIyiYKoYHTpGXhN-IjgMML8z797WVD8',
    appId: '1:961776991058:ios:727229d368cc47e1f4188b',
    messagingSenderId: '961776991058',
    projectId: 'solian-0x001',
    storageBucket: 'solian-0x001.appspot.com',
    iosBundleId: 'dev.solsynth.solian',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBKfIQpTouj5rXnlzkEieSlbAzepm4mgJE',
    appId: '1:961776991058:web:dcd731c8c5ce1281f4188b',
    messagingSenderId: '961776991058',
    projectId: 'solian-0x001',
    authDomain: 'solian-0x001.firebaseapp.com',
    storageBucket: 'solian-0x001.appspot.com',
    measurementId: 'G-EF9BZMKBC3',
  );
}
