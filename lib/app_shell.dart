import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'formatters.dart';
import 'models.dart';
import 'ui_common.dart';
import 'ui_dialogs.dart';

enum AppSection { dashboard, borrowers, deals, closedDeals, notifications }

enum AppWorkspace { loanDesk, lottery }

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
  static const double _workspaceDockRevealOffset = 120;
  static const double _workspaceDockHideOffset = 24;

  AppWorkspace _selectedWorkspace = AppWorkspace.loanDesk;
  AppSection _selectedSection = AppSection.dashboard;
  DealsViewFilter _dealsViewFilter = DealsViewFilter.all;
  ClosedDealsViewFilter _closedDealsViewFilter = ClosedDealsViewFilter.all;
  AlertsViewFilter _alertsViewFilter = AlertsViewFilter.all;
  int _dealsViewRequestId = 0;
  int _closedDealsViewRequestId = 0;
  int _alertsViewRequestId = 0;
  bool _showWorkspaceDock = false;

  void _openSection(AppSection section) {
    if (_selectedSection == section) {
      return;
    }
    setState(() {
      _selectedWorkspace = AppWorkspace.loanDesk;
      _selectedSection = section;
      _showWorkspaceDock = false;
    });
  }

  void _openDeals(DealsViewFilter filter) {
    setState(() {
      _selectedWorkspace = AppWorkspace.loanDesk;
      _selectedSection = AppSection.deals;
      _dealsViewFilter = filter;
      _dealsViewRequestId += 1;
      _showWorkspaceDock = false;
    });
  }

  void _openClosedDeals(ClosedDealsViewFilter filter) {
    setState(() {
      _selectedWorkspace = AppWorkspace.loanDesk;
      _selectedSection = AppSection.closedDeals;
      _closedDealsViewFilter = filter;
      _closedDealsViewRequestId += 1;
      _showWorkspaceDock = false;
    });
  }

  void _openAlerts(AlertsViewFilter filter) {
    setState(() {
      _selectedWorkspace = AppWorkspace.loanDesk;
      _selectedSection = AppSection.notifications;
      _alertsViewFilter = filter;
      _alertsViewRequestId += 1;
      _showWorkspaceDock = false;
    });
  }

  void _selectWorkspace(AppWorkspace workspace) {
    if (_selectedWorkspace == workspace &&
        workspace == AppWorkspace.loanDesk &&
        _selectedSection == AppSection.dashboard) {
      return;
    }
    setState(() {
      _selectedWorkspace = workspace;
      _showWorkspaceDock = false;
      if (workspace == AppWorkspace.loanDesk) {
        _selectedSection = AppSection.dashboard;
      }
    });
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }

    final double offset = notification.metrics.pixels;
    final bool shouldShow = _showWorkspaceDock
        ? offset > _workspaceDockHideOffset
        : offset > _workspaceDockRevealOffset;

    if (shouldShow != _showWorkspaceDock) {
      setState(() => _showWorkspaceDock = shouldShow);
    }
    return false;
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
              key: ValueKey<String>(
                '${_selectedWorkspace.name}-${_selectedSection.name}',
              ),
              child: _buildWorkspaceView(),
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
                  destinations: _railDestinations,
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
                            CupertinoIcons.money_dollar_circle_fill,
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
          extendBody: true,
          body: Stack(
            children: <Widget>[
              NotificationListener<ScrollNotification>(
                onNotification: _handleScrollNotification,
                child: body,
              ),
              if (_showWorkspaceDock)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 18, end: 0),
                    builder:
                        (BuildContext context, double offset, Widget? child) {
                          return Transform.translate(
                            offset: Offset(0, offset),
                            child: child,
                          );
                        },
                    child: _AppWorkspaceDock(
                      key: const ValueKey<String>('app-workspace-dock'),
                      selectedWorkspace: _selectedWorkspace,
                      onSelected: _selectWorkspace,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWorkspaceView() {
    return switch (_selectedWorkspace) {
      AppWorkspace.loanDesk => _buildSection(),
      AppWorkspace.lottery => const LotteryComingSoonView(
        key: ValueKey<String>('section-lottery'),
      ),
    };
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

  List<_AppDestination> get _destinations => const <_AppDestination>[
    _AppDestination(
      icon: Icon(CupertinoIcons.square_grid_2x2),
      selectedIcon: Icon(CupertinoIcons.square_grid_2x2_fill),
      label: 'Dashboard',
    ),
    _AppDestination(
      icon: Icon(CupertinoIcons.person_2),
      selectedIcon: Icon(CupertinoIcons.person_2_fill),
      label: 'Borrowers',
    ),
    _AppDestination(
      icon: Icon(CupertinoIcons.doc_text),
      selectedIcon: Icon(CupertinoIcons.doc_text_fill),
      label: 'Active Deals',
    ),
    _AppDestination(
      icon: Icon(CupertinoIcons.checkmark_seal),
      selectedIcon: Icon(CupertinoIcons.checkmark_seal_fill),
      label: 'Closed Deals',
    ),
    _AppDestination(
      icon: Icon(CupertinoIcons.bell),
      selectedIcon: Icon(CupertinoIcons.bell_fill),
      label: 'Alerts',
    ),
  ];

  List<NavigationRailDestination> get _railDestinations => _destinations
      .map(
        (_AppDestination destination) => NavigationRailDestination(
          icon: destination.icon,
          selectedIcon: destination.selectedIcon,
          label: Text(destination.label),
        ),
      )
      .toList();
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
    final List<LoanDeal> outstandingDeals = controller.activeDeals().toList()
      ..sort((LoanDeal a, LoanDeal b) => b.updatedAt.compareTo(a.updatedAt));
    final List<NotificationItem> alerts = controller
        .notifications()
        .take(3)
        .toList();
    final bool useWalletLayout =
        isAppleVisuals(context) && MediaQuery.sizeOf(context).width < 760;
    if (useWalletLayout) {
      return _DashboardWalletView(
        controller: controller,
        stats: stats,
        outstandingDeals: outstandingDeals.take(3).toList(),
        onOpenSection: onOpenSection,
        onOpenDeals: onOpenDeals,
        onOpenClosedDeals: onOpenClosedDeals,
        onOpenAlerts: onOpenAlerts,
      );
    }
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
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool compact = constraints.maxWidth < 520;
              final double metricWidth = compact
                  ? (constraints.maxWidth - 12) / 2
                  : 220;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  MetricCard(
                    title: 'ผู้กู้ที่ยัง active',
                    value: '${stats.activeBorrowers}',
                    caption: 'นับจากผู้กู้ที่ยังมีดีลเปิดอยู่',
                    width: metricWidth,
                    compact: compact,
                    icon: CupertinoIcons.person_2_fill,
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
                    width: metricWidth,
                    compact: compact,
                    icon: CupertinoIcons.money_dollar_circle_fill,
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
                    width: metricWidth,
                    compact: compact,
                    icon: CupertinoIcons.checkmark_seal_fill,
                    tapTargetKey: const ValueKey<String>(
                      'dashboard-closed-deals-card',
                    ),
                    actionLabel: 'ดูประวัติ',
                    onTap: () =>
                        onOpenClosedDeals(ClosedDealsViewFilter.recent),
                  ),
                  MetricCard(
                    title: 'ดีลที่กำลังติดตาม',
                    value: '${stats.activeDeals}',
                    caption: 'รวมดีลที่ยังไม่ปิดทั้งหมด',
                    width: metricWidth,
                    compact: compact,
                    icon: CupertinoIcons.graph_square_fill,
                    tapTargetKey: const ValueKey<String>(
                      'dashboard-active-deals-card',
                    ),
                    actionLabel: 'ดูรายการติดตาม',
                    onTap: () => onOpenDeals(DealsViewFilter.attention),
                  ),
                ],
              );
            },
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

class _DashboardWalletView extends StatelessWidget {
  const _DashboardWalletView({
    required this.controller,
    required this.stats,
    required this.outstandingDeals,
    required this.onOpenSection,
    required this.onOpenDeals,
    required this.onOpenClosedDeals,
    required this.onOpenAlerts,
  });

  final AppController controller;
  final DashboardStats stats;
  final List<LoanDeal> outstandingDeals;
  final ValueChanged<AppSection> onOpenSection;
  final ValueChanged<DealsViewFilter> onOpenDeals;
  final ValueChanged<ClosedDealsViewFilter> onOpenClosedDeals;
  final ValueChanged<AlertsViewFilter> onOpenAlerts;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color panel = Colors.white;
    final Color ink = const Color(0xFF172033);
    final Color muted = const Color(0xFF6E7689);
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[Color(0xFFF7FAFF), Color(0xFFFFF6EA)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 130),
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Welcome back',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'คุณนิชา',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(color: ink, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Fresh follow-up dashboard',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    gradient: LinearGradient(
                      colors: <Color>[
                        colors.primary,
                        const Color(0xFF5AC8FA),
                        const Color(0xFFFFB341),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: colors.primary.withValues(alpha: 0.22),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'N',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _WalletBalanceCard(
              balance: formatMoney(stats.totalOutstanding),
              activeBorrowers: stats.activeBorrowers,
              activeDeals: stats.activeDeals,
              closedDeals: stats.closedDeals,
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: _WalletShortcut(
                    icon: CupertinoIcons.person_2_fill,
                    label: 'Borrowers',
                    colors: const <Color>[Color(0xFFE5F1FF), Color(0xFFD7EEFF)],
                    iconColor: colors.primary,
                    onTap: () => onOpenSection(AppSection.borrowers),
                  ),
                ),
                Expanded(
                  child: _WalletShortcut(
                    icon: CupertinoIcons.doc_text_fill,
                    label: 'Deals',
                    colors: const <Color>[Color(0xFFFFF0DC), Color(0xFFFFF8DD)],
                    iconColor: const Color(0xFFF59E0B),
                    onTap: () => onOpenDeals(DealsViewFilter.all),
                  ),
                ),
                Expanded(
                  child: _WalletShortcut(
                    icon: CupertinoIcons.arrow_clockwise_circle_fill,
                    label: 'Follow up',
                    colors: const <Color>[Color(0xFFE5FFF4), Color(0xFFDFFAF8)],
                    iconColor: const Color(0xFF14B87A),
                    onTap: () => onOpenDeals(DealsViewFilter.attention),
                  ),
                ),
                Expanded(
                  child: _WalletShortcut(
                    icon: CupertinoIcons.checkmark_seal_fill,
                    label: 'Closed',
                    colors: const <Color>[Color(0xFFF1EBFF), Color(0xFFE8E1FF)],
                    iconColor: const Color(0xFF7C4DFF),
                    onTap: () =>
                        onOpenClosedDeals(ClosedDealsViewFilter.recent),
                  ),
                ),
                Expanded(
                  child: _WalletShortcut(
                    icon: CupertinoIcons.bell_fill,
                    label: 'Alerts',
                    colors: const <Color>[Color(0xFFFFEBEE), Color(0xFFFFF1E6)],
                    iconColor: const Color(0xFFFF5E57),
                    onTap: () => onOpenAlerts(AlertsViewFilter.all),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: () => onOpenDeals(DealsViewFilter.all),
                    child: Container(
                      height: 56,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: panel.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.08),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              'ค้นหาผู้กู้หรือดีล',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: muted),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.search,
                            color: colors.primary.withValues(alpha: 0.9),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: controller.attemptSyncNow,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        colors: <Color>[
                          colors.primary,
                          const Color(0xFF5AC8FA),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: colors.primary.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      CupertinoIcons.arrow_2_circlepath,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Outstanding',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: outstandingDeals.isEmpty
                        ? const Color(0xFFE7F8ED)
                        : const Color(0xFFFFEFE0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    outstandingDeals.isEmpty
                        ? 'All clear'
                        : '${outstandingDeals.length} open',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: outstandingDeals.isEmpty
                          ? const Color(0xFF1E8A4A)
                          : const Color(0xFFD97706),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (outstandingDeals.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: panel.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Text(
                  'ไม่มีลูกหนี้คงค้างตอนนี้',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Column(
                children: outstandingDeals.map((LoanDeal deal) {
                  final Borrower? borrower = controller.borrowerById(
                    deal.borrowerId,
                  );
                  return _WalletTransactionTile(
                    borrowerName: borrower?.name ?? 'Unknown borrower',
                    deal: deal,
                    amount: controller.remainingBalanceForDeal(deal),
                    status: controller.statusForDeal(deal),
                    onTap: () =>
                        showDealDetailDialog(context, controller, deal),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _WalletBalanceCard extends StatelessWidget {
  const _WalletBalanceCard({
    required this.balance,
    required this.activeBorrowers,
    required this.activeDeals,
    required this.closedDeals,
  });

  final String balance;
  final int activeBorrowers;
  final int activeDeals;
  final int closedDeals;

  @override
  Widget build(BuildContext context) {
    final Color primary = Theme.of(context).colorScheme.primary;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: <Color>[
            primary,
            const Color(0xFF54C7FC),
            const Color(0xFF6E7BFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: primary.withValues(alpha: 0.26),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        balance,
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'ยอดคงค้างรวม',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 2,
                    ),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    CupertinoIcons.layers_alt_fill,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: _WalletCardMeta(
                    label: 'ผู้กู้ที่ยัง active',
                    value: '$activeBorrowers ราย',
                  ),
                ),
                Expanded(
                  child: _WalletCardMeta(
                    label: 'ดีลที่กำลังติดตาม',
                    value: '$activeDeals ดีล',
                  ),
                ),
                Expanded(
                  child: _WalletCardMeta(
                    label: 'ปิดยอดแล้ว',
                    value: '$closedDeals ครั้ง',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletCardMeta extends StatelessWidget {
  const _WalletCardMeta({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Container(
        constraints: const BoxConstraints(minHeight: 82),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: 32,
              child: Align(
                alignment: Alignment.topLeft,
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
            ),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WalletShortcut extends StatelessWidget {
  const _WalletShortcut({
    required this.icon,
    required this.label,
    required this.colors,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: colors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.9)),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: iconColor.withValues(alpha: 0.16),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 34,
            child: Center(
              child: Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF445267),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletTransactionTile extends StatelessWidget {
  const _WalletTransactionTile({
    required this.borrowerName,
    required this.deal,
    required this.amount,
    required this.status,
    required this.onTap,
  });

  final String borrowerName;
  final LoanDeal deal;
  final double amount;
  final LoanDealStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color statusTextColor = switch (status) {
      LoanDealStatus.closed => const Color(0xFF30D158),
      LoanDealStatus.overdue => const Color(0xFFFF453A),
      LoanDealStatus.dueToday => const Color(0xFFFF9F0A),
      LoanDealStatus.dueSoon => const Color(0xFFFF9F0A),
      LoanDealStatus.tracking => Theme.of(context).colorScheme.primary,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.88)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[
                statusTextColor.withValues(alpha: 0.88),
                Theme.of(context).colorScheme.primary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              borrowerName.isEmpty ? '?' : borrowerName.characters.first,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(
          borrowerName,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: const Color(0xFF172033),
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '${deal.dealType}  •  ${formatDate(deal.updatedAt)}',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6E7689)),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              formatMoney(amount),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: const Color(0xFF172033),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusTextColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                dealStatusLabel(status),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: statusTextColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
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
                      onDelete: () => _deleteBorrower(borrower),
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

  Future<void> _deleteBorrower(Borrower borrower) async {
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('ลบผู้กู้'),
            content: Text(
              'ต้องการลบ "${borrower.name}" ออกจากทะเบียนผู้กู้หรือไม่',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ยกเลิก'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('ลบ'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) {
      return;
    }

    try {
      await widget.controller.deleteBorrower(borrower: borrower);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ลบผู้กู้เรียบร้อย')));
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
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
                  onEdit: () => _openDealForm(deal: deal),
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

  Future<void> _openDealForm({LoanDeal? deal}) async {
    if (widget.controller.borrowers().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเพิ่มผู้กู้ก่อนสร้างดีล')),
      );
      return;
    }
    final DealDraft? draft = await showDialog<DealDraft>(
      context: context,
      builder: (BuildContext context) =>
          DealFormDialog(controller: widget.controller, initialDeal: deal),
    );
    if (draft == null) return;
    try {
      if (deal == null) {
        await widget.controller.createDeal(
          borrowerId: draft.borrowerId,
          dealType: draft.dealType,
          principal: draft.principal,
          interestRatePercent: draft.interestRatePercent,
          dueDate: draft.dueDate,
        );
      } else {
        await widget.controller.updateDeal(
          deal: deal,
          borrowerId: draft.borrowerId,
          dealType: draft.dealType,
          principal: draft.principal,
          interestRatePercent: draft.interestRatePercent,
          dueDate: draft.dueDate,
        );
      }
    } on ArgumentError catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message.toString())));
    }
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

class LotteryComingSoonView extends StatelessWidget {
  const LotteryComingSoonView({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      title: 'Lottery Sales',
      subtitle: 'พื้นที่สำหรับแอปขายหวยในอนาคต',
      child: SectionCard(
        title: 'Coming soon',
        subtitle: 'ตอนนี้ยังไม่ได้พัฒนาฟีเจอร์ฝั่งขายหวย',
        child: const EmptyState(
          title: 'ยังไม่มีระบบขายหวยในเวอร์ชันนี้',
          message:
              'ตอนนี้ให้ใช้งานฝั่งปล่อยกู้ก่อน แล้วค่อยกลับมาแยก flow ของหวยในรอบถัดไป',
        ),
      ),
    );
  }
}

class _AppDestination {
  const _AppDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final Widget icon;
  final Widget selectedIcon;
  final String label;
}

class _AppWorkspaceDock extends StatelessWidget {
  const _AppWorkspaceDock({
    super.key,
    required this.selectedWorkspace,
    required this.onSelected,
  });

  final AppWorkspace selectedWorkspace;
  final ValueChanged<AppWorkspace> onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.white.withValues(alpha: 0.96),
                  const Color(0xFFF0F4FF).withValues(alpha: 0.93),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.46),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _WorkspaceDockItem(
                    key: const ValueKey<String>('workspace-loan-button'),
                    icon: CupertinoIcons.money_dollar_circle_fill,
                    label: 'ปล่อยกู้',
                    isSelected: selectedWorkspace == AppWorkspace.loanDesk,
                    onTap: () => onSelected(AppWorkspace.loanDesk),
                  ),
                ),
                Expanded(
                  child: _WorkspaceDockItem(
                    key: const ValueKey<String>('workspace-lottery-button'),
                    icon: CupertinoIcons.ticket_fill,
                    label: 'ขายหวย',
                    isSelected: selectedWorkspace == AppWorkspace.lottery,
                    onTap: () => onSelected(AppWorkspace.lottery),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspaceDockItem extends StatelessWidget {
  const _WorkspaceDockItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: <Color>[colors.primary, const Color(0xFF5AC8FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.26),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF748097),
              size: 20,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isSelected ? Colors.white : const Color(0xFF748097),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
