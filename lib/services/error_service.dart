import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/error_handler.dart';
import '../utils/snackbar_utils.dart';
import '../utils/app_constants.dart';
import '../widgets/common_widgets.dart';

/// Centralized error handling service for the IoT parking application
/// Provides consistent error handling, user feedback, and error logging
class ErrorService {
  /// Handle Firebase authentication errors with user feedback
  static void handleAuthError(
    BuildContext context,
    dynamic error, {
    String operation = ErrorStrings.authenticationOperation,
    bool showSnackBar = true,
    bool showDialog = false,
  }) {
    final errorMessage = ErrorHandler.handleError(operation, error);

    if (showDialog) {
      ErrorDialog.show(
        context,
        title: ErrorStrings.authenticationError,
        content: errorMessage,
      );
    } else if (showSnackBar) {
      if (error is FirebaseAuthException) {
        SnackBarUtils.showAuthError(context, error.code, errorMessage);
      } else {
        SnackBarUtils.showError(context, errorMessage);
      }
    }
  }

  /// Handle Firestore database errors with user feedback
  static void handleFirestoreError(
    BuildContext context,
    dynamic error, {
    String operation = ErrorStrings.databaseOperation,
    bool showSnackBar = true,
    bool showDialog = false,
  }) {
    final errorMessage = ErrorHandler.handleError(operation, error);

    if (showDialog) {
      ErrorDialog.show(
        context,
        title: ErrorStrings.databaseError,
        content: errorMessage,
      );
    } else if (showSnackBar) {
      SnackBarUtils.showError(context, errorMessage);
    }
  }

  /// Handle location-related errors with user feedback
  static void handleLocationError(
    BuildContext context,
    dynamic error, {
    String operation = ErrorStrings.locationAccessOperation,
    bool showSnackBar = true,
    bool showDialog = false,
  }) {
    ErrorHandler.logError(operation, error);

    if (showDialog) {
      String errorMessage = _getLocationErrorMessage(error);
      ErrorDialog.show(
        context,
        title: ErrorStrings.locationError,
        content: errorMessage,
      );
    } else if (showSnackBar) {
      SnackBarUtils.showLocationError(context, error);
    }
  }

  /// Handle generic errors with user feedback
  static void handleGenericError(
    BuildContext context,
    dynamic error, {
    String operation = ErrorStrings.operation,
    bool showSnackBar = true,
    bool showDialog = false,
    Map<String, dynamic>? additionalData,
  }) {
    final errorMessage = ErrorHandler.handleError(
      operation,
      error,
      additionalData: additionalData,
    );

    if (showDialog) {
      ErrorDialog.show(
        context,
        title: ErrorStrings.error,
        content: errorMessage,
      );
    } else if (showSnackBar) {
      SnackBarUtils.showError(context, errorMessage);
    }
  }

  /// Handle network errors with user feedback and retry option
  static void handleNetworkError(
    BuildContext context,
    dynamic error, {
    String operation = ErrorStrings.networkRequestOperation,
    VoidCallback? onRetry,
    bool showSnackBar = true,
    bool showDialog = false,
  }) {
    final errorMessage = ErrorHandler.handleError(operation, error);

    if (showDialog) {
      ErrorDialog.show(
        context,
        title: ErrorStrings.networkError,
        content: errorMessage,
      );
    } else if (showSnackBar) {
      SnackBarUtils.showCustom(
        context,
        errorMessage,
        backgroundColor: Colors.red,
        icon: Icons.error,
        action: onRetry != null
            ? SnackBarAction(
                label: AppStrings.retry,
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
      );
    }
  }

  /// Handle booking-related errors specifically
  static void handleBookingError(
    BuildContext context,
    dynamic error, {
    String operation = ErrorStrings.bookingOperation,
    bool showSnackBar = true,
  }) {
    String errorMessage;

    if (error.toString().contains(ErrorStrings.documentNotExist) ||
        error.toString().contains(ErrorStrings.notFound)) {
      errorMessage = ErrorStrings.spotNoLongerAvailable;
    } else if (error.toString().contains(ErrorStrings.permissionDenied)) {
      errorMessage = ErrorStrings.noPermissionAction;
    } else if (error.toString().contains(ErrorStrings.unavailable)) {
      errorMessage = ErrorStrings.serviceUnavailable;
    } else {
      errorMessage = ErrorHandler.handleError(operation, error);
    }

    if (showSnackBar) {
      SnackBarUtils.showError(context, errorMessage);
    }
  }

  /// Handle spot listing errors specifically
  static void handleSpotListingError(
    BuildContext context,
    dynamic error, {
    String operation = ErrorStrings.spotListingOperation,
    bool showSnackBar = true,
  }) {
    String errorMessage;

    if (error.toString().contains(ErrorStrings.unauthenticated)) {
      errorMessage = ErrorStrings.mustBeLoggedIn;
    } else if (error.toString().contains(ErrorStrings.permissionDenied)) {
      errorMessage = ErrorStrings.noPermissionListSpots;
    } else {
      errorMessage = ErrorHandler.handleError(operation, error);
    }

    if (showSnackBar) {
      SnackBarUtils.showError(context, errorMessage);
    }
  }

  /// Execute an operation with error handling
  static Future<T?> executeWithErrorHandling<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String operationName = ErrorStrings.operation,
    bool showSnackBar = true,
    bool showDialog = false,
    VoidCallback? onRetry,
  }) async {
    try {
      return await operation();
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        handleAuthError(
          context,
          e,
          operation: operationName,
          showSnackBar: showSnackBar,
          showDialog: showDialog,
        );
      }
      return null;
    } on FirebaseException catch (e) {
      if (context.mounted) {
        handleFirestoreError(
          context,
          e,
          operation: operationName,
          showSnackBar: showSnackBar,
          showDialog: showDialog,
        );
      }
      return null;
    } catch (e) {
      if (context.mounted) {
        if (e.toString().contains(ErrorStrings.location) ||
            e.toString().contains(ErrorStrings.locationCapitalized) ||
            e.toString().contains(ErrorStrings.permission)) {
          handleLocationError(
            context,
            e,
            operation: operationName,
            showSnackBar: showSnackBar,
            showDialog: showDialog,
          );
        } else if (e.toString().contains(ErrorStrings.network) ||
            e.toString().contains(ErrorStrings.timeout) ||
            e.toString().contains(ErrorStrings.connection)) {
          handleNetworkError(
            context,
            e,
            operation: operationName,
            onRetry: onRetry,
            showSnackBar: showSnackBar,
            showDialog: showDialog,
          );
        } else {
          handleGenericError(
            context,
            e,
            operation: operationName,
            showSnackBar: showSnackBar,
            showDialog: showDialog,
          );
        }
      }
      return null;
    }
  }

  /// Execute an operation with retry logic and error handling
  static Future<T?> executeWithRetry<T>(
    BuildContext context,
    Future<T> Function() operation, {
    String operationName = ErrorStrings.defaultRetryOperation,
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool showSnackBar = true,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    try {
      return await AsyncOperation.withRetry(
        operation,
        maxRetries: maxRetries,
        delay: delay,
        shouldRetry: shouldRetry,
      );
    } catch (e) {
      if (context.mounted) {
        handleGenericError(
          context,
          e,
          operation: operationName,
          showSnackBar: showSnackBar,
        );
      }
      return null;
    }
  }

  /// Get location-specific error message
  static String _getLocationErrorMessage(dynamic error) {
    final errorString = error.toString();

    if (errorString.contains(ErrorStrings.noLocationPermissions) ||
        errorString.contains(ErrorStrings.permissions)) {
      return ErrorStrings.locationPermissionRequired;
    } else if (errorString.contains(ErrorStrings.locationServices) ||
        errorString.contains(ErrorStrings.disabled)) {
      return ErrorStrings.locationServicesDisabled;
    } else if (errorString.contains(ErrorStrings.timeout) ||
        errorString.contains(ErrorStrings.timeoutException)) {
      return ErrorStrings.locationRequestTimeout;
    } else {
      return ErrorStrings.couldNotGetLocation;
    }
  }

  /// Validate user input and throw appropriate exceptions
  static void validateUserInput({
    String? email,
    String? password,
    String? address,
    DateTime? selectedDateTime,
  }) {
    if (email != null) {
      ErrorHandler.validateEmail(email);
    }

    if (password != null) {
      ErrorHandler.validatePassword(password);
    }
    if (address != null && address.trim().isEmpty) {
      throw const ValidationException(ErrorStrings.addressRequired);
    }

    if (selectedDateTime != null && selectedDateTime.isBefore(DateTime.now())) {
      throw const ValidationException(ErrorStrings.futureDateTimeRequired);
    }
  }

  /// Handle validation errors with user feedback
  static void handleValidationError(
    BuildContext context,
    ValidationException error, {
    bool showSnackBar = true,
  }) {
    if (showSnackBar) {
      SnackBarUtils.showWarning(context, error.message);
    }
  }

  /// Log error for debugging (wrapper around ErrorHandler.logError)
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    ErrorHandler.logError(
      context,
      error,
      stackTrace: stackTrace,
      additionalData: additionalData,
    );
  }
}
