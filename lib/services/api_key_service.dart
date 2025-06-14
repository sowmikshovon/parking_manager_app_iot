import '../config/environment.dart';

/// Service to validate and manage API key security
class ApiKeyService {
  static bool _isInitialized = false;

  /// Initialize and validate all API keys
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Validate environment configuration
      Environment.validateConfiguration();

      // Additional security checks
      _validateGoogleMapsKey();
      _validateFirebaseKey();
      _isInitialized = true;
      // Debug logging disabled in production
    } catch (e) {
      // Debug logging disabled in production
      if (Environment.isProduction) {
        // In production, fail fast if keys are invalid
        throw Exception(
            'Production app cannot start without valid API keys: $e');
      }
    }
  }

  /// Validate Google Maps API key format and security
  static void _validateGoogleMapsKey() {
    final mapsKey = Environment.mapsApiKey;

    if (mapsKey.isEmpty) {
      throw Exception('Google Maps API key is empty');
    }

    if (!mapsKey.startsWith('AIza')) {
      throw Exception('Invalid Google Maps API key format');
    }

    if (mapsKey.length < 35) {
      throw Exception('Google Maps API key appears to be truncated');
    } // Security warning for development
    if (Environment.isDevelopment &&
        mapsKey == 'AIzaSyDY6Xx10omIllIivBo4TOiegLMRvm2E7Xs') {
      // Debug logging disabled in production
    }
  }

  /// Validate Firebase API key
  static void _validateFirebaseKey() {
    final firebaseKey = Environment.firebaseApiKey;

    if (firebaseKey.isEmpty) {
      throw Exception('Firebase API key is empty');
    }

    if (!firebaseKey.startsWith('AIza')) {
      throw Exception('Invalid Firebase API key format');
    }
  }

  /// Get Maps API key with validation
  static String getMapsApiKey() {
    if (!_isInitialized) {
      throw Exception(
          'ApiKeyService not initialized. Call initialize() first.');
    }
    return Environment.mapsApiKey;
  }

  /// Get Firebase API key with validation
  static String getFirebaseApiKey() {
    if (!_isInitialized) {
      throw Exception(
          'ApiKeyService not initialized. Call initialize() first.');
    }
    return Environment.firebaseApiKey;
  }

  /// Check if running in secure environment
  static bool get isSecureEnvironment => Environment.isSecureEnvironment;

  /// Get current environment info for debugging
  static Map<String, dynamic> getEnvironmentInfo() {
    return {
      'isDevelopment': Environment.isDevelopment,
      'isProduction': Environment.isProduction,
      'isSecureEnvironment': isSecureEnvironment,
      'hasMapsKey': Environment.mapsApiKey.isNotEmpty,
      'hasFirebaseKey': Environment.firebaseApiKey.isNotEmpty,
      'mapsKeyLength': Environment.mapsApiKey.length,
      'initialized': _isInitialized,
    };
  }
}
