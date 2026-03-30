import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nicha_loan_desk/google_sheets_sync.dart';
import 'package:nicha_loan_desk/local_store.dart';
import 'package:nicha_loan_desk/local_store_driver.dart';
import 'package:nicha_loan_desk/main.dart';

void main() {
  testWidgets('loan dashboard loads', (WidgetTester tester) async {
    LocalStore.debugDriver = MemoryLocalStoreDriver();
    GoogleSheetsSyncService.debugInstance =
        GoogleSheetsSyncService.unconfigured();
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() {
      LocalStore.debugDriver = null;
      GoogleSheetsSyncService.debugInstance = null;
    });

    await tester.pumpWidget(const LoanAppBootstrap());
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('section-dashboard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dashboard-active-borrowers-card')),
      findsOneWidget,
    );
  });

  testWidgets('dashboard summary cards open related sections', (
    WidgetTester tester,
  ) async {
    LocalStore.debugDriver = MemoryLocalStoreDriver();
    GoogleSheetsSyncService.debugInstance =
        GoogleSheetsSyncService.unconfigured();
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() {
      LocalStore.debugDriver = null;
      GoogleSheetsSyncService.debugInstance = null;
    });

    await tester.pumpWidget(const LoanAppBootstrap());
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey<String>('dashboard-closed-deals-card')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard-closed-deals-card')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('section-closed-deals')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey<String>('closed-deals-filter-recent')),
          )
          .selected,
      isTrue,
    );
  });

  testWidgets('dashboard schedule shortcut opens attention filter', (
    WidgetTester tester,
  ) async {
    LocalStore.debugDriver = MemoryLocalStoreDriver();
    GoogleSheetsSyncService.debugInstance =
        GoogleSheetsSyncService.unconfigured();
    tester.view.physicalSize = const Size(1400, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() {
      LocalStore.debugDriver = null;
      GoogleSheetsSyncService.debugInstance = null;
    });

    await tester.pumpWidget(const LoanAppBootstrap());
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('dashboard-open-deals-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey<String>('section-deals')), findsOneWidget);
    expect(
      tester
          .widget<ChoiceChip>(
            find.byKey(const ValueKey<String>('deals-filter-attention')),
          )
          .selected,
      isTrue,
    );
  });
}
