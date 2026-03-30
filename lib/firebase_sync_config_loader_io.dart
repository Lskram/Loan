import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'firebase_sync_config.dart';

Future<FirebaseSyncConfig> loadFirebaseSyncConfig() async {
  const String rawConfig = String.fromEnvironment('FIREBASE_SYNC_CONFIG_JSON');
  if (rawConfig.trim().isNotEmpty) {
    final FirebaseSyncConfig? config = _parseConfig(rawConfig);
    if (config != null) {
      return config;
    }
  }

  final File configFile = File(_resolveConfigPath());
  if (!await configFile.exists()) {
    return FirebaseSyncConfig.empty;
  }

  try {
    final String fileContents = await configFile.readAsString();
    return _parseConfig(fileContents) ?? FirebaseSyncConfig.empty;
  } catch (_) {
    return FirebaseSyncConfig.empty;
  }
}

FirebaseSyncConfig? _parseConfig(String raw) {
  try {
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    return FirebaseSyncConfig.fromJson(decoded);
  } catch (_) {
    return null;
  }
}

String _resolveConfigPath() {
  if (Platform.isWindows) {
    final String root =
        Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
    return p.join(root, 'NichaLoanDesk', 'firebase_sync_config.json');
  }

  final String root = Platform.environment['HOME'] ?? Directory.current.path;
  return p.join(root, '.nicha_loan_desk', 'firebase_sync_config.json');
}
