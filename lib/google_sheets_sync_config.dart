class GoogleSheetsSyncConfig {
  const GoogleSheetsSyncConfig({required this.endpointUrl, this.token});

  final String endpointUrl;
  final String? token;

  bool get isConfigured => endpointUrl.trim().isNotEmpty;

  static const GoogleSheetsSyncConfig empty = GoogleSheetsSyncConfig(
    endpointUrl: '',
  );
}
