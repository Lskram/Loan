abstract class StorageBackend {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemoryStorageBackend implements StorageBackend {
  final Map<String, String> _store = <String, String>{};

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    _store[key] = value;
  }
}
