import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebasePlatformSyncConfig {
  const FirebasePlatformSyncConfig({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.storageBucket,
    this.authDomain,
    this.databaseURL,
    this.iosBundleId,
    this.androidClientId,
    this.iosClientId,
    this.measurementId,
    this.appGroupId,
    this.deepLinkURLScheme,
  });

  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? storageBucket;
  final String? authDomain;
  final String? databaseURL;
  final String? iosBundleId;
  final String? androidClientId;
  final String? iosClientId;
  final String? measurementId;
  final String? appGroupId;
  final String? deepLinkURLScheme;

  bool get isConfigured =>
      apiKey.trim().isNotEmpty &&
      appId.trim().isNotEmpty &&
      messagingSenderId.trim().isNotEmpty &&
      projectId.trim().isNotEmpty;

  FirebaseOptions toOptions() {
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: messagingSenderId,
      projectId: projectId,
      storageBucket: _normalize(storageBucket),
      authDomain: _normalize(authDomain),
      databaseURL: _normalize(databaseURL),
      iosBundleId: _normalize(iosBundleId),
      androidClientId: _normalize(androidClientId),
      iosClientId: _normalize(iosClientId),
      measurementId: _normalize(measurementId),
      appGroupId: _normalize(appGroupId),
      deepLinkURLScheme: _normalize(deepLinkURLScheme),
    );
  }

  factory FirebasePlatformSyncConfig.fromJson(Map<String, dynamic> json) {
    return FirebasePlatformSyncConfig(
      apiKey: (json['apiKey'] as String? ?? '').trim(),
      appId: (json['appId'] as String? ?? '').trim(),
      messagingSenderId: (json['messagingSenderId'] as String? ?? '').trim(),
      projectId: (json['projectId'] as String? ?? '').trim(),
      storageBucket: _normalize(json['storageBucket'] as String?),
      authDomain: _normalize(json['authDomain'] as String?),
      databaseURL: _normalize(json['databaseURL'] as String?),
      iosBundleId: _normalize(json['iosBundleId'] as String?),
      androidClientId: _normalize(json['androidClientId'] as String?),
      iosClientId: _normalize(json['iosClientId'] as String?),
      measurementId: _normalize(json['measurementId'] as String?),
      appGroupId: _normalize(json['appGroupId'] as String?),
      deepLinkURLScheme: _normalize(json['deepLinkURLScheme'] as String?),
    );
  }

  static String? _normalize(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}

class FirebaseSyncConfig {
  const FirebaseSyncConfig({this.android, this.ios, this.macos, this.web});

  final FirebasePlatformSyncConfig? android;
  final FirebasePlatformSyncConfig? ios;
  final FirebasePlatformSyncConfig? macos;
  final FirebasePlatformSyncConfig? web;

  static const FirebaseSyncConfig empty = FirebaseSyncConfig();

  bool get hasAnyConfig =>
      (android?.isConfigured ?? false) ||
      (ios?.isConfigured ?? false) ||
      (macos?.isConfigured ?? false) ||
      (web?.isConfigured ?? false);

  FirebaseOptions? optionsForCurrentPlatform() {
    if (kIsWeb) {
      if (web?.isConfigured ?? false) {
        return web!.toOptions();
      }
      return null;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android =>
        android?.isConfigured ?? false ? android!.toOptions() : null,
      TargetPlatform.iOS =>
        ios?.isConfigured ?? false ? ios!.toOptions() : null,
      TargetPlatform.macOS =>
        macos?.isConfigured ?? false
            ? macos!.toOptions()
            : (ios?.isConfigured ?? false ? ios!.toOptions() : null),
      TargetPlatform.fuchsia => null,
      TargetPlatform.linux => null,
      TargetPlatform.windows => null,
    };
  }

  factory FirebaseSyncConfig.fromJson(Map<String, dynamic> json) {
    return FirebaseSyncConfig(
      android: _platformConfigFrom(json['android']),
      ios: _platformConfigFrom(json['ios']),
      macos: _platformConfigFrom(json['macos']),
      web: _platformConfigFrom(json['web']),
    );
  }

  static FirebasePlatformSyncConfig? _platformConfigFrom(Object? value) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    final FirebasePlatformSyncConfig config =
        FirebasePlatformSyncConfig.fromJson(value);
    return config.isConfigured ? config : null;
  }
}
