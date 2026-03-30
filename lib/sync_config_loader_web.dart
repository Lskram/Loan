import 'google_sheets_sync_config.dart';

Future<GoogleSheetsSyncConfig> loadGoogleSheetsSyncConfig() async {
  const String endpointUrl = String.fromEnvironment('GOOGLE_SHEETS_SYNC_URL');
  const String token = String.fromEnvironment('GOOGLE_SHEETS_SYNC_TOKEN');
  if (endpointUrl.trim().isEmpty) {
    return GoogleSheetsSyncConfig.empty;
  }

  return GoogleSheetsSyncConfig(
    endpointUrl: endpointUrl,
    token: token.isEmpty ? null : token,
  );
}
