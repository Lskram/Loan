import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'local_store_driver_base.dart';
import 'models.dart';

class SqliteLocalStoreDriver implements LocalStoreDriver {
  SqliteLocalStoreDriver._({
    required DatabaseFactory databaseFactory,
    required String databasePath,
    required String legacyJsonPath,
  }) : _databaseFactory = databaseFactory,
       _databasePath = databasePath,
       _legacyJsonPath = legacyJsonPath;

  static const int _databaseVersion = 1;
  static const String _databaseFileName = 'loan_app_data.db';
  static const String _syncStateKey = 'sync_state';

  final DatabaseFactory _databaseFactory;
  final String _databasePath;
  final String _legacyJsonPath;

  Database? _database;

  static Future<LocalStoreDriver> create() async {
    final DatabaseFactory databaseFactory = _resolveDatabaseFactory();
    final String databasePath = await _resolveDatabasePath(databaseFactory);
    final SqliteLocalStoreDriver driver = SqliteLocalStoreDriver._(
      databaseFactory: databaseFactory,
      databasePath: databasePath,
      legacyJsonPath: _resolveLegacyJsonPath(),
    );
    await driver._openDatabase();
    return driver;
  }

  @override
  Future<AppData> load() async {
    final Database database = await _openDatabase();
    final List<Map<String, Object?>> borrowerRows = await database.query(
      'borrowers',
    );
    final List<Map<String, Object?>> dealRows = await database.query('deals');
    final List<Map<String, Object?>> paymentRows = await database.query(
      'payments',
    );
    final List<Map<String, Object?>> eventRows = await database.query(
      'deal_events',
    );
    final List<Map<String, Object?>> metaRows = await database.query(
      'app_meta',
    );

    SyncState syncState = SyncState.initial(DateTime.now());
    for (final Map<String, Object?> row in metaRows) {
      if (row['key'] != _syncStateKey || row['value'] == null) {
        continue;
      }
      try {
        final Object? decoded = jsonDecode(row['value']! as String);
        if (decoded is Map<String, dynamic>) {
          syncState = SyncState.fromJson(decoded);
        }
      } catch (_) {
        syncState = SyncState.initial(DateTime.now());
      }
    }

    return AppData(
      borrowers: borrowerRows.map(_borrowerFromRow).toList(),
      deals: dealRows.map(_dealFromRow).toList(),
      payments: paymentRows.map(_paymentFromRow).toList(),
      events: eventRows.map(_eventFromRow).toList(),
      syncState: syncState,
    );
  }

  @override
  Future<void> save(AppData data) async {
    final Database database = await _openDatabase();
    await database.transaction((Transaction txn) async {
      await _replaceSnapshot(txn, data);
    });
  }

  Future<Database> _openDatabase() async {
    if (_database != null) {
      return _database!;
    }

    _database = await _databaseFactory.openDatabase(
      _databasePath,
      options: OpenDatabaseOptions(
        version: _databaseVersion,
        onCreate: (Database db, int version) async {
          await _createSchema(db);
        },
      ),
    );
    await _createSchema(_database!);
    await _migrateLegacyJsonIfNeeded(_database!);
    return _database!;
  }

  Future<void> _createSchema(DatabaseExecutor executor) async {
    await executor.execute('''
      CREATE TABLE IF NOT EXISTS borrowers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        phone_number TEXT NOT NULL,
        credit_level TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await executor.execute('''
      CREATE TABLE IF NOT EXISTS deals (
        id TEXT PRIMARY KEY,
        borrower_id TEXT NOT NULL,
        deal_type TEXT NOT NULL,
        principal REAL NOT NULL,
        interest_rate_percent REAL NOT NULL,
        due_date TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_closed INTEGER NOT NULL,
        closed_at TEXT,
        closed_reason TEXT
      )
    ''');

    await executor.execute('''
      CREATE TABLE IF NOT EXISTS payments (
        id TEXT PRIMARY KEY,
        deal_id TEXT NOT NULL,
        paid_at TEXT NOT NULL,
        amount REAL NOT NULL,
        remaining_after_payment REAL NOT NULL,
        note TEXT
      )
    ''');

    await executor.execute('''
      CREATE TABLE IF NOT EXISTS deal_events (
        id TEXT PRIMARY KEY,
        deal_id TEXT NOT NULL,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        description TEXT NOT NULL
      )
    ''');

    await executor.execute('''
      CREATE TABLE IF NOT EXISTS app_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _migrateLegacyJsonIfNeeded(Database database) async {
    if (!await _isDatabaseEmpty(database)) {
      return;
    }

    final File legacyFile = File(_legacyJsonPath);
    if (!await legacyFile.exists()) {
      return;
    }

    try {
      final String raw = await legacyFile.readAsString();
      if (raw.trim().isEmpty) {
        return;
      }

      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return;
      }

      final AppData migratedData = AppData.fromJson(decoded);
      await database.transaction((Transaction txn) async {
        await _replaceSnapshot(txn, migratedData);
      });

      final String backupPath = '$_legacyJsonPath.migrated';
      final File backupFile = File(backupPath);
      if (await backupFile.exists()) {
        await backupFile.delete();
      }
      await legacyFile.rename(backupPath);
    } catch (_) {
      // Keep the legacy file in place if migration fails.
    }
  }

  Future<bool> _isDatabaseEmpty(Database database) async {
    final int borrowerCount =
        sqflite.Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM borrowers'),
        ) ??
        0;
    final int dealCount =
        sqflite.Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM deals'),
        ) ??
        0;
    final int paymentCount =
        sqflite.Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM payments'),
        ) ??
        0;
    final int eventCount =
        sqflite.Sqflite.firstIntValue(
          await database.rawQuery('SELECT COUNT(*) FROM deal_events'),
        ) ??
        0;
    return borrowerCount == 0 &&
        dealCount == 0 &&
        paymentCount == 0 &&
        eventCount == 0;
  }

  Future<void> _replaceSnapshot(DatabaseExecutor executor, AppData data) async {
    await executor.delete('borrowers');
    await executor.delete('deals');
    await executor.delete('payments');
    await executor.delete('deal_events');
    await executor.delete('app_meta');

    for (final Borrower borrower in data.borrowers) {
      await executor.insert('borrowers', <String, Object?>{
        'id': borrower.id,
        'name': borrower.name,
        'phone_number': borrower.phoneNumber,
        'credit_level': borrower.creditLevel.name,
        'created_at': borrower.createdAt.toIso8601String(),
        'updated_at': borrower.updatedAt.toIso8601String(),
      });
    }

    for (final LoanDeal deal in data.deals) {
      await executor.insert('deals', <String, Object?>{
        'id': deal.id,
        'borrower_id': deal.borrowerId,
        'deal_type': deal.dealType,
        'principal': deal.principal,
        'interest_rate_percent': deal.interestRatePercent,
        'due_date': deal.dueDate.toIso8601String(),
        'created_at': deal.createdAt.toIso8601String(),
        'updated_at': deal.updatedAt.toIso8601String(),
        'is_closed': deal.isClosed ? 1 : 0,
        'closed_at': deal.closedAt?.toIso8601String(),
        'closed_reason': deal.closedReason,
      });
    }

    for (final PaymentRecord payment in data.payments) {
      await executor.insert('payments', <String, Object?>{
        'id': payment.id,
        'deal_id': payment.dealId,
        'paid_at': payment.paidAt.toIso8601String(),
        'amount': payment.amount,
        'remaining_after_payment': payment.remainingAfterPayment,
        'note': payment.note,
      });
    }

    for (final DealEvent event in data.events) {
      await executor.insert('deal_events', <String, Object?>{
        'id': event.id,
        'deal_id': event.dealId,
        'type': event.type.name,
        'created_at': event.createdAt.toIso8601String(),
        'description': event.description,
      });
    }

    await executor.insert('app_meta', <String, Object?>{
      'key': _syncStateKey,
      'value': jsonEncode(data.syncState.toJson()),
    });
  }

  static DatabaseFactory _resolveDatabaseFactory() {
    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      return databaseFactoryFfi;
    }
    return sqflite.databaseFactory;
  }

  static Future<String> _resolveDatabasePath(
    DatabaseFactory databaseFactory,
  ) async {
    final String root = (Platform.isWindows || Platform.isLinux)
        ? await databaseFactory.getDatabasesPath()
        : await sqflite.getDatabasesPath();
    return p.join(root, _databaseFileName);
  }

  static String _resolveLegacyJsonPath() {
    if (Platform.isWindows) {
      final String root =
          Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
      return p.join(root, 'NichaLoanDesk', 'loan_app_data.json');
    }

    final String root = Platform.environment['HOME'] ?? Directory.current.path;
    return p.join(root, '.nicha_loan_desk', 'loan_app_data.json');
  }

  static Borrower _borrowerFromRow(Map<String, Object?> row) {
    return Borrower(
      id: row['id']! as String,
      name: row['name']! as String,
      phoneNumber: row['phone_number']! as String,
      creditLevel: CreditLevel.values.byName(row['credit_level']! as String),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
    );
  }

  static LoanDeal _dealFromRow(Map<String, Object?> row) {
    return LoanDeal(
      id: row['id']! as String,
      borrowerId: row['borrower_id']! as String,
      dealType: row['deal_type']! as String,
      principal: (row['principal']! as num).toDouble(),
      interestRatePercent: (row['interest_rate_percent']! as num).toDouble(),
      dueDate: DateTime.parse(row['due_date']! as String),
      createdAt: DateTime.parse(row['created_at']! as String),
      updatedAt: DateTime.parse(row['updated_at']! as String),
      isClosed: (row['is_closed']! as num) == 1,
      closedAt: row['closed_at'] == null
          ? null
          : DateTime.parse(row['closed_at']! as String),
      closedReason: row['closed_reason'] as String?,
    );
  }

  static PaymentRecord _paymentFromRow(Map<String, Object?> row) {
    return PaymentRecord(
      id: row['id']! as String,
      dealId: row['deal_id']! as String,
      paidAt: DateTime.parse(row['paid_at']! as String),
      amount: (row['amount']! as num).toDouble(),
      remainingAfterPayment: (row['remaining_after_payment']! as num)
          .toDouble(),
      note: row['note'] as String?,
    );
  }

  static DealEvent _eventFromRow(Map<String, Object?> row) {
    return DealEvent(
      id: row['id']! as String,
      dealId: row['deal_id']! as String,
      type: DealEventType.values.byName(row['type']! as String),
      createdAt: DateTime.parse(row['created_at']! as String),
      description: row['description']! as String,
    );
  }
}

Future<LocalStoreDriver> createLocalStoreDriver() {
  return SqliteLocalStoreDriver.create();
}
