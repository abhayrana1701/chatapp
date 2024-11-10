// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
    apiKey: 'AIzaSyB-TFbom3Wb4UVgY1noTONUX2Li9Horhdo',
    appId: '1:247871107267:web:866f20b52ff899eb0bf276',
    messagingSenderId: '247871107267',
    projectId: 'mychatapplication-a353a',
    authDomain: 'mychatapplication-a353a.firebaseapp.com',
    storageBucket: 'mychatapplication-a353a.appspot.com',
    measurementId: 'G-QNFXBYETC9',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBL4aaa8QTCcwSxoRkgDjJ4dopi5BMyV4w',
    appId: '1:247871107267:android:5a463480720d75b50bf276',
    messagingSenderId: '247871107267',
    projectId: 'mychatapplication-a353a',
    storageBucket: 'mychatapplication-a353a.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCqAs8F2dLWZv53lsJqOvrb4nTYK3ba8M8',
    appId: '1:247871107267:ios:5f1b336edd91761c0bf276',
    messagingSenderId: '247871107267',
    projectId: 'mychatapplication-a353a',
    storageBucket: 'mychatapplication-a353a.appspot.com',
    iosBundleId: 'com.example.mychatapplication',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCqAs8F2dLWZv53lsJqOvrb4nTYK3ba8M8',
    appId: '1:247871107267:ios:8add07a6e92f75e80bf276',
    messagingSenderId: '247871107267',
    projectId: 'mychatapplication-a353a',
    storageBucket: 'mychatapplication-a353a.appspot.com',
    iosBundleId: 'com.example.mychatapplication.RunnerTests',
  );
}