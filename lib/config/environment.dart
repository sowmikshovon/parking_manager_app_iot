/// Environment configuration for API keys and sensitive data
/// This provides a centralized way to manage environment-specific configurations
class Environment {
  // Google Maps API Key - loaded from build-time environment
  static const String mapsApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '', // Empty for security - will be populated at build time
  );

  // Firebase API Key - secured via environment variables
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '', // Empty for security - will be set via environment
  );

  // Build environment detection
  static const bool isDevelopment =
      bool.fromEnvironment('DEBUG', defaultValue: true);
  static const bool isProduction =
      bool.fromEnvironment('PRODUCTION', defaultValue: false);

  // API endpoints (can be environment-specific)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://your-api.com', // Replace with your actual API
  );

  /// Validates that all required environment variables are set
  static void validateConfiguration() {
    if (mapsApiKey.isEmpty) {
      throw Exception(
          'Maps API key not configured. Please set MAPS_API_KEY environment variable.');
    }

    if (firebaseApiKey.isEmpty) {
      throw Exception(
          'Firebase API key not configured. Please set FIREBASE_API_KEY environment variable.');
    }
  }

  /// Returns true if app is running in a secure production environment
  static bool get isSecureEnvironment => isProduction && mapsApiKey.isNotEmpty;
}
