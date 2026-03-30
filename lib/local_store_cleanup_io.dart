import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> purgeLegacyLocalStoreData() async {
  final String databasePath = await _resolveDatabasePath();
  final String legacyJsonPath = _resolveLegacyJsonPath();
  final List<String> paths = <String>{
    databasePath,
    '$databasePath-journal',
    '$databasePath-shm',
    '$databasePath-wal',
    legacyJsonPath,
    '$legacyJsonPath.migrated',
  }.toList();

  for (final String path in paths) {
    try {
      final File file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // Ignore cleanup failures so startup can continue.
    }
  }
}

Future<String> _resolveDatabasePath() async {
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    final String root = await databaseFactoryFfi.getDatabasesPath();
    return p.join(root, 'loan_app_data.db');
  }

  final String root = await sqflite.getDatabasesPath();
  return p.join(root, 'loan_app_data.db');
}

String _resolveLegacyJsonPath() {
  if (Platform.isWindows) {
    final String root =
        Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
    return p.join(root, 'NichaLoanDesk', 'loan_app_data.json');
  }

  final String root = Platform.environment['HOME'] ?? Directory.current.path;
  return p.join(root, '.nicha_loan_desk', 'loan_app_data.json');
}
