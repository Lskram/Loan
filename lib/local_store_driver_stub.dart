import 'local_store_driver_base.dart';

Future<LocalStoreDriver> createLocalStoreDriver() async {
  return MemoryLocalStoreDriver();
}
