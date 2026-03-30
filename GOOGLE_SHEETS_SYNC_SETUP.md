# Google Sheets Sync Setup

This app syncs by sending the full app snapshot to a Google Apps Script web app. The script then rewrites the spreadsheet tabs with the latest data.

## 1. Create The Spreadsheet

Create a Google Sheet with these tabs:

- `borrowers`
- `deals`
- `payments`
- `events`
- `sync_meta`

## 2. Create The Apps Script

Open `Extensions > Apps Script` from the spreadsheet and replace the default script with this:

```javascript
const SHARED_TOKEN = 'replace-with-shared-secret';

function doPost(e) {
  try {
    const payload = JSON.parse(e.postData.contents || '{}');
    if (SHARED_TOKEN && payload.token !== SHARED_TOKEN) {
      return jsonResponse_(401, {
        ok: false,
        message: 'Unauthorized sync token.',
      });
    }

    const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
    writeSheet_(spreadsheet, 'borrowers', payload.borrowers || []);
    writeSheet_(spreadsheet, 'deals', payload.deals || []);
    writeSheet_(spreadsheet, 'payments', payload.payments || []);
    writeSheet_(spreadsheet, 'events', payload.events || []);
    writeSheet_(spreadsheet, 'sync_meta', [
      {
        app: payload.app || 'Nicha Loan Desk',
        sentAt: payload.sentAt || '',
      },
    ]);

    return jsonResponse_(200, {
      ok: true,
      message: 'Google Sheets sync completed.',
    });
  } catch (error) {
    return jsonResponse_(500, {
      ok: false,
      message: String(error),
    });
  }
}

function writeSheet_(spreadsheet, sheetName, rows) {
  const sheet =
    spreadsheet.getSheetByName(sheetName) || spreadsheet.insertSheet(sheetName);
  sheet.clearContents();

  if (!rows.length) {
    return;
  }

  const headers = Object.keys(rows[0]);
  const values = rows.map((row) => headers.map((header) => row[header] ?? ''));
  sheet.getRange(1, 1, 1, headers.length).setValues([headers]);
  sheet.getRange(2, 1, values.length, headers.length).setValues(values);
}

function jsonResponse_(statusCode, payload) {
  return ContentService.createTextOutput(JSON.stringify(payload)).setMimeType(
    ContentService.MimeType.JSON,
  );
}
```

## 3. Deploy The Web App

Deploy the Apps Script as a web app:

1. Click `Deploy > New deployment`
2. Choose `Web app`
3. Set access to the level you want to allow
4. Copy the web app URL

## 4. Configure The App

### Option A: Desktop Config File

Create this file on Windows:

`%LOCALAPPDATA%\NichaLoanDesk\sync_config.json`

```json
{
  "endpointUrl": "https://script.google.com/macros/s/REPLACE_ME/exec",
  "token": "replace-with-shared-secret"
}
```

### Option B: Dart Defines

Run Flutter with:

```bash
flutter run ^
  --dart-define=GOOGLE_SHEETS_SYNC_URL=https://script.google.com/macros/s/REPLACE_ME/exec ^
  --dart-define=GOOGLE_SHEETS_SYNC_TOKEN=replace-with-shared-secret
```

## Notes

- Sync runs while the app is open.
- The current sync model replaces sheet contents with the latest app snapshot.
- Local data remains the source of truth when sync is not configured or when the network is unavailable.
