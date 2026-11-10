// ⚠️ TEMPLATE FILE — placeholders only.
//
// Run `flutterfire configure` (see README, "Firebase production setup")
// and this file is fully regenerated with your real project values. Until
// then, main.dart detects the placeholders and runs NARA in local mode.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('NARA v1 targets Android only.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'NARA v1 targets Android only. Run `flutterfire configure` '
          'and add more platforms if needed.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'your-project-id',
    storageBucket: 'your-project-id.firebasestorage.app',
  );
}
