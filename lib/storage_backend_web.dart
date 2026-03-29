// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:html' as html;

import 'storage_backend_base.dart';

class WebStorageBackend implements StorageBackend {
  @override
  Future<String?> read(String key) async => html.window.localStorage[key];

  @override
  Future<void> write(String key, String value) async {
    html.window.localStorage[key] = value;
  }
}

StorageBackend createStorageBackend() {
  return WebStorageBackend();
}
