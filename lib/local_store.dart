import 'models.dart';
import 'local_store_driver.dart';

class LocalStore {
  LocalStore._(this._driver);

  static LocalStoreDriver? debugDriver;

  final LocalStoreDriver _driver;

  static Future<LocalStore> create() async {
    return LocalStore._(debugDriver ?? await createPlatformLocalStoreDriver());
  }

  Future<AppData> load() => _driver.load();

  Future<void> save(AppData data) => _driver.save(data);
}
