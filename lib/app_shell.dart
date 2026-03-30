import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'formatters.dart';
import 'models.dart';
import 'ui_common.dart';
import 'ui_dialogs.dart';

enum AppSection { dashboard, borrowers, deals, closedDeals, notifications }

enum DealsViewFilter { all, attention, dueToday, overdue }

enum ClosedDealsViewFilter { all, recent }

enum AlertsViewFilter { all, dueSoon, dueToday, overdue }

String dealsViewFilterLabel(DealsViewFilter filter) {
  return switch (filter) {
    DealsViewFilter.all => 'ทั้งหมด',
    DealsViewFilter.attention => 'ต้องติดตาม',
    DealsViewFilter.dueToday => 'ครบกำหนดวันนี้',
    DealsViewFilter.overdue => 'ค้างชำระ',
  };
}

String closedDealsViewFilterLabel(ClosedDealsViewFilter filter) {
  return switch (filter) {
    ClosedDealsViewFilter.all => 'ทั้งหมด',
    ClosedDealsViewFilter.recent => 'ล่าสุด 7 วัน',
  };
}

String alertsViewFilterLabel(AlertsViewFilter filter) {
  return switch (filter) {
    AlertsViewFilter.all => 'ทั้งหมด',
    AlertsViewFilter.dueSoon => 'ใกล้ครบกำหนด',
    AlertsViewFilter.dueToday => 'ครบกำหนดวันนี้',
    AlertsViewFilter.overdue => 'ค้างชำระ',
  };
}

class LoanAppShell extends StatefulWidget {
  const LoanAppShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoanAppShell> createState() => _LoanAppShellState();
}

class _LoanAppShellState extends State<LoanAppShell> {
  AppSection _selectedSection = AppSection.dashboard;
  DealsViewFilter _dealsViewFilter = DealsViewFilter.all;
  ClosedDealsViewFilter _closedDealsViewFilter = ClosedDealsViewFilter.all;
  AlertsViewFilter _alertsViewFilter = AlertsViewFilter.all;
  int _dealsViewRequestId = 0;
  int _closedDealsViewRequestId = 0;
  int _alertsViewRequestId = 0;

  void _openSection(AppSection section) {
    if (_selectedSection == section) {
      return;
    }
    setState(() => _selectedSection = section);
  }

  void _openDeals(DealsViewFilter filter) {
    setState(() {
      _selectedSection = AppSection.deals;
      _dealsViewFilter = filter;
      _dealsViewRequestId += 1;
    });
  }

  void _openClosedDeals(ClosedDealsViewFilter filter) {
    setState(() {
      _selectedSection = AppSection.closedDeals;
      _closedDealsViewFilter = filter;
      _closedDealsViewRequestId += 1;
    });
  }

  void _openAlerts(AlertsViewFilter filter) {
    setState(() {
      _selectedSection = AppSection.notifications;
      _alertsViewFilter = filter;
      _alertsViewRequestId += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool useRail = constraints.maxWidth >= 1040;
        final Widget body = AnimatedBuilder(
          animation: widget.controller,
          builder: (BuildContext context, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey<AppSection>(_selectedSection),
              child: _buildSection(),
            ),
          ),
        );

        if (useRail) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: _selectedSection.index,
                  extended: constraints.maxWidth >= 1320,
                  labelType: NavigationRailLabelType.none,
                  minExtendedWidth: 220,
                  destinations: _destinations,
                  onDestinationSelected: (int index) => setState(
                    () => _selectedSection = AppSection.values[index],
                  ),
                  leading: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nicha Loan Desk',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Single-user loan control',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedSection.index,
            onDestinationSelected: (int index) =>
                setState(() => _selectedSection = AppSection.values[index]),
            destinations: _destinations
                .map(
                  (NavigationRailDestination destination) =>
                      NavigationDestination(
                        icon: destination.icon,
                        selectedIcon: destination.selectedIcon,
                        label: (destination.label as Text).data ?? '',
                      ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  Widget _buildSection() {
    return switch (_selectedSection) {
      AppSection.dashboard => DashboardView(
        key: const ValueKey<String>('section-dashboard'),
        controller: widget.controller,
        onOpenSection: _openSection,
        onOpenDeals: _openDeals,
        onOpenClosedDeals: _openClosedDeals,
        onOpenAlerts: _openAlerts,
      ),
      AppSection.borrowers => BorrowersView(
        key: const ValueKey<String>('section-borrowers'),
        controller: widget.controller,
      ),
      AppSection.deals => DealsView(
        key: const ValueKey<String>('section-deals'),
        controller: widget.controller,
        requestedFilter: _dealsViewFilter,
        requestId: _dealsViewRequestId,
      ),
      AppSection.closedDeals => ClosedDealsView(
        key: const ValueKey<String>('section-closed-deals'),
        controller: widget.controller,
        requestedFilter: _closedDealsViewFilter,
        requestId: _closedDealsViewRequestId,
      ),
      AppSection.notifications => NotificationsView(
        key: const ValueKey<String>('section-notifications'),
        controller: widget.controller,
        requestedFilter: _alertsViewFilter,
        requestId: _alertsViewRequestId,
      ),
    };
  }

  List<NavigationRailDestination> get _destinations =>
      const <NavigationRailDestination>[
        NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard_rounded),
          label: Text('Dashboard'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.people_outline_rounded),
          selectedIcon: Icon(Icons.people_rounded),
          label: Text('Borrowers'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: Text('Active Deals'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: Text('Closed Deals'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.notifications_none_rounded),
          selectedIcon: Icon(Icons.notifications_active_rounded),
          label: Text('Alerts'),
        ),
      ];
}

class DashboardView extends StatelessWidget {
  const DashboardView({
    super.key,
    required this.controller,
    required this.onOpenSection,
    required this.onOpenDeals,
    required this.onOpenClosedDeals,
    required this.onOpenAlerts,
  });
  final AppController controller;
  final ValueChanged<AppSection> onOpenSection;
  final ValueChanged<DealsViewFilter> onOpenDeals;
  final ValueChanged<ClosedDealsViewFilter> onOpenClosedDeals;
  final ValueChanged<AlertsViewFilter> onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final DashboardStats stats = controller.dashboardStats;
    final List<LoanDeal> upcomingDeals = controller
        .activeDeals()
        .take(4)
        .toList();
    final List<NotificationItem> alerts = controller
        .notifications()
        .take(3)
        .toList();
    return PageFrame(
      title: 'สวัสดีคุณนิชา',
      subtitle: 'ดูยอดคงเหลือ รายการใกล้กำหนด และประวัติปิดยอดจากจุดเดียว',
      actions: <Widget>[
        FilledButton.tonalIcon(
          onPressed: () async => controller.attemptSyncNow(),
          icon: const Icon(Icons.sync_rounded),
          label: const Text('Sync now'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          CompactHeroCard(syncState: controller.syncState),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              MetricCard(
                title: 'ผู้กู้ที่ยัง active',
                value: '${stats.activeBorrowers}',
                caption: 'นับจากผู้กู้ที่ยังมีดีลเปิดอยู่',
                icon: Icons.people_alt_rounded,
                tapTargetKey: const ValueKey<String>(
                  'dashboard-active-borrowers-card',
                ),
                actionLabel: 'ดูรายชื่อ',
                onTap: () => onOpenSection(AppSection.borrowers),
              ),
              MetricCard(
                title: 'ยอดคงค้างรวม',
                value: formatMoney(stats.totalOutstanding),
                caption: 'รวมยอดคงเหลือของดีลที่ยังไม่ปิด',
                icon: Icons.paid_rounded,
                tapTargetKey: const ValueKey<String>(
                  'dashboard-open-balance-card',
                ),
                actionLabel: 'ดูดีล',
                onTap: () => onOpenDeals(DealsViewFilter.all),
              ),
              MetricCard(
                title: 'ดีลที่ปิดแล้ว',
                value: '${stats.closedDeals}',
                caption: 'สะสมทั้งหมดและเปิดกลับได้ภายหลัง',
                icon: Icons.assignment_turned_in_rounded,
                tapTargetKey: const ValueKey<String>(
                  'dashboard-closed-deals-card',
                ),
                actionLabel: 'ดูประวัติ',
                onTap: () => onOpenClosedDeals(ClosedDealsViewFilter.recent),
              ),
              MetricCard(
                title: 'ดีลที่กำลังติดตาม',
                value: '${stats.activeDeals}',
                caption: 'รวมดีลที่ยังไม่ปิดทั้งหมด',
                icon: Icons.track_changes_rounded,
                tapTargetKey: const ValueKey<String>(
                  'dashboard-active-deals-card',
                ),
                actionLabel: 'ดูรายการติดตาม',
                onTap: () => onOpenDeals(DealsViewFilter.attention),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'รายการกำหนดชำระถัดไป',
            subtitle: 'เรียงจากดีลที่ถึงกำหนดเร็วที่สุดลงไป',
            headerAction: TextButton.icon(
              key: const ValueKey<String>('dashboard-open-deals-button'),
              onPressed: () => onOpenDeals(DealsViewFilter.attention),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('ดูรายการติดตาม'),
            ),
            child: upcomingDeals.isEmpty
                ? const EmptyState(
                    title: 'ยังไม่มีดีลที่เปิดอยู่',
                    message:
                        'เพิ่มผู้กู้และสร้างดีลแรกเพื่อให้ Dashboard เริ่มสรุปงานให้',
                  )
                : Column(
                    children: upcomingDeals.map((LoanDeal deal) {
                      final Borrower? borrower = controller.borrowerById(
                        deal.borrowerId,
                      );
                      return DealListTile(
                        borrowerName: borrower?.name ?? 'Unknown borrower',
                        deal: deal,
                        remaining: controller.remainingBalanceForDeal(deal),
                        daysUntilDue: controller.daysUntilDue(deal),
                        status: controller.statusForDeal(deal),
                        onTap: () =>
                            showDealDetailDialog(context, controller, deal),
                      );
                    }).toList(),
                  ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'การแจ้งเตือนภายในแอป',
            subtitle: 'รายการใกล้ครบกำหนด ครบกำหนดวันนี้ และค้างชำระ',
            headerAction: TextButton.icon(
              key: const ValueKey<String>('dashboard-open-alerts-button'),
              onPressed: () => onOpenAlerts(AlertsViewFilter.all),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('ดูแจ้งเตือนทั้งหมด'),
            ),
            child: alerts.isEmpty
                ? const EmptyState(
                    title: 'ยังไม่มีแจ้งเตือน',
                    message:
                        'เมื่อมีดีลใกล้ครบกำหนดหรือค้างชำระ ระบบจะแสดงที่นี่',
                  )
                : Column(
                    children: alerts
                        .map(
                          (NotificationItem item) => NotificationListTile(
                            item: item,
                            onTap: () => showDealDetailDialog(
                              context,
                              controller,
                              controller.dealById(item.dealId)!,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class BorrowersView extends StatefulWidget {
  const BorrowersView({super.key, required this.controller});
  final AppController controller;

  @override
  State<BorrowersView> createState() => _BorrowersViewState();
}

class _BorrowersViewState extends State<BorrowersView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<Borrower> items = widget.controller.borrowers(query: _query);
    return PageFrame(
      title: 'ทะเบียนผู้กู้',
      subtitle:
          'เพิ่ม แก้ไข ค้นหา ดูรายละเอียด และตั้งระดับเครดิตของผู้กู้แต่ละคน',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: () => _openBorrowerForm(),
          icon: const Icon(Icons.person_add_alt_1_rounded),
          label: const Text('เพิ่มผู้กู้'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SearchField(
            hintText: 'ค้นหาจากชื่อ เบอร์โทร หรือรหัสผู้กู้',
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const SectionCard(
              title: 'ยังไม่มีผู้กู้',
              child: EmptyState(
                title: 'สร้างทะเบียนผู้กู้ก่อนเริ่มปล่อยกู้',
                message: 'ข้อมูลขั้นต่ำของผู้กู้คือชื่อและเบอร์โทรศัพท์',
              ),
            )
          else
            Column(
              children: items
                  .map(
                    (Borrower borrower) => BorrowerCard(
                      borrower: borrower,
                      activeDeals: widget.controller.activeDealCountForBorrower(
                        borrower.id,
                      ),
                      outstanding: widget.controller.outstandingForBorrower(
                        borrower.id,
                      ),
                      onView: () => showBorrowerDetailDialog(
                        context,
                        widget.controller,
                        borrower,
                      ),
                      onEdit: () => _openBorrowerForm(borrower: borrower),
                      onCreateDeal: () =>
                          _openDealForm(borrowerId: borrower.id),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Future<void> _openBorrowerForm({Borrower? borrower}) async {
    final BorrowerDraft? draft = await showDialog<BorrowerDraft>(
      context: context,
      builder: (BuildContext context) =>
          BorrowerFormDialog(initialBorrower: borrower),
    );
    if (draft == null) return;
    if (borrower == null) {
      await widget.controller.addBorrower(
        name: draft.name,
        phoneNumber: draft.phoneNumber,
        creditLevel: draft.creditLevel,
      );
    } else {
      await widget.controller.updateBorrower(
        borrower: borrower,
        name: draft.name,
        phoneNumber: draft.phoneNumber,
        creditLevel: draft.creditLevel,
      );
    }
  }

  Future<void> _openDealForm({String? borrowerId}) async {
    if (widget.controller.borrowers().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ต้องมีผู้กู้ในระบบก่อนจึงจะสร้างดีลได้')),
      );
      return;
    }
    final DealDraft? draft = await showDialog<DealDraft>(
      context: context,
      builder: (BuildContext context) => DealFormDialog(
        controller: widget.controller,
        initialBorrowerId: borrowerId,
      ),
    );
    if (draft == null) return;
    await widget.controller.createDeal(
      borrowerId: draft.borrowerId,
      dealType: draft.dealType,
      principal: draft.principal,
      interestRatePercent: draft.interestRatePercent,
      dueDate: draft.dueDate,
    );
  }
}

class DealsView extends StatefulWidget {
  const DealsView({
    super.key,
    required this.controller,
    required this.requestedFilter,
    required this.requestId,
  });
  final AppController controller;
  final DealsViewFilter requestedFilter;
  final int requestId;

  @override
  State<DealsView> createState() => _DealsViewState();
}

class _DealsViewState extends State<DealsView> {
  String _query = '';
  late final TextEditingController _searchController;
  late DealsViewFilter _filter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filter = widget.requestedFilter;
  }

  @override
  void didUpdateWidget(covariant DealsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestId == oldWidget.requestId) {
      return;
    }
    setState(() {
      _filter = widget.requestedFilter;
      _query = '';
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<LoanDeal> items = widget.controller
        .activeDeals(query: _query)
        .where(_matchesFilter)
        .toList();
    return PageFrame(
      title: 'ดีลที่กำลังติดตาม',
      subtitle: 'ดูดีลเปิดอยู่ รับชำระ และโฟกัสรายการที่ต้องติดตามได้เร็วขึ้น',
      actions: <Widget>[
        FilledButton.icon(
          onPressed: _openDealForm,
          icon: const Icon(Icons.add_card_rounded),
          label: const Text('สร้างดีล'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SearchField(
            controller: _searchController,
            hintText: 'ค้นหาจากชื่อผู้กู้ ประเภทดีล รหัสดีล หรือเบอร์โทร',
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: DealsViewFilter.values.map((DealsViewFilter filter) {
              return ChoiceChip(
                key: ValueKey<String>('deals-filter-${filter.name}'),
                label: Text(dealsViewFilterLabel(filter)),
                selected: _filter == filter,
                onSelected: (bool selected) {
                  if (!selected) return;
                  setState(() => _filter = filter);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            SectionCard(
              title: _filter == DealsViewFilter.all
                  ? 'ยังไม่มีดีล active'
                  : 'ยังไม่มีดีลในตัวกรองนี้',
              child: EmptyState(
                title: _filter == DealsViewFilter.all
                    ? 'สร้างดีลปล่อยกู้รายการแรก'
                    : 'ไม่พบรายการตามตัวกรองที่เลือก',
                message: _filter == DealsViewFilter.all
                    ? 'ทุกดีลจะผูกกับผู้กู้หนึ่งคน มีดอกเบี้ยแบบคิดครั้งเดียว และรองรับการชำระหลายงวด'
                    : 'ลองเปลี่ยนตัวกรอง หรือค้นหาด้วยชื่อผู้กู้และประเภทดีลเพิ่มเติม',
              ),
            )
          else
            Column(
              children: items.map((LoanDeal deal) {
                final Borrower? borrower = widget.controller.borrowerById(
                  deal.borrowerId,
                );
                return DealCard(
                  borrowerName: borrower?.name ?? 'Unknown borrower',
                  borrowerPhone: borrower?.phoneNumber ?? '-',
                  deal: deal,
                  remaining: widget.controller.remainingBalanceForDeal(deal),
                  totalPaid: widget.controller.totalPaidForDeal(deal.id),
                  daysUntilDue: widget.controller.daysUntilDue(deal),
                  status: widget.controller.statusForDeal(deal),
                  onView: () =>
                      showDealDetailDialog(context, widget.controller, deal),
                  onPayment: () => _openPaymentForm(deal),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  bool _matchesFilter(LoanDeal deal) {
    final LoanDealStatus status = widget.controller.statusForDeal(deal);
    return switch (_filter) {
      DealsViewFilter.all => true,
      DealsViewFilter.attention =>
        status == LoanDealStatus.dueSoon ||
            status == LoanDealStatus.dueToday ||
            status == LoanDealStatus.overdue,
      DealsViewFilter.dueToday => status == LoanDealStatus.dueToday,
      DealsViewFilter.overdue => status == LoanDealStatus.overdue,
    };
  }

  Future<void> _openDealForm() async {
    if (widget.controller.borrowers().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มผู้กู้ก่อนสร้างดีล')),
      );
      return;
    }
    final DealDraft? draft = await showDialog<DealDraft>(
      context: context,
      builder: (BuildContext context) =>
          DealFormDialog(controller: widget.controller),
    );
    if (draft == null) return;
    await widget.controller.createDeal(
      borrowerId: draft.borrowerId,
      dealType: draft.dealType,
      principal: draft.principal,
      interestRatePercent: draft.interestRatePercent,
      dueDate: draft.dueDate,
    );
  }

  Future<void> _openPaymentForm(LoanDeal deal) async {
    final PaymentDraft? draft = await showDialog<PaymentDraft>(
      context: context,
      builder: (BuildContext context) => PaymentFormDialog(
        remainingBalance: widget.controller.remainingBalanceForDeal(deal),
      ),
    );
    if (draft == null) return;
    try {
      await widget.controller.addPayment(
        deal: deal,
        amount: draft.amount,
        note: draft.note,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกรับชำระเรียบร้อย')));
    } on ArgumentError catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
  }
}

class ClosedDealsView extends StatefulWidget {
  const ClosedDealsView({
    super.key,
    required this.controller,
    required this.requestedFilter,
    required this.requestId,
  });
  final AppController controller;
  final ClosedDealsViewFilter requestedFilter;
  final int requestId;

  @override
  State<ClosedDealsView> createState() => _ClosedDealsViewState();
}

class _ClosedDealsViewState extends State<ClosedDealsView> {
  String _query = '';
  late final TextEditingController _searchController;
  late ClosedDealsViewFilter _filter;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filter = widget.requestedFilter;
  }

  @override
  void didUpdateWidget(covariant ClosedDealsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestId == oldWidget.requestId) {
      return;
    }
    setState(() {
      _filter = widget.requestedFilter;
      _query = '';
      _searchController.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<LoanDeal> items = widget.controller
        .closedDeals(query: _query)
        .where(_matchesFilter)
        .toList();
    return PageFrame(
      title: 'ดีลที่ปิดแล้ว',
      subtitle: 'ดูประวัติปิดยอดย้อนหลัง และแยกรายการที่เพิ่งปิดล่าสุดได้ทันที',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SearchField(
            controller: _searchController,
            hintText: 'ค้นหาจากชื่อผู้กู้ ประเภทดีล หรือรหัสดีล',
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ClosedDealsViewFilter.values.map((
              ClosedDealsViewFilter filter,
            ) {
              return ChoiceChip(
                key: ValueKey<String>('closed-deals-filter-${filter.name}'),
                label: Text(closedDealsViewFilterLabel(filter)),
                selected: _filter == filter,
                onSelected: (bool selected) {
                  if (!selected) return;
                  setState(() => _filter = filter);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            SectionCard(
              title: _filter == ClosedDealsViewFilter.all
                  ? 'ยังไม่มีดีลที่ปิดแล้ว'
                  : 'ยังไม่มีดีลที่ปิดล่าสุด',
              child: EmptyState(
                title: _filter == ClosedDealsViewFilter.all
                    ? 'ประวัติดีลที่ปิดแล้วยังว่างอยู่'
                    : 'ไม่พบดีลที่ปิดใน 7 วันล่าสุด',
                message: _filter == ClosedDealsViewFilter.all
                    ? 'เมื่อมีดีลถูกปิด ระบบจะเก็บไว้ที่หน้านี้พร้อมรองรับการ reopen'
                    : 'ลองกลับไปดูทั้งหมด หรือรอให้มีรายการปิดยอดใหม่เข้ามา',
              ),
            )
          else
            Column(
              children: items.map((LoanDeal deal) {
                final Borrower? borrower = widget.controller.borrowerById(
                  deal.borrowerId,
                );
                return DealCard(
                  borrowerName: borrower?.name ?? 'Unknown borrower',
                  borrowerPhone: borrower?.phoneNumber ?? '-',
                  deal: deal,
                  remaining: widget.controller.remainingBalanceForDeal(deal),
                  totalPaid: widget.controller.totalPaidForDeal(deal.id),
                  daysUntilDue: widget.controller.daysUntilDue(deal),
                  status: widget.controller.statusForDeal(deal),
                  onView: () =>
                      showDealDetailDialog(context, widget.controller, deal),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  bool _matchesFilter(LoanDeal deal) {
    if (_filter == ClosedDealsViewFilter.all) {
      return true;
    }
    final DateTime closedAt = deal.closedAt ?? deal.updatedAt;
    final DateTime threshold = widget.controller.now.subtract(
      const Duration(days: 7),
    );
    return !closedAt.isBefore(threshold);
  }
}

class NotificationsView extends StatefulWidget {
  const NotificationsView({
    super.key,
    required this.controller,
    required this.requestedFilter,
    required this.requestId,
  });
  final AppController controller;

  final AlertsViewFilter requestedFilter;
  final int requestId;

  @override
  State<NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<NotificationsView> {
  late AlertsViewFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.requestedFilter;
  }

  @override
  void didUpdateWidget(covariant NotificationsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestId == oldWidget.requestId) {
      return;
    }
    setState(() => _filter = widget.requestedFilter);
  }

  @override
  Widget build(BuildContext context) {
    final List<NotificationItem> items = widget.controller
        .notifications()
        .where(_matchesFilter)
        .toList();
    return PageFrame(
      title: 'การแจ้งเตือน',
      subtitle: 'รวมรายการใกล้ครบกำหนด ครบกำหนดวันนี้ และค้างชำระในมุมมองเดียว',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AlertsViewFilter.values.map((AlertsViewFilter filter) {
              return ChoiceChip(
                key: ValueKey<String>('alerts-filter-${filter.name}'),
                label: Text(alertsViewFilterLabel(filter)),
                selected: _filter == filter,
                onSelected: (bool selected) {
                  if (!selected) return;
                  setState(() => _filter = filter);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            SectionCard(
              title: _filter == AlertsViewFilter.all
                  ? 'ไม่มีแจ้งเตือนตอนนี้'
                  : 'ไม่มีรายการในตัวกรองนี้',
              child: EmptyState(
                title: _filter == AlertsViewFilter.all
                    ? 'งานติดตามยังอยู่ในเกณฑ์ปกติ'
                    : 'ไม่พบแจ้งเตือนตามตัวกรองที่เลือก',
                message: _filter == AlertsViewFilter.all
                    ? 'เมื่อมีดีลเหลือไม่เกิน 3 วันถึงกำหนด หรือมีสถานะค้างชำระ ระบบจะแสดงที่นี่'
                    : 'ลองเปลี่ยนตัวกรองเพื่อดูรายการครบกำหนดหรือค้างชำระประเภทอื่น',
              ),
            )
          else
            Column(
              children: items
                  .map(
                    (NotificationItem item) => NotificationListTile(
                      item: item,
                      onTap: () => showDealDetailDialog(
                        context,
                        widget.controller,
                        widget.controller.dealById(item.dealId)!,
                      ),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  bool _matchesFilter(NotificationItem item) {
    return switch (_filter) {
      AlertsViewFilter.all => true,
      AlertsViewFilter.dueSoon => item.status == LoanDealStatus.dueSoon,
      AlertsViewFilter.dueToday => item.status == LoanDealStatus.dueToday,
      AlertsViewFilter.overdue => item.status == LoanDealStatus.overdue,
    };
  }
}
