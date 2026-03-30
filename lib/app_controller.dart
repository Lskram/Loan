import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'firebase_sync_service.dart';
import 'local_store.dart';
import 'models.dart';

class AppController extends ChangeNotifier {
  AppController._(this._store, this._syncService, this._data)
    : _now = DateTime.now() {
    _startTicker();
    unawaited(_attemptStartupSync());
  }

  static const List<String> suggestedDealTypes = <String>[
    'Loan',
    '6 Payment Plans',
    'Credits 25%',
  ];

  final LocalStore _store;
  final FirebaseSyncService _syncService;
  final Uuid _uuid = const Uuid();

  AppData _data;
  DateTime _now;
  Timer? _ticker;
  bool _syncInFlight = false;
  bool _syncQueued = false;
  bool _queuedManualSync = false;
  bool _hasUnsyncedChanges = false;

  static Future<AppController> create() async {
    final LocalStore store = await LocalStore.create();
    final FirebaseSyncService syncService = await FirebaseSyncService.create();
    final AppData loaded = await store.load();
    final AppData? restored = syncService.isConfigured
        ? await syncService.restoreIfRemoteIsNewer(loaded)
        : null;
    if (restored != null) {
      await store.save(restored);
    }
    final AppData baseData = restored ?? loaded;
    final AppData data = baseData.copyWith(
      syncState: baseData.syncState.copyWith(
        isConfigured: syncService.isConfigured,
      ),
    );
    return AppController._(store, syncService, data);
  }

  DateTime get now => _now;
  SyncState get syncState => _data.syncState;

  List<Borrower> borrowers({String query = ''}) {
    final String normalized = query.trim().toLowerCase();
    final Iterable<Borrower> matches = _data.borrowers.where((
      Borrower borrower,
    ) {
      if (normalized.isEmpty) {
        return true;
      }

      return borrower.name.toLowerCase().contains(normalized) ||
          borrower.phoneNumber.toLowerCase().contains(normalized) ||
          borrower.id.toLowerCase().contains(normalized);
    });

    final List<Borrower> items = matches.toList()
      ..sort((Borrower a, Borrower b) => a.name.compareTo(b.name));
    return items;
  }

  List<LoanDeal> activeDeals({String query = ''}) {
    final String normalized = query.trim().toLowerCase();
    final List<LoanDeal> items =
        _data.deals.where((LoanDeal deal) {
          if (deal.isClosed) {
            return false;
          }

          if (normalized.isEmpty) {
            return true;
          }

          final Borrower? borrower = borrowerById(deal.borrowerId);
          final String borrowerName = borrower?.name.toLowerCase() ?? '';
          final String borrowerPhone =
              borrower?.phoneNumber.toLowerCase() ?? '';

          return deal.id.toLowerCase().contains(normalized) ||
              deal.dealType.toLowerCase().contains(normalized) ||
              borrowerName.contains(normalized) ||
              borrowerPhone.contains(normalized);
        }).toList()..sort((LoanDeal a, LoanDeal b) {
          final int dueCompare = a.dueDate.compareTo(b.dueDate);
          if (dueCompare != 0) {
            return dueCompare;
          }
          return b.createdAt.compareTo(a.createdAt);
        });

    return items;
  }

  List<LoanDeal> closedDeals({String query = ''}) {
    final String normalized = query.trim().toLowerCase();
    final List<LoanDeal> items =
        _data.deals.where((LoanDeal deal) {
          if (!deal.isClosed) {
            return false;
          }

          if (normalized.isEmpty) {
            return true;
          }

          final Borrower? borrower = borrowerById(deal.borrowerId);
          final String borrowerName = borrower?.name.toLowerCase() ?? '';
          final String borrowerPhone =
              borrower?.phoneNumber.toLowerCase() ?? '';

          return deal.id.toLowerCase().contains(normalized) ||
              deal.dealType.toLowerCase().contains(normalized) ||
              borrowerName.contains(normalized) ||
              borrowerPhone.contains(normalized);
        }).toList()..sort((LoanDeal a, LoanDeal b) {
          final DateTime aClosedAt = a.closedAt ?? a.updatedAt;
          final DateTime bClosedAt = b.closedAt ?? b.updatedAt;
          return bClosedAt.compareTo(aClosedAt);
        });

    return items;
  }

  Borrower? borrowerById(String borrowerId) {
    for (final Borrower borrower in _data.borrowers) {
      if (borrower.id == borrowerId) {
        return borrower;
      }
    }
    return null;
  }

  LoanDeal? dealById(String dealId) {
    for (final LoanDeal deal in _data.deals) {
      if (deal.id == dealId) {
        return deal;
      }
    }
    return null;
  }

  List<PaymentRecord> paymentsForDeal(String dealId) {
    final List<PaymentRecord> items =
        _data.payments
            .where((PaymentRecord payment) => payment.dealId == dealId)
            .toList()
          ..sort(
            (PaymentRecord a, PaymentRecord b) => b.paidAt.compareTo(a.paidAt),
          );
    return items;
  }

  List<DealEvent> eventsForDeal(String dealId) {
    final List<DealEvent> items =
        _data.events.where((DealEvent event) => event.dealId == dealId).toList()
          ..sort(
            (DealEvent a, DealEvent b) => b.createdAt.compareTo(a.createdAt),
          );
    return items;
  }

  DashboardStats get dashboardStats {
    final List<LoanDeal> active = activeDeals();
    final Set<String> activeBorrowerIds = <String>{
      for (final LoanDeal deal in active) deal.borrowerId,
    };

    double totalOutstanding = 0;
    for (final LoanDeal deal in active) {
      totalOutstanding += remainingBalanceForDeal(deal);
    }

    return DashboardStats(
      activeBorrowers: activeBorrowerIds.length,
      totalOutstanding: totalOutstanding,
      closedDeals: _data.deals.where((LoanDeal deal) => deal.isClosed).length,
      activeDeals: active.length,
    );
  }

  List<NotificationItem> notifications() {
    final List<NotificationItem> items = <NotificationItem>[];

    for (final LoanDeal deal in activeDeals()) {
      final LoanDealStatus status = statusForDeal(deal);
      if (status == LoanDealStatus.tracking ||
          status == LoanDealStatus.closed) {
        continue;
      }

      final Borrower? borrower = borrowerById(deal.borrowerId);
      items.add(
        NotificationItem(
          id: '${deal.id}-$status',
          dealId: deal.id,
          borrowerName: borrower?.name ?? 'Unknown borrower',
          dealType: deal.dealType,
          dueDate: deal.dueDate,
          remainingBalance: remainingBalanceForDeal(deal),
          status: status,
          daysOffset: daysUntilDue(deal),
        ),
      );
    }

    items.sort((NotificationItem a, NotificationItem b) {
      final int severity = _severityWeight(
        a.status,
      ).compareTo(_severityWeight(b.status));
      if (severity != 0) {
        return severity;
      }
      return a.dueDate.compareTo(b.dueDate);
    });

    return items;
  }

  int activeDealCountForBorrower(String borrowerId) {
    return _data.deals.where((LoanDeal deal) {
      return deal.borrowerId == borrowerId && !deal.isClosed;
    }).length;
  }

  double outstandingForBorrower(String borrowerId) {
    double total = 0;
    for (final LoanDeal deal in _data.deals) {
      if (deal.borrowerId == borrowerId && !deal.isClosed) {
        total += remainingBalanceForDeal(deal);
      }
    }
    return total;
  }

  bool borrowerHasLinkedDeals(String borrowerId) {
    return _data.deals.any((LoanDeal deal) => deal.borrowerId == borrowerId);
  }

  double totalPaidForDeal(String dealId) {
    double total = 0;
    for (final PaymentRecord payment in _data.payments) {
      if (payment.dealId == dealId) {
        total += payment.amount;
      }
    }
    return total;
  }

  double remainingBalanceForDeal(LoanDeal deal) {
    return max(0, deal.totalDue - totalPaidForDeal(deal.id));
  }

  int daysUntilDue(LoanDeal deal) {
    final DateTime today = _dateOnly(_now);
    final DateTime dueDate = _dateOnly(deal.dueDate);
    return dueDate.difference(today).inDays;
  }

  LoanDealStatus statusForDeal(LoanDeal deal) {
    if (deal.isClosed) {
      return LoanDealStatus.closed;
    }

    if (deal.dueDate.isBefore(_now)) {
      return LoanDealStatus.overdue;
    }
    final int difference = daysUntilDue(deal);
    if (difference == 0) {
      return LoanDealStatus.dueToday;
    }
    if (deal.dueDate.difference(_now) <= const Duration(days: 3)) {
      return LoanDealStatus.dueSoon;
    }
    return LoanDealStatus.tracking;
  }

  Future<void> addBorrower({
    required String name,
    required String phoneNumber,
    required CreditLevel creditLevel,
  }) async {
    final DateTime timestamp = DateTime.now();
    final Borrower borrower = Borrower(
      id: _uuid.v4(),
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      creditLevel: creditLevel,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final List<Borrower> borrowers = <Borrower>[..._data.borrowers, borrower];

    await _commit(
      _data.copyWith(borrowers: borrowers),
      now: timestamp,
      triggerImmediateSync: true,
    );
  }

  Future<void> updateBorrower({
    required Borrower borrower,
    required String name,
    required String phoneNumber,
    required CreditLevel creditLevel,
  }) async {
    final DateTime timestamp = DateTime.now();
    final List<Borrower> borrowers = _data.borrowers
        .map(
          (Borrower current) => current.id == borrower.id
              ? current.copyWith(
                  name: name.trim(),
                  phoneNumber: phoneNumber.trim(),
                  creditLevel: creditLevel,
                  updatedAt: timestamp,
                )
              : current,
        )
        .toList();

    await _commit(
      _data.copyWith(borrowers: borrowers),
      now: timestamp,
      triggerImmediateSync: true,
    );
  }

  Future<void> deleteBorrower({required Borrower borrower}) async {
    if (borrowerHasLinkedDeals(borrower.id)) {
      throw ArgumentError(
        'Borrowers with linked deals cannot be deleted. Remove their linked deals first.',
      );
    }

    final DateTime timestamp = DateTime.now();
    final List<Borrower> borrowers = _data.borrowers
        .where((Borrower current) => current.id != borrower.id)
        .toList();

    await _commit(
      _data.copyWith(borrowers: borrowers),
      now: timestamp,
      triggerImmediateSync: true,
    );
  }

  Future<void> createDeal({
    required String borrowerId,
    required String dealType,
    required double principal,
    required double interestRatePercent,
    required DateTime dueDate,
  }) async {
    final DateTime timestamp = DateTime.now();
    final LoanDeal deal = LoanDeal(
      id: _uuid.v4(),
      borrowerId: borrowerId,
      dealType: dealType.trim(),
      principal: principal,
      interestRatePercent: interestRatePercent,
      dueDate: dueDate,
      createdAt: timestamp,
      updatedAt: timestamp,
    );

    final DealEvent event = DealEvent(
      id: _uuid.v4(),
      dealId: deal.id,
      type: DealEventType.created,
      createdAt: timestamp,
      description:
          'Deal opened for ${deal.dealType} with total due ${deal.totalDue.toStringAsFixed(2)}.',
    );

    await _commit(
      _data.copyWith(
        deals: <LoanDeal>[..._data.deals, deal],
        events: <DealEvent>[..._data.events, event],
      ),
      now: timestamp,
      triggerImmediateSync: true,
    );
  }

  Future<void> updateDeal({
    required LoanDeal deal,
    required String borrowerId,
    required String dealType,
    required double principal,
    required double interestRatePercent,
    required DateTime dueDate,
  }) async {
    if (deal.isClosed) {
      throw ArgumentError('Closed deals must be reopened before editing.');
    }

    final DateTime timestamp = DateTime.now();
    final LoanDeal updatedDeal = deal.copyWith(
      borrowerId: borrowerId,
      dealType: dealType.trim(),
      principal: principal,
      interestRatePercent: interestRatePercent,
      dueDate: dueDate,
      updatedAt: timestamp,
    );
    final double totalPaid = totalPaidForDeal(deal.id);
    if (updatedDeal.totalDue + 0.001 < totalPaid) {
      throw ArgumentError(
        'Updated total due cannot be lower than the amount already paid.',
      );
    }

    final List<LoanDeal> deals = _data.deals
        .map(
          (LoanDeal current) => current.id == deal.id ? updatedDeal : current,
        )
        .toList();
    final DealEvent event = DealEvent(
      id: _uuid.v4(),
      dealId: deal.id,
      type: DealEventType.updated,
      createdAt: timestamp,
      description:
          'Deal updated to ${updatedDeal.dealType} with total due ${updatedDeal.totalDue.toStringAsFixed(2)}.',
    );

    await _commit(
      _data.copyWith(deals: deals, events: <DealEvent>[..._data.events, event]),
      now: timestamp,
      triggerImmediateSync: true,
    );
  }

  Future<void> addPayment({
    required LoanDeal deal,
    required double amount,
    String? note,
  }) async {
    if (deal.isClosed) {
      throw ArgumentError('Closed deals cannot receive new payments.');
    }

    final double remainingBefore = remainingBalanceForDeal(deal);
    if (amount <= 0 || amount > remainingBefore + 0.001) {
      throw ArgumentError(
        'Payment amount must be greater than 0 and not exceed the remaining balance.',
      );
    }

    final DateTime timestamp = DateTime.now();
    final double remainingAfter = max(0, remainingBefore - amount);
    final PaymentRecord payment = PaymentRecord(
      id: _uuid.v4(),
      dealId: deal.id,
      paidAt: timestamp,
      amount: amount,
      remainingAfterPayment: remainingAfter,
      note: note?.trim().isEmpty ?? true ? null : note?.trim(),
    );

    List<LoanDeal> deals = _data.deals
        .map(
          (LoanDeal current) => current.id == deal.id
              ? current.copyWith(updatedAt: timestamp)
              : current,
        )
        .toList();
    List<DealEvent> events = _data.events;

    if (remainingAfter <= 0.001) {
      deals = deals
          .map(
            (LoanDeal current) => current.id == deal.id
                ? current.copyWith(
                    isClosed: true,
                    closedAt: timestamp,
                    closedReason: 'Automatically closed after full repayment.',
                    updatedAt: timestamp,
                  )
                : current,
          )
          .toList();
      events = <DealEvent>[
        ...events,
        DealEvent(
          id: _uuid.v4(),
          dealId: deal.id,
          type: DealEventType.autoClosed,
          createdAt: timestamp,
          description: 'Deal closed automatically after the balance reached 0.',
        ),
      ];
    }

    await _commit(
      _data.copyWith(
        deals: deals,
        payments: <PaymentRecord>[..._data.payments, payment],
        events: events,
      ),
      now: timestamp,
      triggerImmediateSync: true,
    );
  }

  Future<void> closeDeal({
    required LoanDeal deal,
    required String reason,
  }) async {
    if (deal.isClosed) {
      return;
    }

    final DateTime timestamp = DateTime.now();
    final List<LoanDeal> deals = _data.deals
        .map(
          (LoanDeal current) => current.id == deal.id
              ? current.copyWith(
                  isClosed: true,
                  closedAt: timestamp,
                  closedReason: reason.trim(),
                  updatedAt: timestamp,
                )
              : current,
        )
        .toList();

    final DealEvent event = DealEvent(
      id: _uuid.v4(),
      dealId: deal.id,
      type: DealEventType.manuallyClosed,
      createdAt: timestamp,
      description: reason.trim(),
    );

    await _commit(
      _data.copyWith(deals: deals, events: <DealEvent>[..._data.events, event]),
      now: timestamp,
      triggerImmediateSync: true,
    );
  }

  Future<void> reopenDeal({
    required LoanDeal deal,
    required String reason,
  }) async {
    if (!deal.isClosed) {
      return;
    }

    final DateTime timestamp = DateTime.now();
    final List<LoanDeal> deals = _data.deals
        .map(
          (LoanDeal current) => current.id == deal.id
              ? current.copyWith(
                  isClosed: false,
                  updatedAt: timestamp,
                  clearClosedAt: true,
                  clearClosedReason: true,
                )
              : current,
        )
        .toList();

    final DealEvent event = DealEvent(
      id: _uuid.v4(),
      dealId: deal.id,
      type: DealEventType.reopened,
      createdAt: timestamp,
      description: reason.trim(),
    );

    await _commit(
      _data.copyWith(deals: deals, events: <DealEvent>[..._data.events, event]),
      now: timestamp,
      triggerImmediateSync: true,
    );
  }

  Future<void> attemptSyncNow() async {
    await _attemptSync(isManual: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      _now = DateTime.now();
      notifyListeners();
      unawaited(_attemptScheduledSyncIfDue());
    });
  }

  Future<void> _attemptScheduledSyncIfDue() async {
    if (!_hasUnsyncedChanges ||
        _syncInFlight ||
        _now.isBefore(_data.syncState.nextAttemptAt)) {
      return;
    }

    await _attemptSync();
  }

  Future<void> _attemptStartupSync() async {
    if (_syncService.isConfigured) {
      final DateTime timestamp = DateTime.now();
      final SyncState updatedSync = _data.syncState.copyWith(
        isConfigured: true,
        lastMessage: _data.hasRecords
            ? 'Loaded records from Firebase for this session.'
            : 'Connected to Firebase. No records found yet.',
        nextAttemptAt: timestamp.add(const Duration(minutes: 30)),
      );
      await _commit(_data.copyWith(syncState: updatedSync), now: timestamp);
      return;
    }

    await _attemptScheduledSyncIfDue();
  }

  Future<void> _attemptSync({bool isManual = false}) async {
    if (_syncInFlight) {
      _syncQueued = true;
      _queuedManualSync = _queuedManualSync || isManual;
      return;
    }

    _syncInFlight = true;
    final DateTime timestamp = DateTime.now();

    try {
      final FirebaseSyncResult result = await _syncService.sync(
        _data,
        isManual: isManual,
      );
      final SyncState updatedSync = _data.syncState.copyWith(
        isConfigured: _syncService.isConfigured,
        lastAttemptAt: timestamp,
        lastSuccessAt: result.success
            ? timestamp
            : _data.syncState.lastSuccessAt,
        clearLastSuccessAt:
            !result.success && _data.syncState.lastSuccessAt == null,
        lastMessage: result.message,
        nextAttemptAt: timestamp.add(const Duration(minutes: 30)),
      );
      if (result.success) {
        _hasUnsyncedChanges = false;
      }

      await _commit(_data.copyWith(syncState: updatedSync), now: timestamp);
    } finally {
      _syncInFlight = false;
      if (_syncQueued) {
        final bool queuedManualSync = _queuedManualSync;
        _syncQueued = false;
        _queuedManualSync = false;
        unawaited(_attemptSync(isManual: queuedManualSync));
      }
    }
  }

  Future<void> _commit(
    AppData data, {
    DateTime? now,
    bool triggerImmediateSync = false,
  }) async {
    if (triggerImmediateSync) {
      _hasUnsyncedChanges = true;
    }
    _data = data;
    _now = now ?? DateTime.now();
    notifyListeners();
    await _store.save(_data);
    if (triggerImmediateSync && _syncService.isConfigured) {
      unawaited(_attemptSync());
    }
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static int _severityWeight(LoanDealStatus status) {
    switch (status) {
      case LoanDealStatus.overdue:
        return 0;
      case LoanDealStatus.dueToday:
        return 1;
      case LoanDealStatus.dueSoon:
        return 2;
      case LoanDealStatus.tracking:
      case LoanDealStatus.closed:
        return 3;
    }
  }
}
