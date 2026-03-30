import 'models.dart';

abstract class LocalStoreDriver {
  Future<AppData> load();
  Future<void> save(AppData data);
}

class MemoryLocalStoreDriver implements LocalStoreDriver {
  MemoryLocalStoreDriver({AppData? seedData}) : _data = seedData;

  AppData? _data;

  @override
  Future<AppData> load() async {
    return _data ?? AppData.empty(DateTime.now());
  }

  @override
  Future<void> save(AppData data) async {
    _data = data;
  }
}
