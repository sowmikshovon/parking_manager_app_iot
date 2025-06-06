import 'package:flutter/material.dart';

/// Utility class for consistent SnackBar messaging across the app
class SnackBarUtils {
  /// Shows a success SnackBar with green background and check icon
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows an error SnackBar with red background and error icon
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a warning SnackBar with orange background and warning icon
  static void showWarning(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows an info SnackBar with blue background and info icon
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Shows a custom SnackBar with specified background color and icon
  static void showCustom(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Color iconColor = Colors.white,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor ?? Colors.grey[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(16),
        duration: duration,
        action: action,
      ),
    );
  }

  /// Shows a location error SnackBar with appropriate message based on error type
  static void showLocationError(BuildContext context, Object error) {
    final errorString = error.toString();
    String message;

    if (errorString.contains('No location permissions') ||
        errorString.contains('permissions')) {
      message =
          'Location permission required. Please enable location access in Settings.';
    } else if (errorString.contains('Location services') ||
        errorString.contains('disabled')) {
      message =
          'Location services are disabled. Please enable them in Settings.';
    } else if (errorString.contains('timeout') ||
        errorString.contains('TimeoutException')) {
      message = 'Location request timed out. Please try again.';
    } else {
      message = 'Could not get your location.';
    }

    showError(context, message);
  }

  /// Shows a Firebase auth error SnackBar with user-friendly message
  static void showAuthError(BuildContext context, String errorCode,
      [String? message]) {
    String userMessage;

    switch (errorCode) {
      case 'user-not-found':
        userMessage = 'No account found with this email address.';
        break;
      case 'wrong-password':
        userMessage = 'Incorrect password. Please try again.';
        break;
      case 'email-already-in-use':
        userMessage = 'An account already exists with this email address.';
        break;
      case 'weak-password':
        userMessage =
            'Password is too weak. Please choose a stronger password.';
        break;
      case 'invalid-email':
        userMessage = 'Please enter a valid email address.';
        break;
      case 'network-request-failed':
        userMessage = 'Network error. Please check your internet connection.';
        break;
      default:
        userMessage = message ?? 'Authentication failed. Please try again.';
    }

    showError(context, userMessage);
  }
}
