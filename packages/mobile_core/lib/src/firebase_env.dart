import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class FirebaseEnvConfig {
  static String get apiKey => const String.fromEnvironment('FIREBASE_API_KEY');
  static String get authDomain =>
      const String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static String get projectId =>
      const String.fromEnvironment('FIREBASE_PROJECT_ID');
  static String get storageBucket =>
      const String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static String get messagingSenderId =>
      const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static String get iosBundleId =>
      const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');
  static String get appIdWeb =>
      const String.fromEnvironment('FIREBASE_APP_ID_WEB');
  static String get appIdAndroid =>
      const String.fromEnvironment('FIREBASE_APP_ID_ANDROID');
  static String get appIdIos =>
      const String.fromEnvironment('FIREBASE_APP_ID_IOS');

  static bool get isConfigured =>
      apiKey.isNotEmpty &&
      projectId.isNotEmpty &&
      storageBucket.isNotEmpty &&
      messagingSenderId.isNotEmpty &&
      currentAppId.isNotEmpty;

  static String get currentAppId {
    if (kIsWeb) {
      return appIdWeb;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return appIdIos;
      default:
        return appIdAndroid;
    }
  }

  static FirebaseOptions get currentOptions {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: currentAppId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      authDomain: authDomain.isEmpty ? null : authDomain,
      storageBucket: storageBucket,
      iosBundleId: iosBundleId.isEmpty ? null : iosBundleId,
    );
  }
}
