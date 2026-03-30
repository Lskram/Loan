import 'google_sheets_sync_config.dart';
import 'sync_config_loader_stub.dart'
    if (dart.library.io) 'sync_config_loader_io.dart'
    if (dart.library.html) 'sync_config_loader_web.dart'
    as loader_impl;

Future<GoogleSheetsSyncConfig> loadGoogleSheetsSyncConfig() {
  return loader_impl.loadGoogleSheetsSyncConfig();
}
