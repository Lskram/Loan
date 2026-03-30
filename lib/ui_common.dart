import 'package:flutter/material.dart';

import 'formatters.dart';
import 'models.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const <Widget>[],
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: <Widget>[
          Wrap(
            runSpacing: 16,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Wrap(spacing: 12, runSpacing: 12, children: actions),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.headerAction,
  });
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? headerAction;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...[headerAction].whereType<Widget>(),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
    this.onTap,
    this.actionLabel,
    this.tapTargetKey,
  });
  final String title;
  final String value;
  final String caption;
  final IconData icon;
  final VoidCallback? onTap;
  final String? actionLabel;
  final Key? tapTargetKey;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 220,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: tapTargetKey,
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(icon, color: colors.primary, size: 20),
                      ),
                      if (onTap != null)
                        Icon(
                          Icons.arrow_outward_rounded,
                          color: colors.primary,
                          size: 18,
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  if (actionLabel != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      actionLabel!,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hintText,
    required this.onChanged,
    this.controller,
  });
  final String hintText;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search_rounded),
      ),
    );
  }
}

class InfoPill extends StatelessWidget {
  const InfoPill({super.key, required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.inbox_rounded,
            size: 42,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class CreditChip extends StatelessWidget {
  const CreditChip({super.key, required this.level});
  final CreditLevel level;

  @override
  Widget build(BuildContext context) {
    final Color color = switch (level) {
      CreditLevel.good => const Color(0xFF2E7D32),
      CreditLevel.medium => const Color(0xFFB26A00),
      CreditLevel.risky => const Color(0xFFB3261E),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        creditLevelLabel(level),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final LoanDealStatus status;

  @override
  Widget build(BuildContext context) {
    final Color color = statusColor(context, status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(statusIcon(status), size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            dealStatusLabel(status),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

Color statusColor(BuildContext context, LoanDealStatus status) {
  return switch (status) {
    LoanDealStatus.tracking => Theme.of(context).colorScheme.primary,
    LoanDealStatus.dueSoon => const Color(0xFFB26A00),
    LoanDealStatus.dueToday => const Color(0xFF8B5E34),
    LoanDealStatus.overdue => const Color(0xFFB3261E),
    LoanDealStatus.closed => const Color(0xFF2E7D32),
  };
}

IconData statusIcon(LoanDealStatus status) {
  return switch (status) {
    LoanDealStatus.tracking => Icons.schedule_rounded,
    LoanDealStatus.dueSoon => Icons.event_repeat_rounded,
    LoanDealStatus.dueToday => Icons.today_rounded,
    LoanDealStatus.overdue => Icons.warning_amber_rounded,
    LoanDealStatus.closed => Icons.check_circle_rounded,
  };
}

class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.syncState});
  final SyncState syncState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1E4D4F), Color(0xFF8B5E34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Wrap(
        spacing: 24,
        runSpacing: 24,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Local-first loan control',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.74),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'เก็บผู้กู้ สร้างดีล คำนวณดอกเบี้ย รับชำระ และเปิดดีลกลับมาติดตามใหม่ได้จากชุดข้อมูลเดิม',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'ระบบเก็บข้อมูลไว้ในเครื่องก่อนเสมอ และวางจุดต่อสำหรับการ sync ขึ้น Google Sheets ทุก 30 นาทีเมื่อเติมค่าการเชื่อมต่อภายหลัง',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(Icons.sync_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        'Sync status',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    syncState.lastMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Last attempt: ${syncState.lastAttemptAt == null ? '-' : formatDateTime(syncState.lastAttemptAt!)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Next attempt: ${formatDateTime(syncState.nextAttemptAt)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompactHeroCard extends StatelessWidget {
  const CompactHeroCard({super.key, required this.syncState});

  final SyncState syncState;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1E4D4F), Color(0xFF8B5E34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Dashboard overview',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.76),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '\u0e20\u0e32\u0e1e\u0e23\u0e27\u0e21\u0e01\u0e32\u0e23\u0e15\u0e34\u0e14\u0e15\u0e32\u0e21\u0e27\u0e31\u0e19\u0e19\u0e35\u0e49',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  syncState.lastMessage,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              _SyncMetaChip(
                label: 'Last attempt',
                value: syncState.lastAttemptAt == null
                    ? '-'
                    : formatDateTime(syncState.lastAttemptAt!),
              ),
              _SyncMetaChip(
                label: 'Next sync',
                value: formatDateTime(syncState.nextAttemptAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncMetaChip extends StatelessWidget {
  const _SyncMetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: 172,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.76),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class BorrowerCard extends StatelessWidget {
  const BorrowerCard({
    super.key,
    required this.borrower,
    required this.activeDeals,
    required this.outstanding,
    required this.onView,
    required this.onEdit,
    required this.onCreateDeal,
  });
  final Borrower borrower;
  final int activeDeals;
  final double outstanding;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onCreateDeal;

  @override
  Widget build(BuildContext context) {
    final String initial = borrower.name.isEmpty
        ? '?'
        : borrower.name.substring(0, 1).toUpperCase();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Wrap(
        spacing: 20,
        runSpacing: 16,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          SizedBox(
            width: 520,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(
                  radius: 28,
                  child: Text(
                    initial,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              borrower.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 10),
                          CreditChip(level: borrower.creditLevel),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        borrower.phoneNumber,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Active deals: $activeDeals  •  Outstanding: ${formatMoney(outstanding)}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: <Widget>[
              OutlinedButton(
                onPressed: onView,
                child: const Text('รายละเอียด'),
              ),
              OutlinedButton(onPressed: onEdit, child: const Text('แก้ไข')),
              FilledButton.tonal(
                onPressed: onCreateDeal,
                child: const Text('ปล่อยกู้'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DealCard extends StatelessWidget {
  const DealCard({
    super.key,
    required this.borrowerName,
    required this.borrowerPhone,
    required this.deal,
    required this.remaining,
    required this.totalPaid,
    required this.daysUntilDue,
    required this.status,
    required this.onView,
    this.onPayment,
  });
  final String borrowerName;
  final String borrowerPhone;
  final LoanDeal deal;
  final double remaining;
  final double totalPaid;
  final int daysUntilDue;
  final LoanDealStatus status;
  final VoidCallback onView;
  final VoidCallback? onPayment;

  @override
  Widget build(BuildContext context) {
    final double progress = deal.totalDue == 0 ? 0 : totalPaid / deal.totalDue;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 16,
            runSpacing: 12,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 660,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Text(
                          borrowerName,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        StatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${deal.dealType}  •  Due ${formatDate(deal.dueDate)}  •  $borrowerPhone',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  OutlinedButton(
                    onPressed: onView,
                    child: const Text('รายละเอียด'),
                  ),
                  if (onPayment != null)
                    FilledButton.tonal(
                      onPressed: onPayment,
                      child: const Text('รับชำระ'),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 18,
            runSpacing: 10,
            children: <Widget>[
              InfoPill(label: 'เงินต้น', value: formatMoney(deal.principal)),
              InfoPill(
                label: 'ดอกเบี้ย',
                value:
                    '${deal.interestRatePercent.toStringAsFixed(deal.interestRatePercent % 1 == 0 ? 0 : 2)}%',
              ),
              InfoPill(label: 'ยอดรวม', value: formatMoney(deal.totalDue)),
              InfoPill(label: 'ชำระแล้ว', value: formatMoney(totalPaid)),
              InfoPill(label: 'คงเหลือ', value: formatMoney(remaining)),
              InfoPill(
                label: 'สถานะกำหนด',
                value: dueOffsetLabel(daysUntilDue),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class DealListTile extends StatelessWidget {
  const DealListTile({
    super.key,
    required this.borrowerName,
    required this.deal,
    required this.remaining,
    required this.daysUntilDue,
    required this.status,
    required this.onTap,
  });
  final String borrowerName;
  final LoanDeal deal;
  final double remaining;
  final int daysUntilDue;
  final LoanDealStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      visualDensity: VisualDensity.compact,
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      title: Text(borrowerName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${deal.dealType} • ${formatDate(deal.dueDate)} • ${dueOffsetLabel(daysUntilDue)}',
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 118),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              formatMoney(remaining),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            StatusChip(status: status),
          ],
        ),
      ),
    );
  }
}

class NotificationListTile extends StatelessWidget {
  const NotificationListTile({
    super.key,
    required this.item,
    required this.onTap,
  });
  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        visualDensity: VisualDensity.compact,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        onTap: onTap,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor: statusColor(
            context,
            item.status,
          ).withValues(alpha: 0.14),
          child: Icon(
            statusIcon(item.status),
            color: statusColor(context, item.status),
            size: 18,
          ),
        ),
        title: Text(
          '${item.borrowerName} • ${item.dealType}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${dealStatusLabel(item.status)} • Due ${formatDate(item.dueDate)} • ${dueOffsetLabel(item.daysOffset)}',
        ),
        trailing: Text(
          formatMoney(item.remainingBalance),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
