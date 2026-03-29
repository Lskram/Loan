import 'dart:io';

import 'storage_backend_base.dart';

class FileStorageBackend implements StorageBackend {
  FileStorageBackend() : _file = File(_resolvePath());

  final File _file;

  @override
  Future<String?> read(String key) async {
    if (!await _file.exists()) {
      return null;
    }
    return _file.readAsString();
  }

  @override
  Future<void> write(String key, String value) async {
    await _file.parent.create(recursive: true);
    await _file.writeAsString(value, flush: true);
  }

  static String _resolvePath() {
    if (Platform.isWindows) {
      final String root =
          Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
      return '$root\\NichaLoanDesk\\loan_app_data.json';
    }

    final String root = Platform.environment['HOME'] ?? Directory.current.path;
    return '$root/.nicha_loan_desk/loan_app_data.json';
  }
}

StorageBackend createStorageBackend() {
  return FileStorageBackend();
}
