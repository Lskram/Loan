import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/local_store.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/storage_backend.dart';

void main() {
  testWidgets('loan dashboard loads', (WidgetTester tester) async {
    LocalStore.debugBackend = MemoryStorageBackend();

    await tester.pumpWidget(const LoanAppBootstrap());
    await tester.pumpAndSettle();

    expect(find.text('สวัสดีคุณนิชา'), findsOneWidget);
    expect(find.text('การแจ้งเตือนภายในแอป'), findsOneWidget);
  });
}
