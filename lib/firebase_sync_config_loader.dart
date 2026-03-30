import 'firebase_sync_config.dart';
import 'firebase_sync_config_loader_stub.dart'
    if (dart.library.io) 'firebase_sync_config_loader_io.dart'
    if (dart.library.html) 'firebase_sync_config_loader_web.dart'
    as loader_impl;

Future<FirebaseSyncConfig> loadFirebaseSyncConfig() {
  return loader_impl.loadFirebaseSyncConfig();
}
