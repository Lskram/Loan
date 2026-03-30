import 'package:intl/intl.dart';

import 'models.dart';

final NumberFormat _wholeMoneyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: '฿',
  decimalDigits: 0,
);

final NumberFormat _decimalMoneyFormat = NumberFormat.currency(
  locale: 'en_US',
  symbol: '฿',
  decimalDigits: 2,
);

String formatMoney(double value) {
  final bool needsDecimals = value % 1 != 0;
  return needsDecimals
      ? _decimalMoneyFormat.format(value)
      : _wholeMoneyFormat.format(value);
}

String formatDate(DateTime value) {
  return DateFormat('dd/MM/yyyy').format(value);
}

String formatDateTime(DateTime value) {
  return DateFormat('dd/MM/yyyy HH:mm').format(value);
}

String creditLevelLabel(CreditLevel creditLevel) {
  switch (creditLevel) {
    case CreditLevel.good:
      return 'ดี';
    case CreditLevel.medium:
      return 'กลาง';
    case CreditLevel.risky:
      return 'เสี่ยง';
  }
}

String dealStatusLabel(LoanDealStatus status) {
  switch (status) {
    case LoanDealStatus.tracking:
      return 'กำลังติดตาม';
    case LoanDealStatus.dueSoon:
      return 'ใกล้ครบกำหนด';
    case LoanDealStatus.dueToday:
      return 'ครบกำหนดวันนี้';
    case LoanDealStatus.overdue:
      return 'ค้างชำระ';
    case LoanDealStatus.closed:
      return 'ปิดยอดแล้ว';
  }
}

String dealEventLabel(DealEventType type) {
  switch (type) {
    case DealEventType.created:
      return 'สร้างดีล';
    case DealEventType.updated:
      return 'แก้ไขดีล';
    case DealEventType.manuallyClosed:
      return 'ปิดดีล';
    case DealEventType.autoClosed:
      return 'ปิดอัตโนมัติ';
    case DealEventType.reopened:
      return 'เปิดติดตามอีกครั้ง';
  }
}

String dueOffsetLabel(int daysOffset) {
  if (daysOffset < 0) {
    return 'เกินกำหนด ${daysOffset.abs()} วัน';
  }
  if (daysOffset == 0) {
    return 'ครบกำหนดวันนี้';
  }
  return 'เหลืออีก $daysOffset วัน';
}
