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
- borrower edit and safe delete flow
- loan creation from an existing borrower profile
- loan deal editing after creation
- per-deal interest calculation
- flexible installment payments
- overdue and upcoming payment reminders
- closed-deal history and reopen flow without creating a new debt
- Firebase-first storage with automatic Firestore sync after each change, plus a 30-minute retry window for unsynced changes

## Core Rules
- Every loan must be linked to one borrower.
- Interest is calculated per loan deal, not as a recurring monthly accrual.
- Deal total is calculated as `principal + interest`.
- The due date is selected manually for each deal.
- The due date can include both date and time.
- Repayment can be split into any number of installments.
- Installment amounts do not need to be equal.
- A closed deal can be reopened for follow-up if the recorded payment was incomplete, without creating a new contract.
- Borrowers can only be deleted when they have no linked deals, to avoid breaking history.

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
- mobile uses a scroll-reveal workspace dock to switch between `ปล่อยกู้` and the `ขายหวย` placeholder
- wallet-style outstanding list shows only borrowers with open debt; closed deals stay in history
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
- due time
- repayment history
- remaining balance
- current status

## Notifications
V1 uses in-app notifications for:

- upcoming due dates
- overdue deals
- reopened follow-up deals

## Data Storage
- Firebase Firestore is the source of truth.
- Business data is kept only in memory while the app is open.
- The app removes its old local SQLite and JSON snapshot files on startup.
- Firestore disk persistence is disabled so the app does not keep an offline cache on the device.
- The app tries to sync records to Firebase Firestore immediately after each saved change when sync is configured.
- The app retries unsynced changes every 30 minutes while it remains open.
- When a new device starts, the app pulls borrowers, deals, payments, and history from Firebase.
- Closed deals remain available in Firebase for history and auditing.

## Firebase Sync
- Sync is triggered while the app is running.
- On startup, the app loads the newest Firebase snapshot into the current session.
- Saving borrowers, deals, payments, closing a deal, or reopening a deal triggers an immediate sync attempt.
- Android uses native Firebase setup from [google-services.json](/D:/Work/flutter_app/android/app/google-services.json).
- Configuration can be provided by:
  - native mobile Firebase app setup on Android/iOS
  - a local config file on desktop at `LOCALAPPDATA\NichaLoanDesk\firebase_sync_config.json`
  - a JSON dart define such as `--dart-define=FIREBASE_SYNC_CONFIG_JSON=...`
- The desktop config file format is:

```json
{
  "android": {
    "apiKey": "YOUR_ANDROID_API_KEY",
    "appId": "YOUR_ANDROID_APP_ID",
    "messagingSenderId": "YOUR_SENDER_ID",
    "projectId": "YOUR_PROJECT_ID",
    "storageBucket": "YOUR_STORAGE_BUCKET"
  },
  "ios": {
    "apiKey": "YOUR_IOS_API_KEY",
    "appId": "YOUR_IOS_APP_ID",
    "messagingSenderId": "YOUR_SENDER_ID",
    "projectId": "YOUR_PROJECT_ID",
    "storageBucket": "YOUR_STORAGE_BUCKET",
    "iosBundleId": "com.lskram.nichaloandesk"
  }
}
```

- Setup details are in [FIREBASE_SYNC_SETUP.md](FIREBASE_SYNC_SETUP.md).
- If Firebase is unavailable, changes only remain in memory for the current app session.

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
