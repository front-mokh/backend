import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FirebaseEnvOptions {
  FirebaseEnvOptions._();

  static FirebaseOptions? get currentPlatform {
    final apiKey = _env('FIREBASE_API_KEY');
    final projectId = _env('FIREBASE_PROJECT_ID');
    final messagingSenderId = _env('FIREBASE_MESSAGING_SENDER_ID');
    final appId = _platformAppId;

    if (apiKey == null ||
        projectId == null ||
        messagingSenderId == null ||
        appId == null) {
      return null;
    }

    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: _env('FIREBASE_STORAGE_BUCKET'),
      iosBundleId: _env('FIREBASE_IOS_BUNDLE_ID'),
      androidClientId: _env('FIREBASE_ANDROID_CLIENT_ID'),
      iosClientId: _env('FIREBASE_IOS_CLIENT_ID'),
    );
  }

  static String? get platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'unknown';
    }
  }

  static String? get _platformAppId {
    if (kIsWeb) return _env('FIREBASE_WEB_APP_ID') ?? _env('FIREBASE_APP_ID');
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _env('FIREBASE_ANDROID_APP_ID') ?? _env('FIREBASE_APP_ID');
      case TargetPlatform.iOS:
        return _env('FIREBASE_IOS_APP_ID') ?? _env('FIREBASE_APP_ID');
      case TargetPlatform.macOS:
        return _env('FIREBASE_MACOS_APP_ID') ?? _env('FIREBASE_APP_ID');
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        return _env('FIREBASE_APP_ID');
    }
  }

  static String? _env(String key) {
    final value = dotenv.env[key]?.trim();
    return value == null || value.isEmpty ? null : value;
  }
}
