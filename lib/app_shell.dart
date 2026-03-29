import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'formatters.dart';
import 'models.dart';
import 'ui_common.dart';
import 'ui_dialogs.dart';

enum AppSection { dashboard, borrowers, deals, closedDeals, notifications }

class LoanAppShell extends StatefulWidget {
  const LoanAppShell({super.key, required this.controller});
  final AppController controller;

  @override
  State<LoanAppShell> createState() => _LoanAppShellState();
}

class _LoanAppShellState extends State<LoanAppShell> {
  AppSection _selectedSection = AppSection.dashboard;

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
      AppSection.dashboard => DashboardView(controller: widget.controller),
      AppSection.borrowers => BorrowersView(controller: widget.controller),
      AppSection.deals => DealsView(controller: widget.controller),
      AppSection.closedDeals => ClosedDealsView(controller: widget.controller),
      AppSection.notifications => NotificationsView(
        controller: widget.controller,
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
  const DashboardView({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final DashboardStats stats = controller.dashboardStats;
    final List<LoanDeal> upcomingDeals = controller
        .activeDeals()
        .take(6)
        .toList();
    final List<NotificationItem> alerts = controller
        .notifications()
        .take(4)
        .toList();
    return PageFrame(
      title: 'สวัสดีคุณนิชา',
      subtitle:
          'จัดการผู้กู้ ดีล การชำระ และดีลที่ปิดแล้วจากจุดเดียว แอปจะถือว่า "ใกล้ครบกำหนด" เมื่อเหลือไม่เกิน 3 วัน',
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
          HeroCard(syncState: controller.syncState),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: <Widget>[
              MetricCard(
                title: 'ผู้กู้ที่ยัง active',
                value: '${stats.activeBorrowers}',
                caption: 'นับจากผู้กู้ที่ยังมีดีลเปิดอยู่',
                icon: Icons.people_alt_rounded,
              ),
              MetricCard(
                title: 'ยอดคงค้างรวม',
                value: formatMoney(stats.totalOutstanding),
                caption: 'รวมยอดคงเหลือของดีลที่ยังไม่ปิด',
                icon: Icons.paid_rounded,
              ),
              MetricCard(
                title: 'ดีลที่ปิดแล้ว',
                value: '${stats.closedDeals}',
                caption: 'สะสมทั้งหมดและเปิดกลับได้ภายหลัง',
                icon: Icons.assignment_turned_in_rounded,
              ),
              MetricCard(
                title: 'ดีลที่กำลังติดตาม',
                value: '${stats.activeDeals}',
                caption: 'รวมดีลที่ยังไม่ปิดทั้งหมด',
                icon: Icons.track_changes_rounded,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SectionCard(
            title: 'รายการกำหนดชำระถัดไป',
            subtitle: 'เรียงจากดีลที่ถึงกำหนดเร็วที่สุดลงไป',
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
          const SizedBox(height: 24),
          SectionCard(
            title: 'การแจ้งเตือนภายในแอป',
            subtitle: 'รายการใกล้ครบกำหนด ครบกำหนดวันนี้ และค้างชำระ',
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
  const DealsView({super.key, required this.controller});
  final AppController controller;

  @override
  State<DealsView> createState() => _DealsViewState();
}

class _DealsViewState extends State<DealsView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<LoanDeal> items = widget.controller.activeDeals(query: _query);
    return PageFrame(
      title: 'ดีลที่กำลังติดตาม',
      subtitle:
          'สร้างดีลใหม่ ดูสถานะคงเหลือ รับชำระหลายงวด และเปิดรายละเอียดดีลย้อนหลัง',
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
            hintText: 'ค้นหาจากชื่อผู้กู้ ประเภทดีล รหัสดีล หรือเบอร์โทร',
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const SectionCard(
              title: 'ยังไม่มีดีล active',
              child: EmptyState(
                title: 'สร้างดีลปล่อยกู้รายการแรก',
                message:
                    'ทุกดีลจะผูกกับผู้กู้หนึ่งคน มีดอกเบี้ยแบบคิดครั้งเดียว และรองรับการชำระหลายงวด',
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
  const ClosedDealsView({super.key, required this.controller});
  final AppController controller;

  @override
  State<ClosedDealsView> createState() => _ClosedDealsViewState();
}

class _ClosedDealsViewState extends State<ClosedDealsView> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<LoanDeal> items = widget.controller.closedDeals(query: _query);
    return PageFrame(
      title: 'ดีลที่ปิดแล้ว',
      subtitle:
          'ดูประวัติดีลที่ปิดแล้วทั้งหมด และเปิดกลับมาติดตามใหม่โดยไม่สร้างสัญญาใหม่',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SearchField(
            hintText: 'ค้นหาจากชื่อผู้กู้ ประเภทดีล หรือรหัสดีล',
            onChanged: (String value) => setState(() => _query = value),
          ),
          const SizedBox(height: 20),
          if (items.isEmpty)
            const SectionCard(
              title: 'ยังไม่มีดีลที่ปิดแล้ว',
              child: EmptyState(
                title: 'ประวัติดีลที่ปิดแล้วยังว่างอยู่',
                message:
                    'เมื่อมีดีลถูกปิด ระบบจะเก็บไว้ที่หน้านี้พร้อมรองรับการ reopen',
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
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key, required this.controller});
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final List<NotificationItem> items = controller.notifications();
    return PageFrame(
      title: 'การแจ้งเตือน',
      subtitle:
          'รายการดีลใกล้ครบกำหนด ครบกำหนดวันนี้ และค้างชำระ พร้อมลิงก์ไปยังหน้ารายละเอียดดีล',
      child: items.isEmpty
          ? const SectionCard(
              title: 'ไม่มีแจ้งเตือนตอนนี้',
              child: EmptyState(
                title: 'งานติดตามยังอยู่ในเกณฑ์ปกติ',
                message:
                    'เมื่อมีดีลเหลือไม่เกิน 3 วันถึงกำหนด หรือมีสถานะค้างชำระ ระบบจะแสดงที่นี่',
              ),
            )
          : Column(
              children: items
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
    );
  }
}
