# Firebase Sync Setup

This app uses Firebase Firestore as the source of truth. Business data stays only in memory while the app is open, then reloads from Firebase the next time the app starts. A 30-minute retry loop only applies when there are unsynced changes in the current session.

## Mobile Note

- Android can use the native Firebase app file at `android/app/google-services.json`.
- iOS should use the native Firebase app file `GoogleService-Info.plist`.
- Desktop keeps using `%LOCALAPPDATA%\NichaLoanDesk\firebase_sync_config.json`.

## 1. Create A Firebase Project

Create one Firebase project in the [Firebase Console](https://console.firebase.google.com/).

## 2. Enable Firestore

Inside the project:

1. Open `Build > Firestore Database`
2. Click `Create database`
3. Choose the region you want
4. Start in test mode first if you only want to try the app quickly

## 3. Register Your Apps

Register the app platforms you want to use:

- Android package ID: `com.lskram.nichaloandesk`
- Apple bundle ID: `com.lskram.nichaloandesk`

After adding each app, Firebase will show SDK values such as:

- `apiKey`
- `appId`
- `messagingSenderId`
- `projectId`
- `storageBucket`

For iOS you should also keep:

- `iosBundleId`

## 4. Create The Local Firebase Config File

Create this file on Windows:

`%LOCALAPPDATA%\NichaLoanDesk\firebase_sync_config.json`

Example:

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

## 5. Restart The App

Close and open the app again so it reloads the config.

## 6. Try A Real Sync

1. Add a borrower
2. Wait a moment for the automatic sync attempt
3. Open Firestore in Firebase Console

Collections created by the app:

- `borrowers`
- `deals`
- `payments`
- `events`
- `sync_meta`

## Notes

- Firestore is the source of truth.
- The app removes its old SQLite and JSON snapshot files on startup.
- Firestore disk persistence is disabled to avoid leaving offline business data on the device.
- On a new device, the app restores data from Firestore during startup.
- The app currently upserts records by ID during sync and removes remote documents that no longer exist in the active session snapshot.
- User data changes trigger an immediate background sync attempt.
- If Firebase is unavailable, changes only survive until the app is closed.
- Borrowers can only be deleted when they have no linked deals.
- Since the app does not delete deals yet, stale remote deletes are not an issue in the current workflow.
