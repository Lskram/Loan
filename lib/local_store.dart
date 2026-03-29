import 'dart:convert';

import 'models.dart';
import 'storage_backend.dart';

class LocalStore {
  LocalStore._(this._backend);

  static const String _storageKey = 'loan_management_app_db_v1';
  static StorageBackend? debugBackend;

  final StorageBackend _backend;

  static Future<LocalStore> create() async {
    return LocalStore._(debugBackend ?? createPlatformStorageBackend());
  }

  Future<AppData> load() async {
    final String? raw = await _backend.read(_storageKey);
    if (raw == null || raw.isEmpty) {
      return AppData.empty(DateTime.now());
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AppData.fromJson(decoded);
      }
    } catch (_) {
      return AppData.empty(DateTime.now());
    }

    return AppData.empty(DateTime.now());
  }

  Future<void> save(AppData data) {
    return _backend.write(_storageKey, data.toJsonString());
  }
}
