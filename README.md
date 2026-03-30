# Nicha Loan Desk

Flutter application for managing borrower records, loan deals, repayments, reminders, and closed-deal follow-up for a single operator.

## App Identity
- Product name: `Nicha Loan Desk`
- Flutter package: `nicha_loan_desk`
- Android application ID: `com.lskram.nichaloandesk`
- Apple bundle ID: `com.lskram.nichaloandesk`

## Product Summary
This app is designed for one user, `Khun Nicha`, to manage daily lending transactions in one place. The system supports:

- borrower registration
- loan creation from an existing borrower profile
- per-deal interest calculation
- flexible installment payments
- overdue and upcoming payment reminders
- closed-deal history and reopen flow without creating a new debt
- local-first storage with scheduled sync to Google Sheets

## Core Rules
- Every loan must be linked to one borrower.
- Interest is calculated per loan deal, not as a recurring monthly accrual.
- Deal total is calculated as `principal + interest`.
- The due date is selected manually for each deal.
- Repayment can be split into any number of installments.
- Installment amounts do not need to be equal.
- A closed deal can be reopened for follow-up if the recorded payment was incomplete, without creating a new contract.

## Main Screens
- Dashboard
- Borrower Registry
- Loan Transaction
- Deal Detail
- Repayment Entry
- Closed Deals History

## Dashboard
The dashboard is centered around quick daily operations:

- greeting message for `Khun Nicha`
- compact overview layout for faster scanning
- active borrower count
- total collectible amount from open deals
- closed deal count
- upcoming due list sorted by nearest payment date
- tappable summary cards that jump to borrowers, active deals, closed deals, or alerts
- dashboard shortcuts open target screens with contextual filters such as attention-required deals or recently closed history

## Borrower Data
Initial borrower data is intentionally minimal:

- name
- phone number
- credit status: `Good`, `Medium`, `Risk`

## Deal Detail View
The app does not generate printable receipts or PDF files in V1. Instead, each deal has a detail screen that shows:

- transaction date and time
- borrower info
- principal
- interest rate
- interest amount
- total due
- due date
- repayment history
- remaining balance
- current status

## Notifications
V1 uses in-app notifications for:

- upcoming due dates
- overdue deals
- reopened follow-up deals

## Data Storage
- Data is stored locally first.
- Mobile and desktop builds use a local SQLite database.
- Web builds use browser local storage as a fallback store.
- The app can sync records to Google Sheets every 30 minutes when sync is configured.
- Closed deals remain available for history and auditing.

## Google Sheets Sync
- Sync is triggered while the app is running.
- Configuration can be provided by:
  - a local config file on desktop at `LOCALAPPDATA\NichaLoanDesk\sync_config.json`
  - Dart defines such as `--dart-define=GOOGLE_SHEETS_SYNC_URL=...`
- The desktop config file format is:

```json
{
  "endpointUrl": "https://script.google.com/macros/s/REPLACE_ME/exec",
  "token": "replace-with-shared-secret"
}
```

- Setup details and an Apps Script example are in [GOOGLE_SHEETS_SYNC_SETUP.md](GOOGLE_SHEETS_SYNC_SETUP.md).

## Development
### Requirements
- Flutter SDK
- Dart SDK compatible with the version in `pubspec.yaml`

### Run
```bash
flutter pub get
flutter run
```

### Test
```bash
flutter test
```
