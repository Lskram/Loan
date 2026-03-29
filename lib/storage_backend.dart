export 'storage_backend_base.dart';

import 'storage_backend_base.dart';
import 'storage_backend_stub.dart'
    if (dart.library.io) 'storage_backend_io.dart'
    if (dart.library.html) 'storage_backend_web.dart'
    as backend_impl;

StorageBackend createPlatformStorageBackend() {
  return backend_impl.createStorageBackend();
}
