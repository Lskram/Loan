import 'package:flutter_test/flutter_test.dart';

import 'package:nicha_loan_desk/app_controller.dart';
import 'package:nicha_loan_desk/firebase_sync_service.dart';
import 'package:nicha_loan_desk/local_store.dart';
import 'package:nicha_loan_desk/local_store_driver.dart';
import 'package:nicha_loan_desk/models.dart';

void main() {
  setUp(() {
    LocalStore.debugDriver = MemoryLocalStoreDriver();
    FirebaseSyncService.debugInstance = FirebaseSyncService.unconfigured();
  });

  tearDown(() {
    LocalStore.debugDriver = null;
    FirebaseSyncService.debugInstance = null;
  });

  test('deal can be updated and keeps due time', () async {
    final AppController controller = await AppController.create();
    addTearDown(controller.dispose);

    await controller.addBorrower(
      name: 'Nicha',
      phoneNumber: '0812345678',
      creditLevel: CreditLevel.good,
    );
    final Borrower borrower = controller.borrowers().single;
    await controller.createDeal(
      borrowerId: borrower.id,
      dealType: 'Loan',
      principal: 10000,
      interestRatePercent: 25,
      dueDate: DateTime(2026, 4, 2, 14, 30),
    );

    final LoanDeal originalDeal = controller.activeDeals().single;
    final DateTime updatedDueDate = DateTime(2026, 4, 4, 19, 45);
    await controller.updateDeal(
      deal: originalDeal,
      borrowerId: borrower.id,
      dealType: 'Credits 25%',
      principal: 12000,
      interestRatePercent: 20,
      dueDate: updatedDueDate,
    );

    final LoanDeal updatedDeal = controller.dealById(originalDeal.id)!;
    expect(updatedDeal.dealType, 'Credits 25%');
    expect(updatedDeal.principal, 12000);
    expect(updatedDeal.interestRatePercent, 20);
    expect(updatedDeal.dueDate, updatedDueDate);
    expect(
      controller
          .eventsForDeal(updatedDeal.id)
          .any((DealEvent event) => event.type == DealEventType.updated),
      isTrue,
    );
  });

  test('borrower deletion is blocked when deals are linked', () async {
    final AppController controller = await AppController.create();
    addTearDown(controller.dispose);

    await controller.addBorrower(
      name: 'Aom',
      phoneNumber: '0899999999',
      creditLevel: CreditLevel.medium,
    );
    final Borrower borrower = controller.borrowers().single;
    await controller.createDeal(
      borrowerId: borrower.id,
      dealType: 'Loan',
      principal: 5000,
      interestRatePercent: 10,
      dueDate: DateTime(2026, 4, 1, 9, 0),
    );

    await expectLater(
      controller.deleteBorrower(borrower: borrower),
      throwsA(isA<ArgumentError>()),
    );
    expect(controller.borrowers(), hasLength(1));
  });

  test('borrower without linked deals can be deleted', () async {
    final AppController controller = await AppController.create();
    addTearDown(controller.dispose);

    await controller.addBorrower(
      name: 'Mint',
      phoneNumber: '0866666666',
      creditLevel: CreditLevel.risky,
    );
    final Borrower borrower = controller.borrowers().single;

    await controller.deleteBorrower(borrower: borrower);

    expect(controller.borrowers(), isEmpty);
  });
}
