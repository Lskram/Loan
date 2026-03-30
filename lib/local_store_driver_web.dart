// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:convert';
import 'dart:html' as html;

import 'local_store_driver_base.dart';
import 'models.dart';

class WebLocalStoreDriver implements LocalStoreDriver {
  static const String _storageKey = 'loan_management_app_db_v1';

  @override
  Future<AppData> load() async {
    final String? raw = html.window.localStorage[_storageKey];
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

  @override
  Future<void> save(AppData data) async {
    html.window.localStorage[_storageKey] = data.toJsonString();
  }
}

Future<LocalStoreDriver> createLocalStoreDriver() async {
  return WebLocalStoreDriver();
}
