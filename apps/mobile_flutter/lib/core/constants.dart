class AppConstants {
  AppConstants._();

  static const String appName = 'BeeApp';
  static const String defaultRegion = 'eu-central';

  /// Base URL for the backend API. Can be overridden via environment variable
  /// or runtime configuration.
  ///
  /// Local dev (Android emulator): http://10.0.2.2:3000/v1
  /// Local dev (iOS simulator):    http://localhost:3000/v1
  /// Fly.io:                       https://beefactory-api.fly.dev/v1
  /// Render:                       https://beefactory-api.onrender.com/v1
  static String apiBaseUrl = const String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://beefactory-api.fly.dev/v1',
  );

  /// WebSocket server URL (without /chat namespace — added by ChatSocket).
  /// Local: http://10.0.2.2:3000
  /// Fly.io: https://beefactory-api.fly.dev
  static String wsBaseUrl = const String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'https://beefactory-api.fly.dev',
  );

  static const Duration httpTimeout = Duration(seconds: 30);
  static const int syncRetryLimit = 5;
  static const String lastSyncKey = 'last_sync_timestamp';
  static const String jwtTokenKey = 'jwt_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
}
