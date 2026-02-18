class AppConstants {
  AppConstants._();

  static const String appName = 'BeeApp';
  static const String defaultRegion = 'eu-central';

  /// Base URL for the backend API. Can be overridden via environment variable
  /// or runtime configuration.
  static String apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api/v1',
  );

  static const Duration httpTimeout = Duration(seconds: 30);
  static const int syncRetryLimit = 5;
  static const String lastSyncKey = 'last_sync_timestamp';
  static const String jwtTokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
}
