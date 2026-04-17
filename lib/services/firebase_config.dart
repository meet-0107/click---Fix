import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Initializes Firebase for all platforms.
/// On web, uses the provided Firebase config options.
/// On Android/iOS, uses the google-services.json / GoogleService-Info.plist.
Future<void> initializeFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyC_MnrYvwCDHgMNcTKEJeJrrEL7iVkYdAU",
        authDomain: "click-fix-86629.firebaseapp.com",
        projectId: "click-fix-86629",
        storageBucket: "click-fix-86629.firebasestorage.app",
        messagingSenderId: "350733479288",
        appId: "1:350733479288:web:b1f8aed48e0b26f8b96c8d",
        measurementId: "G-0DP3J4DBMM",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
}
