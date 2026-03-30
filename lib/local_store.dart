import 'models.dart';
import 'local_store_driver.dart';
import 'local_store_cleanup.dart';

class LocalStore {
  LocalStore._(this._driver);

  static LocalStoreDriver? debugDriver;

  final LocalStoreDriver _driver;

  static Future<LocalStore> create() async {
    if (debugDriver != null) {
      return LocalStore._(debugDriver!);
    }

    await purgeLegacyLocalStoreData();
    return LocalStore._(MemoryLocalStoreDriver());
  }

  Future<AppData> load() => _driver.load();

  Future<void> save(AppData data) => _driver.save(data);
}
