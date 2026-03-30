import 'local_store_cleanup_stub.dart'
    if (dart.library.io) 'local_store_cleanup_io.dart'
    if (dart.library.html) 'local_store_cleanup_web.dart'
    as cleanup_impl;

Future<void> purgeLegacyLocalStoreData() {
  return cleanup_impl.purgeLegacyLocalStoreData();
}
