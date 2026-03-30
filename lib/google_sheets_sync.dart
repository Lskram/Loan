import 'dart:convert';

import 'package:http/http.dart' as http;

import 'google_sheets_sync_config.dart';
import 'models.dart';
import 'sync_config_loader.dart';

class GoogleSheetsSyncResult {
  const GoogleSheetsSyncResult({required this.success, required this.message});

  final bool success;
  final String message;
}

class GoogleSheetsSyncService {
  GoogleSheetsSyncService._(this._config, this._client);

  static GoogleSheetsSyncService? debugInstance;

  final GoogleSheetsSyncConfig _config;
  final http.Client _client;

  bool get isConfigured => _config.isConfigured;

  static Future<GoogleSheetsSyncService> create({http.Client? client}) async {
    if (debugInstance != null) {
      return debugInstance!;
    }

    final GoogleSheetsSyncConfig config = await loadGoogleSheetsSyncConfig();
    return GoogleSheetsSyncService._(config, client ?? http.Client());
  }

  factory GoogleSheetsSyncService.unconfigured({http.Client? client}) {
    return GoogleSheetsSyncService._(
      GoogleSheetsSyncConfig.empty,
      client ?? http.Client(),
    );
  }

  Future<GoogleSheetsSyncResult> sync(
    AppData data, {
    required bool isManual,
  }) async {
    if (!isConfigured) {
      return const GoogleSheetsSyncResult(
        success: false,
        message:
            'Google Sheets sync is not configured yet. Local data remains available offline.',
      );
    }

    try {
      final Map<String, Object?> payload = <String, Object?>{
        'app': 'Nicha Loan Desk',
        'sentAt': DateTime.now().toIso8601String(),
        'token': _config.token,
        'borrowers': data.borrowers
            .map((Borrower borrower) => borrower.toJson())
            .toList(),
        'deals': data.deals.map((LoanDeal deal) => deal.toJson()).toList(),
        'payments': data.payments
            .map((PaymentRecord payment) => payment.toJson())
            .toList(),
        'events': data.events.map((DealEvent event) => event.toJson()).toList(),
        'syncState': data.syncState.toJson(),
      };

      final Uri uri = Uri.parse(_config.endpointUrl);
      final http.Response response = await _client
          .post(
            uri,
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return GoogleSheetsSyncResult(
          success: false,
          message:
              'Google Sheets sync failed (${response.statusCode}). ${response.body.trim()}',
        );
      }

      final String? responseMessage = _extractMessage(response.body);
      return GoogleSheetsSyncResult(
        success: true,
        message:
            responseMessage ??
            (isManual
                ? 'Manual Google Sheets sync completed.'
                : 'Scheduled Google Sheets sync completed.'),
      );
    } catch (error) {
      return GoogleSheetsSyncResult(
        success: false,
        message: 'Google Sheets sync failed: $error',
      );
    }
  }

  String? _extractMessage(String rawBody) {
    final String trimmed = rawBody.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    try {
      final Object? decoded = jsonDecode(trimmed);
      if (decoded is Map<String, dynamic>) {
        final String? message = decoded['message'] as String?;
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      return trimmed;
    }

    return null;
  }
}
