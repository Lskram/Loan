import 'package:flutter/material.dart';

import 'app_controller.dart';
import 'formatters.dart';
import 'models.dart';
import 'ui_common.dart';

class BorrowerDraft {
  const BorrowerDraft({
    required this.name,
    required this.phoneNumber,
    required this.creditLevel,
  });
  final String name;
  final String phoneNumber;
  final CreditLevel creditLevel;
}

class DealDraft {
  const DealDraft({
    required this.borrowerId,
    required this.dealType,
    required this.principal,
    required this.interestRatePercent,
    required this.dueDate,
  });
  final String borrowerId;
  final String dealType;
  final double principal;
  final double interestRatePercent;
  final DateTime dueDate;
}

class PaymentDraft {
  const PaymentDraft({required this.amount, required this.note});
  final double amount;
  final String note;
}

class BorrowerFormDialog extends StatefulWidget {
  const BorrowerFormDialog({super.key, this.initialBorrower});
  final Borrower? initialBorrower;

  @override
  State<BorrowerFormDialog> createState() => _BorrowerFormDialogState();
}

class _BorrowerFormDialogState extends State<BorrowerFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late CreditLevel _creditLevel;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialBorrower?.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.initialBorrower?.phoneNumber ?? '',
    );
    _creditLevel = widget.initialBorrower?.creditLevel ?? CreditLevel.good;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialBorrower == null ? 'เพิ่มผู้กู้' : 'แก้ไขข้อมูลผู้กู้',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'ชื่อผู้กู้'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'กรุณากรอกชื่อผู้กู้'
                    : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'เบอร์โทรศัพท์'),
                validator: (String? value) =>
                    value == null || value.trim().isEmpty
                    ? 'กรุณากรอกเบอร์โทรศัพท์'
                    : null,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<CreditLevel>(
                initialValue: _creditLevel,
                decoration: const InputDecoration(labelText: 'ระดับเครดิต'),
                items: CreditLevel.values
                    .map(
                      (CreditLevel level) => DropdownMenuItem<CreditLevel>(
                        value: level,
                        child: Text(creditLevelLabel(level)),
                      ),
                    )
                    .toList(),
                onChanged: (CreditLevel? value) {
                  if (value == null) return;
                  setState(() => _creditLevel = value);
                },
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              BorrowerDraft(
                name: _nameController.text.trim(),
                phoneNumber: _phoneController.text.trim(),
                creditLevel: _creditLevel,
              ),
            );
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

class PaymentFormDialog extends StatefulWidget {
  const PaymentFormDialog({super.key, required this.remainingBalance});
  final double remainingBalance;

  @override
  State<PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<PaymentFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('บันทึกรับชำระ'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ยอดคงเหลือปัจจุบัน ${formatMoney(widget.remainingBalance)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'จำนวนเงินที่รับ'),
                validator: (String? value) {
                  final double? amount = double.tryParse(value ?? '');
                  if (amount == null || amount <= 0) {
                    return 'กรุณากรอกจำนวนเงินมากกว่า 0';
                  }
                  if (amount > widget.remainingBalance + 0.001) {
                    return 'จำนวนเงินต้องไม่เกินยอดคงเหลือ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'หมายเหตุ'),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              PaymentDraft(
                amount: double.parse(_amountController.text),
                note: _noteController.text.trim(),
              ),
            );
          },
          child: const Text('บันทึก'),
        ),
      ],
    );
  }
}

class ReasonDialog extends StatefulWidget {
  const ReasonDialog({
    super.key,
    required this.title,
    required this.hintText,
    required this.confirmLabel,
    required this.initialValue,
  });
  final String title;
  final String hintText;
  final String confirmLabel;
  final String initialValue;

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _reasonController,
            decoration: InputDecoration(hintText: widget.hintText),
            maxLines: 4,
            validator: (String? value) => value == null || value.trim().isEmpty
                ? 'กรุณาระบุเหตุผล'
                : null,
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(_reasonController.text.trim());
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class DealFormDialog extends StatefulWidget {
  const DealFormDialog({
    super.key,
    required this.controller,
    this.initialBorrowerId,
  });
  final AppController controller;
  final String? initialBorrowerId;

  @override
  State<DealFormDialog> createState() => _DealFormDialogState();
}

class _DealFormDialogState extends State<DealFormDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _dealTypeController;
  late final TextEditingController _principalController;
  late final TextEditingController _interestController;
  String? _selectedBorrowerId;
  DateTime _dueDate = DateTime.now().add(const Duration(days: 7));

  @override
  void initState() {
    super.initState();
    final List<Borrower> borrowers = widget.controller.borrowers();
    _selectedBorrowerId =
        widget.initialBorrowerId ??
        (borrowers.isNotEmpty ? borrowers.first.id : null);
    _dealTypeController = TextEditingController(text: 'Loan');
    _principalController = TextEditingController();
    _interestController = TextEditingController(text: '25');
  }

  @override
  void dispose() {
    _dealTypeController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Borrower> borrowers = widget.controller.borrowers();
    final double principal = double.tryParse(_principalController.text) ?? 0;
    final double rate = double.tryParse(_interestController.text) ?? 0;
    final double interest = principal * (rate / 100);
    final double totalDue = principal + interest;

    return AlertDialog(
      title: const Text('สร้างดีลใหม่'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  initialValue: _selectedBorrowerId,
                  decoration: const InputDecoration(labelText: 'ผู้กู้'),
                  items: borrowers
                      .map(
                        (Borrower borrower) => DropdownMenuItem<String>(
                          value: borrower.id,
                          child: Text(
                            '${borrower.name} • ${borrower.phoneNumber}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (String? value) =>
                      setState(() => _selectedBorrowerId = value),
                  validator: (String? value) => value == null || value.isEmpty
                      ? 'กรุณาเลือกผู้กู้'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _dealTypeController,
                  decoration: const InputDecoration(
                    labelText: 'ประเภทดีล',
                    helperText: 'ตัวอย่าง: Loan, 6 Payment Plans, Credits 25%',
                  ),
                  validator: (String? value) =>
                      value == null || value.trim().isEmpty
                      ? 'กรุณากรอกประเภทดีล'
                      : null,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: AppController.suggestedDealTypes
                      .map(
                        (String value) => ActionChip(
                          label: Text(value),
                          onPressed: () => setState(() {
                            _dealTypeController.text = value;
                            if (value.contains('25%')) {
                              _interestController.text = '25';
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _principalController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'เงินต้น'),
                  onChanged: (_) => setState(() {}),
                  validator: (String? value) {
                    final double? amount = double.tryParse(value ?? '');
                    return amount == null || amount <= 0
                        ? 'กรุณากรอกเงินต้นมากกว่า 0'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _interestController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'ดอกเบี้ย (%)',
                    helperText: 'คิดดอกเบี้ยแบบครั้งเดียวจากเงินต้น',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (String? value) {
                    final double? amount = double.tryParse(value ?? '');
                    return amount == null || amount < 0
                        ? 'กรุณากรอกดอกเบี้ยเป็นตัวเลขที่ถูกต้อง'
                        : null;
                  },
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () async {
                    final DateTime? selected = await showDatePicker(
                      context: context,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                      initialDate: _dueDate,
                    );
                    if (selected != null) setState(() => _dueDate = selected);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'วันครบกำหนด'),
                    child: Text(formatDate(_dueDate)),
                  ),
                ),
                const SizedBox(height: 18),
                SectionCard(
                  title: 'สรุปก่อนบันทึก',
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      InfoPill(
                        label: 'ดอกเบี้ยที่คำนวณ',
                        value: formatMoney(interest),
                      ),
                      InfoPill(
                        label: 'ยอดรวมที่ต้องรับคืน',
                        value: formatMoney(totalDue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ยกเลิก'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              DealDraft(
                borrowerId: _selectedBorrowerId!,
                dealType: _dealTypeController.text.trim(),
                principal: double.parse(_principalController.text),
                interestRatePercent: double.parse(_interestController.text),
                dueDate: _dueDate,
              ),
            );
          },
          child: const Text('สร้างดีล'),
        ),
      ],
    );
  }
}

class BorrowerDetailDialog extends StatelessWidget {
  const BorrowerDetailDialog({
    super.key,
    required this.controller,
    required this.borrower,
  });
  final AppController controller;
  final Borrower borrower;

  @override
  Widget build(BuildContext context) {
    final List<LoanDeal> activeDeals = controller
        .activeDeals()
        .where((LoanDeal deal) => deal.borrowerId == borrower.id)
        .toList();
    final List<LoanDeal> closedDeals = controller
        .closedDeals()
        .where((LoanDeal deal) => deal.borrowerId == borrower.id)
        .toList();
    return AlertDialog(
      title: Text(borrower.name),
      content: SizedBox(
        width: 640,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  InfoPill(label: 'เบอร์โทร', value: borrower.phoneNumber),
                  InfoPill(
                    label: 'เครดิต',
                    value: creditLevelLabel(borrower.creditLevel),
                  ),
                  InfoPill(
                    label: 'สร้างเมื่อ',
                    value: formatDateTime(borrower.createdAt),
                  ),
                  InfoPill(
                    label: 'อัปเดตล่าสุด',
                    value: formatDateTime(borrower.updatedAt),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'ดีลที่ยังติดตามอยู่',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (activeDeals.isEmpty)
                const Text('ไม่มีดีล active')
              else
                Column(
                  children: activeDeals
                      .map(
                        (LoanDeal deal) => DealListTile(
                          borrowerName: borrower.name,
                          deal: deal,
                          remaining: controller.remainingBalanceForDeal(deal),
                          daysUntilDue: controller.daysUntilDue(deal),
                          status: controller.statusForDeal(deal),
                          onTap: () =>
                              showDealDetailDialog(context, controller, deal),
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 16),
              Text(
                'ประวัติดีลที่ปิดแล้ว',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (closedDeals.isEmpty)
                const Text('ยังไม่มีดีลที่ปิดแล้ว')
              else
                Column(
                  children: closedDeals
                      .map(
                        (LoanDeal deal) => DealListTile(
                          borrowerName: borrower.name,
                          deal: deal,
                          remaining: controller.remainingBalanceForDeal(deal),
                          daysUntilDue: controller.daysUntilDue(deal),
                          status: controller.statusForDeal(deal),
                          onTap: () =>
                              showDealDetailDialog(context, controller, deal),
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('ปิด'),
        ),
      ],
    );
  }
}

class DealDetailDialog extends StatelessWidget {
  const DealDetailDialog({
    super.key,
    required this.controller,
    required this.initialDealId,
  });
  final AppController controller;
  final String initialDealId;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final LoanDeal? deal = controller.dealById(initialDealId);
        if (deal == null) {
          return const AlertDialog(
            title: Text('ไม่พบดีล'),
            content: Text('ดีลนี้อาจถูกลบหรือข้อมูลไม่สามารถโหลดได้'),
          );
        }
        final Borrower? borrower = controller.borrowerById(deal.borrowerId);
        final List<PaymentRecord> payments = controller.paymentsForDeal(
          deal.id,
        );
        final List<DealEvent> events = controller.eventsForDeal(deal.id);
        final double remaining = controller.remainingBalanceForDeal(deal);
        final LoanDealStatus status = controller.statusForDeal(deal);

        return AlertDialog(
          title: Text(borrower?.name ?? 'Loan detail'),
          content: SizedBox(
            width: 760,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      StatusChip(status: status),
                      InfoPill(
                        label: 'รหัสดีล',
                        value: deal.id.substring(0, 8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: <Widget>[
                      InfoPill(label: 'ผู้กู้', value: borrower?.name ?? '-'),
                      InfoPill(
                        label: 'เบอร์โทร',
                        value: borrower?.phoneNumber ?? '-',
                      ),
                      InfoPill(label: 'ประเภทดีล', value: deal.dealType),
                      InfoPill(
                        label: 'เงินต้น',
                        value: formatMoney(deal.principal),
                      ),
                      InfoPill(
                        label: 'ดอกเบี้ย',
                        value:
                            '${deal.interestRatePercent.toStringAsFixed(deal.interestRatePercent % 1 == 0 ? 0 : 2)}%',
                      ),
                      InfoPill(
                        label: 'จำนวนดอกเบี้ย',
                        value: formatMoney(deal.interestAmount),
                      ),
                      InfoPill(
                        label: 'ยอดรวม',
                        value: formatMoney(deal.totalDue),
                      ),
                      InfoPill(label: 'คงเหลือ', value: formatMoney(remaining)),
                      InfoPill(
                        label: 'ครบกำหนด',
                        value: formatDate(deal.dueDate),
                      ),
                      InfoPill(
                        label: 'สร้างเมื่อ',
                        value: formatDateTime(deal.createdAt),
                      ),
                      InfoPill(
                        label: 'อัปเดตล่าสุด',
                        value: formatDateTime(deal.updatedAt),
                      ),
                    ],
                  ),
                  if (deal.closedReason != null) ...<Widget>[
                    const SizedBox(height: 18),
                    SectionCard(
                      title: 'เหตุผลปิดดีลล่าสุด',
                      child: Text(deal.closedReason!),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SectionCard(
                    title: 'ประวัติการรับชำระ',
                    subtitle: 'รองรับหลายงวดและยอดแต่ละงวดไม่จำเป็นต้องเท่ากัน',
                    child: payments.isEmpty
                        ? const EmptyState(
                            title: 'ยังไม่มีรายการรับชำระ',
                            message:
                                'เมื่อบันทึกรับชำระ ระบบจะคำนวณยอดคงเหลือให้อัตโนมัติ',
                          )
                        : Column(
                            children: payments
                                .map(
                                  (PaymentRecord payment) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(formatMoney(payment.amount)),
                                    subtitle: Text(
                                      '${formatDateTime(payment.paidAt)}${payment.note == null || payment.note!.isEmpty ? '' : ' • ${payment.note}'}',
                                    ),
                                    trailing: Text(
                                      'คงเหลือ ${formatMoney(payment.remainingAfterPayment)}',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                  const SizedBox(height: 18),
                  SectionCard(
                    title: 'ประวัติสถานะดีล',
                    subtitle: 'ติดตามการสร้าง ปิด และ reopen',
                    child: events.isEmpty
                        ? const Text('ยังไม่มีประวัติสถานะ')
                        : Column(
                            children: events
                                .map(
                                  (DealEvent event) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(dealEventLabel(event.type)),
                                    subtitle: Text(event.description),
                                    trailing: Text(
                                      formatDateTime(event.createdAt),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            if (!deal.isClosed)
              OutlinedButton(
                onPressed: () async {
                  final PaymentDraft? draft = await showDialog<PaymentDraft>(
                    context: context,
                    builder: (BuildContext context) =>
                        PaymentFormDialog(remainingBalance: remaining),
                  );
                  if (draft == null) return;
                  await controller.addPayment(
                    deal: deal,
                    amount: draft.amount,
                    note: draft.note,
                  );
                },
                child: const Text('รับชำระ'),
              ),
            if (!deal.isClosed)
              OutlinedButton(
                onPressed: () async {
                  final String? reason = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => const ReasonDialog(
                      title: 'ปิดดีล',
                      hintText: 'ระบุเหตุผลที่ปิดดีล',
                      confirmLabel: 'ปิดดีล',
                      initialValue: 'Closed manually after review.',
                    ),
                  );
                  if (reason == null) return;
                  await controller.closeDeal(deal: deal, reason: reason);
                },
                child: const Text('ปิดดีล'),
              ),
            if (deal.isClosed)
              FilledButton.tonal(
                onPressed: () async {
                  final String? reason = await showDialog<String>(
                    context: context,
                    builder: (BuildContext context) => const ReasonDialog(
                      title: 'เปิดดีลกลับมาติดตาม',
                      hintText: 'ระบุเหตุผลของการ reopen',
                      confirmLabel: 'Reopen',
                      initialValue: 'Reopened after payment review.',
                    ),
                  );
                  if (reason == null) return;
                  await controller.reopenDeal(deal: deal, reason: reason);
                },
                child: const Text('Reopen'),
              ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }
}

Future<void> showBorrowerDetailDialog(
  BuildContext context,
  AppController controller,
  Borrower borrower,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) =>
        BorrowerDetailDialog(controller: controller, borrower: borrower),
  );
}

Future<void> showDealDetailDialog(
  BuildContext context,
  AppController controller,
  LoanDeal deal,
) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) =>
        DealDetailDialog(controller: controller, initialDealId: deal.id),
  );
}
