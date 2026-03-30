import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'google_sheets_sync_config.dart';

Future<GoogleSheetsSyncConfig> loadGoogleSheetsSyncConfig() async {
  const String envEndpointUrl = String.fromEnvironment(
    'GOOGLE_SHEETS_SYNC_URL',
  );
  const String envToken = String.fromEnvironment('GOOGLE_SHEETS_SYNC_TOKEN');
  if (envEndpointUrl.trim().isNotEmpty) {
    return GoogleSheetsSyncConfig(
      endpointUrl: envEndpointUrl,
      token: envToken.isEmpty ? null : envToken,
    );
  }

  final File configFile = File(_resolveConfigPath());
  if (!await configFile.exists()) {
    return GoogleSheetsSyncConfig.empty;
  }

  try {
    final String raw = await configFile.readAsString();
    final Object? decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      return GoogleSheetsSyncConfig.empty;
    }

    final String endpointUrl = (decoded['endpointUrl'] as String? ?? '').trim();
    final String token = (decoded['token'] as String? ?? '').trim();
    if (endpointUrl.isEmpty) {
      return GoogleSheetsSyncConfig.empty;
    }

    return GoogleSheetsSyncConfig(
      endpointUrl: endpointUrl,
      token: token.isEmpty ? null : token,
    );
  } catch (_) {
    return GoogleSheetsSyncConfig.empty;
  }
}

String _resolveConfigPath() {
  if (Platform.isWindows) {
    final String root =
        Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
    return p.join(root, 'NichaLoanDesk', 'sync_config.json');
  }

  final String root = Platform.environment['HOME'] ?? Directory.current.path;
  return p.join(root, '.nicha_loan_desk', 'sync_config.json');
}
