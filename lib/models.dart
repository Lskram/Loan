import 'dart:convert';

enum CreditLevel { good, medium, risky }

enum DealEventType { created, manuallyClosed, autoClosed, reopened }

enum LoanDealStatus { tracking, dueSoon, dueToday, overdue, closed }

class Borrower {
  const Borrower({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.creditLevel,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final CreditLevel creditLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  Borrower copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    CreditLevel? creditLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Borrower(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      creditLevel: creditLevel ?? this.creditLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'creditLevel': creditLevel.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Borrower.fromJson(Map<String, dynamic> json) {
    return Borrower(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      creditLevel: CreditLevel.values.byName(json['creditLevel'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class LoanDeal {
  const LoanDeal({
    required this.id,
    required this.borrowerId,
    required this.dealType,
    required this.principal,
    required this.interestRatePercent,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.isClosed = false,
    this.closedAt,
    this.closedReason,
  });

  final String id;
  final String borrowerId;
  final String dealType;
  final double principal;
  final double interestRatePercent;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isClosed;
  final DateTime? closedAt;
  final String? closedReason;

  double get interestAmount => principal * (interestRatePercent / 100);
  double get totalDue => principal + interestAmount;

  LoanDeal copyWith({
    String? id,
    String? borrowerId,
    String? dealType,
    double? principal,
    double? interestRatePercent,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isClosed,
    DateTime? closedAt,
    String? closedReason,
    bool clearClosedAt = false,
    bool clearClosedReason = false,
  }) {
    return LoanDeal(
      id: id ?? this.id,
      borrowerId: borrowerId ?? this.borrowerId,
      dealType: dealType ?? this.dealType,
      principal: principal ?? this.principal,
      interestRatePercent: interestRatePercent ?? this.interestRatePercent,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isClosed: isClosed ?? this.isClosed,
      closedAt: clearClosedAt ? null : closedAt ?? this.closedAt,
      closedReason: clearClosedReason
          ? null
          : closedReason ?? this.closedReason,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'borrowerId': borrowerId,
      'dealType': dealType,
      'principal': principal,
      'interestRatePercent': interestRatePercent,
      'dueDate': dueDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isClosed': isClosed,
      'closedAt': closedAt?.toIso8601String(),
      'closedReason': closedReason,
    };
  }

  factory LoanDeal.fromJson(Map<String, dynamic> json) {
    return LoanDeal(
      id: json['id'] as String,
      borrowerId: json['borrowerId'] as String,
      dealType: json['dealType'] as String,
      principal: (json['principal'] as num).toDouble(),
      interestRatePercent: (json['interestRatePercent'] as num).toDouble(),
      dueDate: DateTime.parse(json['dueDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isClosed: json['isClosed'] as bool? ?? false,
      closedAt: json['closedAt'] == null
          ? null
          : DateTime.parse(json['closedAt'] as String),
      closedReason: json['closedReason'] as String?,
    );
  }
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.dealId,
    required this.paidAt,
    required this.amount,
    required this.remainingAfterPayment,
    this.note,
  });

  final String id;
  final String dealId;
  final DateTime paidAt;
  final double amount;
  final double remainingAfterPayment;
  final String? note;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'dealId': dealId,
      'paidAt': paidAt.toIso8601String(),
      'amount': amount,
      'remainingAfterPayment': remainingAfterPayment,
      'note': note,
    };
  }

  factory PaymentRecord.fromJson(Map<String, dynamic> json) {
    return PaymentRecord(
      id: json['id'] as String,
      dealId: json['dealId'] as String,
      paidAt: DateTime.parse(json['paidAt'] as String),
      amount: (json['amount'] as num).toDouble(),
      remainingAfterPayment: (json['remainingAfterPayment'] as num).toDouble(),
      note: json['note'] as String?,
    );
  }
}

class DealEvent {
  const DealEvent({
    required this.id,
    required this.dealId,
    required this.type,
    required this.createdAt,
    required this.description,
  });

  final String id;
  final String dealId;
  final DealEventType type;
  final DateTime createdAt;
  final String description;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'dealId': dealId,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }

  factory DealEvent.fromJson(Map<String, dynamic> json) {
    return DealEvent(
      id: json['id'] as String,
      dealId: json['dealId'] as String,
      type: DealEventType.values.byName(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      description: json['description'] as String,
    );
  }
}

class SyncState {
  const SyncState({
    required this.isConfigured,
    required this.lastAttemptAt,
    required this.lastSuccessAt,
    required this.lastMessage,
    required this.nextAttemptAt,
  });

  final bool isConfigured;
  final DateTime? lastAttemptAt;
  final DateTime? lastSuccessAt;
  final String lastMessage;
  final DateTime nextAttemptAt;

  SyncState copyWith({
    bool? isConfigured,
    DateTime? lastAttemptAt,
    DateTime? lastSuccessAt,
    String? lastMessage,
    DateTime? nextAttemptAt,
    bool clearLastSuccessAt = false,
  }) {
    return SyncState(
      isConfigured: isConfigured ?? this.isConfigured,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
      lastSuccessAt: clearLastSuccessAt
          ? null
          : lastSuccessAt ?? this.lastSuccessAt,
      lastMessage: lastMessage ?? this.lastMessage,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isConfigured': isConfigured,
      'lastAttemptAt': lastAttemptAt?.toIso8601String(),
      'lastSuccessAt': lastSuccessAt?.toIso8601String(),
      'lastMessage': lastMessage,
      'nextAttemptAt': nextAttemptAt.toIso8601String(),
    };
  }

  factory SyncState.initial(DateTime now) {
    return SyncState(
      isConfigured: false,
      lastAttemptAt: null,
      lastSuccessAt: null,
      lastMessage: 'Google Sheets sync is waiting for configuration.',
      nextAttemptAt: now.add(const Duration(minutes: 30)),
    );
  }

  factory SyncState.fromJson(Map<String, dynamic> json) {
    return SyncState(
      isConfigured: json['isConfigured'] as bool? ?? false,
      lastAttemptAt: json['lastAttemptAt'] == null
          ? null
          : DateTime.parse(json['lastAttemptAt'] as String),
      lastSuccessAt: json['lastSuccessAt'] == null
          ? null
          : DateTime.parse(json['lastSuccessAt'] as String),
      lastMessage:
          json['lastMessage'] as String? ??
          'Google Sheets sync is waiting for configuration.',
      nextAttemptAt: json['nextAttemptAt'] == null
          ? DateTime.now().add(const Duration(minutes: 30))
          : DateTime.parse(json['nextAttemptAt'] as String),
    );
  }
}

class AppData {
  const AppData({
    required this.borrowers,
    required this.deals,
    required this.payments,
    required this.events,
    required this.syncState,
  });

  final List<Borrower> borrowers;
  final List<LoanDeal> deals;
  final List<PaymentRecord> payments;
  final List<DealEvent> events;
  final SyncState syncState;

  factory AppData.empty(DateTime now) {
    return AppData(
      borrowers: const <Borrower>[],
      deals: const <LoanDeal>[],
      payments: const <PaymentRecord>[],
      events: const <DealEvent>[],
      syncState: SyncState.initial(now),
    );
  }

  AppData copyWith({
    List<Borrower>? borrowers,
    List<LoanDeal>? deals,
    List<PaymentRecord>? payments,
    List<DealEvent>? events,
    SyncState? syncState,
  }) {
    return AppData(
      borrowers: borrowers ?? this.borrowers,
      deals: deals ?? this.deals,
      payments: payments ?? this.payments,
      events: events ?? this.events,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'borrowers': borrowers.map((borrower) => borrower.toJson()).toList(),
      'deals': deals.map((deal) => deal.toJson()).toList(),
      'payments': payments.map((payment) => payment.toJson()).toList(),
      'events': events.map((event) => event.toJson()).toList(),
      'syncState': syncState.toJson(),
    };
  }

  String toJsonString() => jsonEncode(toJson());

  factory AppData.fromJson(Map<String, dynamic> json) {
    return AppData(
      borrowers: (json['borrowers'] as List<dynamic>? ?? <dynamic>[])
          .map((entry) => Borrower.fromJson(entry as Map<String, dynamic>))
          .toList(),
      deals: (json['deals'] as List<dynamic>? ?? <dynamic>[])
          .map((entry) => LoanDeal.fromJson(entry as Map<String, dynamic>))
          .toList(),
      payments: (json['payments'] as List<dynamic>? ?? <dynamic>[])
          .map((entry) => PaymentRecord.fromJson(entry as Map<String, dynamic>))
          .toList(),
      events: (json['events'] as List<dynamic>? ?? <dynamic>[])
          .map((entry) => DealEvent.fromJson(entry as Map<String, dynamic>))
          .toList(),
      syncState: json['syncState'] == null
          ? SyncState.initial(DateTime.now())
          : SyncState.fromJson(json['syncState'] as Map<String, dynamic>),
    );
  }
}

class DashboardStats {
  const DashboardStats({
    required this.activeBorrowers,
    required this.totalOutstanding,
    required this.closedDeals,
    required this.activeDeals,
  });

  final int activeBorrowers;
  final double totalOutstanding;
  final int closedDeals;
  final int activeDeals;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.dealId,
    required this.borrowerName,
    required this.dealType,
    required this.dueDate,
    required this.remainingBalance,
    required this.status,
    required this.daysOffset,
  });

  final String id;
  final String dealId;
  final String borrowerName;
  final String dealType;
  final DateTime dueDate;
  final double remainingBalance;
  final LoanDealStatus status;
  final int daysOffset;
}
