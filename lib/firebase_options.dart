// Replace this file by running: dart run flutterfire_cli:flutterfire configure
// Values below are placeholders so the project compiles before you connect a Firebase project.

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'recipe-creator-ai-placeholder',
    authDomain: 'recipe-creator-ai-placeholder.firebaseapp.com',
    storageBucket: 'recipe-creator-ai-placeholder.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:android:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'recipe-creator-ai-placeholder',
    storageBucket: 'recipe-creator-ai-placeholder.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'recipe-creator-ai-placeholder',
    storageBucket: 'recipe-creator-ai-placeholder.appspot.com',
    iosBundleId: 'com.example.recipeCreatorAi',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_ME',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'recipe-creator-ai-placeholder',
    storageBucket: 'recipe-creator-ai-placeholder.appspot.com',
    iosBundleId: 'com.example.recipeCreatorAi',
  );
}
