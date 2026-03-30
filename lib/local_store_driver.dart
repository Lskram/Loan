export 'local_store_driver_base.dart';

import 'local_store_driver_base.dart';
import 'local_store_driver_stub.dart'
    if (dart.library.io) 'local_store_driver_io.dart'
    if (dart.library.html) 'local_store_driver_web.dart'
    as driver_impl;

Future<LocalStoreDriver> createPlatformLocalStoreDriver() {
  return driver_impl.createLocalStoreDriver();
}
