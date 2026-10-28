class AppConfig {
  AppConfig._();

  /// Base URL of the QREX backend API.
  /// For local dev, point to your machine's Laravel `php artisan serve` URL.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://qrex.qodeigence.com',
  );

  static const String appName = 'QREX';

  static const String tagline = 'Realty ERP & CRM';

  static const String apiPrefix = '/api';

  static String get fullApiBase => '$apiBaseUrl$apiPrefix';

  /// Base URL for public property pages (shareable website links).
  static String get propertyBaseUrl => '$apiBaseUrl/properties';
}
