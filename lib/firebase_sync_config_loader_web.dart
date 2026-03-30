import 'dart:convert';

import 'firebase_sync_config.dart';

Future<FirebaseSyncConfig> loadFirebaseSyncConfig() async {
  const String rawConfig = String.fromEnvironment('FIREBASE_SYNC_CONFIG_JSON');
  if (rawConfig.trim().isEmpty) {
    return FirebaseSyncConfig.empty;
  }

  try {
    final Object? decoded = jsonDecode(rawConfig);
    if (decoded is! Map<String, dynamic>) {
      return FirebaseSyncConfig.empty;
    }

    return FirebaseSyncConfig.fromJson(decoded);
  } catch (_) {
    return FirebaseSyncConfig.empty;
  }
}
