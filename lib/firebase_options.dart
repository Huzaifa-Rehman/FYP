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
        return ios;
      case TargetPlatform.windows:
        return android;
      case TargetPlatform.linux:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDpNQ_maYho24NancqL9XjPhEYPML3Z4aA',
    appId: '1:783128459089:web:2c1dc490298517279c4570',
    messagingSenderId: '783128459089',
    projectId: 'speedygroccer',
    authDomain: 'speedygroccer.firebaseapp.com',
    storageBucket: 'speedygroccer.firebasestorage.app',
    measurementId: 'G-4RJX0EBFBH',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDpNQ_maYho24NancqL9XjPhEYPML3Z4aA',
    appId: '1:783128459089:android:259ba01ec0f81a259c4570',
    messagingSenderId: '783128459089',
    projectId: 'speedygroccer',
    storageBucket: 'speedygroccer.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDpNQ_maYho24NancqL9XjPhEYPML3Z4aA',
    appId: '1:783128459089:ios:259ba01ec0f81a259c4570',
    messagingSenderId: '783128459089',
    projectId: 'speedygroccer',
    storageBucket: 'speedygroccer.firebasestorage.app',
    iosBundleId: 'com.example.speedygrocer',
  );
}
