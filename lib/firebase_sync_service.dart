import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_sync_config.dart';
import 'firebase_sync_config_loader.dart';
import 'models.dart';

class FirebaseSyncResult {
  const FirebaseSyncResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class FirebaseSyncService {
  FirebaseSyncService._(
    this._firestore,
    this._setupMessage,
    this._usesRemoteSync,
  );

  static FirebaseSyncService? debugInstance;

  final FirebaseFirestore? _firestore;
  final String? _setupMessage;
  final bool _usesRemoteSync;

  bool get isConfigured => _usesRemoteSync;

  static Future<FirebaseSyncService> create() async {
    if (debugInstance != null) {
      return debugInstance!;
    }

    final FirebaseSyncConfig config = await loadFirebaseSyncConfig();
    final FirebaseOptions? options = config.optionsForCurrentPlatform();
    try {
      final FirebaseApp app;
      if (Firebase.apps.isNotEmpty) {
        app = Firebase.app();
      } else if (options != null) {
        app = await Firebase.initializeApp(options: options);
      } else {
        app = await Firebase.initializeApp();
      }
      final FirebaseFirestore firestore = FirebaseFirestore.instanceFor(
        app: app,
      );
      firestore.settings = const Settings(persistenceEnabled: false);
      try {
        await firestore.clearPersistence();
      } catch (_) {
        // Ignore failures here; persistence is still disabled for new sessions.
      }

      return FirebaseSyncService._(firestore, null, true);
    } catch (error) {
      return FirebaseSyncService._(
        null,
        options == null
            ? 'Firebase sync is not configured yet. Data will only stay available while this session is open.'
            : 'Firebase sync is unavailable: $error. Changes only stay in memory for this session.',
        false,
      );
    }
  }

  factory FirebaseSyncService.unconfigured({String? message}) {
    return FirebaseSyncService._(
      null,
      message ??
          'Firebase sync is not configured yet. Data will only stay available while this session is open.',
      false,
    );
  }

  Future<AppData?> restoreIfRemoteIsNewer(AppData localData) async {
    if (_firestore == null) {
      return null;
    }

    try {
      final FirebaseFirestore firestore = _firestore;
      final List<QuerySnapshot<Map<String, dynamic>>> snapshots =
          await Future.wait(<Future<QuerySnapshot<Map<String, dynamic>>>>[
            firestore
                .collection('borrowers')
                .get(const GetOptions(source: Source.server)),
            firestore
                .collection('deals')
                .get(const GetOptions(source: Source.server)),
            firestore
                .collection('payments')
                .get(const GetOptions(source: Source.server)),
            firestore
                .collection('events')
                .get(const GetOptions(source: Source.server)),
          ]);
      final DocumentSnapshot<Map<String, dynamic>> syncMetaSnapshot =
          await firestore
              .collection('sync_meta')
              .doc('latest')
              .get(const GetOptions(source: Source.server));

      final AppData remoteData = AppData(
        borrowers: snapshots[0].docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  Borrower.fromJson(doc.data()),
            )
            .toList(),
        deals: snapshots[1].docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  LoanDeal.fromJson(doc.data()),
            )
            .toList(),
        payments: snapshots[2].docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  PaymentRecord.fromJson(doc.data()),
            )
            .toList(),
        events: snapshots[3].docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  DealEvent.fromJson(doc.data()),
            )
            .toList(),
        syncState: localData.syncState,
      );

      if (!remoteData.hasRecords) {
        return null;
      }

      final DateTime? remoteSyncedAt = _parseRemoteSyncedAt(syncMetaSnapshot);
      final DateTime? remoteLatestAt = _maxTimestamp(
        remoteData.latestDataTimestamp,
        remoteSyncedAt,
      );
      final DateTime? localLatestAt = _maxTimestamp(
        localData.latestDataTimestamp,
        localData.syncState.lastSuccessAt,
      );

      if (localData.hasRecords &&
          remoteLatestAt != null &&
          localLatestAt != null &&
          !remoteLatestAt.isAfter(localLatestAt)) {
        return null;
      }

      return remoteData.copyWith(
        syncState: localData.syncState.copyWith(
          isConfigured: true,
          lastAttemptAt: remoteSyncedAt ?? localData.syncState.lastAttemptAt,
          lastSuccessAt: remoteSyncedAt ?? localData.syncState.lastSuccessAt,
          lastMessage: localData.hasRecords
              ? 'Loaded the newest records from Firebase.'
              : 'Recovered data from Firebase for this device.',
        ),
      );
    } catch (_) {
      return null;
    }
  }

  Future<FirebaseSyncResult> sync(
    AppData data, {
    required bool isManual,
  }) async {
    if (_firestore == null) {
      return FirebaseSyncResult(
        success: false,
        message:
            _setupMessage ??
            'Firebase sync is not configured yet. Data will only stay available while this session is open.',
      );
    }

    final FirebaseFirestore firestore = _firestore;

    try {
      await _syncCollection(
        'borrowers',
        data.borrowers.map(
          (Borrower borrower) =>
              _SyncDoc(id: borrower.id, payload: borrower.toJson()),
        ),
      );
      await _syncCollection(
        'deals',
        data.deals.map(
          (LoanDeal deal) => _SyncDoc(id: deal.id, payload: deal.toJson()),
        ),
      );
      await _syncCollection(
        'payments',
        data.payments.map(
          (PaymentRecord payment) =>
              _SyncDoc(id: payment.id, payload: payment.toJson()),
        ),
      );
      await _syncCollection(
        'events',
        data.events.map(
          (DealEvent event) => _SyncDoc(id: event.id, payload: event.toJson()),
        ),
      );
      await firestore
          .collection('sync_meta')
          .doc('latest')
          .set(<String, Object?>{
            'app': 'Nicha Loan Desk',
            'sentAt': DateTime.now().toIso8601String(),
            'borrowerCount': data.borrowers.length,
            'dealCount': data.deals.length,
            'paymentCount': data.payments.length,
            'eventCount': data.events.length,
            'lastMessage': data.syncState.lastMessage,
          });

      return FirebaseSyncResult(
        success: true,
        message: isManual
            ? 'Manual Firebase sync completed.'
            : 'Scheduled Firebase sync completed.',
      );
    } catch (error) {
      return FirebaseSyncResult(
        success: false,
        message: 'Firebase sync failed: $error',
      );
    }
  }

  Future<void> _syncCollection(
    String collection,
    Iterable<_SyncDoc> docs,
  ) async {
    final FirebaseFirestore firestore = _firestore!;
    final Map<String, Map<String, dynamic>> docsById =
        <String, Map<String, dynamic>>{
          for (final _SyncDoc doc in docs) doc.id: doc.payload,
        };
    final QuerySnapshot<Map<String, dynamic>> existingSnapshot = await firestore
        .collection(collection)
        .get(const GetOptions(source: Source.server));
    final List<_PendingRemoteChange> changes = <_PendingRemoteChange>[
      for (final MapEntry<String, Map<String, dynamic>> entry
          in docsById.entries)
        _PendingRemoteChange.set(
          firestore.collection(collection).doc(entry.key),
          entry.value,
        ),
      for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
          in existingSnapshot.docs)
        if (!docsById.containsKey(doc.id))
          _PendingRemoteChange.delete(doc.reference),
    ];

    WriteBatch batch = firestore.batch();
    int operationCount = 0;

    Future<void> commitBatch() async {
      if (operationCount == 0) {
        return;
      }
      await batch.commit();
      batch = firestore.batch();
      operationCount = 0;
    }

    for (final _PendingRemoteChange change in changes) {
      if (change.delete) {
        batch.delete(change.reference);
      } else {
        batch.set(change.reference, change.payload!);
      }
      operationCount += 1;
      if (operationCount >= 400) {
        await commitBatch();
      }
    }

    await commitBatch();
  }

  DateTime? _parseRemoteSyncedAt(
    DocumentSnapshot<Map<String, dynamic>> syncMetaSnapshot,
  ) {
    final Map<String, dynamic>? data = syncMetaSnapshot.data();
    final String? raw = data?['sentAt'] as String?;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }

  DateTime? _maxTimestamp(DateTime? first, DateTime? second) {
    if (first == null) {
      return second;
    }
    if (second == null) {
      return first;
    }
    return first.isAfter(second) ? first : second;
  }
}

class _SyncDoc {
  const _SyncDoc({required this.id, required this.payload});

  final String id;
  final Map<String, dynamic> payload;
}

class _PendingRemoteChange {
  const _PendingRemoteChange._({
    required this.reference,
    required this.delete,
    this.payload,
  });

  final DocumentReference<Map<String, dynamic>> reference;
  final bool delete;
  final Map<String, dynamic>? payload;

  factory _PendingRemoteChange.set(
    DocumentReference<Map<String, dynamic>> reference,
    Map<String, dynamic> payload,
  ) {
    return _PendingRemoteChange._(
      reference: reference,
      delete: false,
      payload: payload,
    );
  }

  factory _PendingRemoteChange.delete(
    DocumentReference<Map<String, dynamic>> reference,
  ) {
    return _PendingRemoteChange._(reference: reference, delete: true);
  }
}
