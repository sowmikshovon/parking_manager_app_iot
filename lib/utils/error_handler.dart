/// Error handling utilities for the IoT parking application
/// Provides standardized error handling, logging, and user-friendly error messages
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_constants.dart';

/// Custom exception classes for better error categorization
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(this.message, {this.code, this.originalError});

  @override
  String toString() => 'AppException: $message';
}

class AuthenticationException extends AppException {
  const AuthenticationException(super.message,
      {super.code, super.originalError});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.originalError});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.originalError});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.originalError});
}

class DataException extends AppException {
  const DataException(super.message, {super.code, super.originalError});
}

/// Error handling utility class
class ErrorHandler {
  /// Log error for debugging (only in debug mode)
  static void logError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    if (kDebugMode) {
      print('🔴 Error in $context: $error');
      if (stackTrace != null) {
        print('Stack trace: $stackTrace');
      }
      if (additionalData != null) {
        print('Additional data: $additionalData');
      }
    }

    // In production, you might want to send errors to a crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
  }

  /// Convert Firebase Auth errors to user-friendly messages
  static String getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return AuthErrorMessages.userNotFound;
      case 'wrong-password':
        return AuthErrorMessages.wrongPassword;
      case 'email-already-in-use':
        return AuthErrorMessages.emailAlreadyInUse;
      case 'weak-password':
        return AuthErrorMessages.weakPassword;
      case 'invalid-email':
        return AuthErrorMessages.invalidEmail;
      case 'user-disabled':
        return AuthErrorMessages.userDisabled;
      case 'too-many-requests':
        return AuthErrorMessages.tooManyRequests;
      case 'operation-not-allowed':
        return AuthErrorMessages.operationNotAllowed;
      case 'invalid-credential':
        return AuthErrorMessages.invalidCredential;
      case 'network-request-failed':
        return AuthErrorMessages.networkRequestFailed;
      case 'requires-recent-login':
        return AuthErrorMessages.requiresRecentLogin;
      default:
        return '${AuthErrorMessages.defaultAuthError}: ${error.message ?? 'Unknown error'}';
    }
  }

  /// Convert Firestore errors to user-friendly messages
  static String getFirestoreErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return DatabaseErrorMessages.permissionDenied;
      case 'unavailable':
        return DatabaseErrorMessages.unavailable;
      case 'not-found':
        return DatabaseErrorMessages.notFound;
      case 'already-exists':
        return DatabaseErrorMessages.alreadyExists;
      case 'resource-exhausted':
        return DatabaseErrorMessages.resourceExhausted;
      case 'failed-precondition':
        return DatabaseErrorMessages.failedPrecondition;
      case 'aborted':
        return DatabaseErrorMessages.aborted;
      case 'out-of-range':
        return DatabaseErrorMessages.outOfRange;
      case 'unimplemented':
        return DatabaseErrorMessages.unimplemented;
      case 'internal':
        return DatabaseErrorMessages.internal;
      case 'deadline-exceeded':
        return DatabaseErrorMessages.deadlineExceeded;
      case 'unauthenticated':
        return DatabaseErrorMessages.unauthenticated;
      default:
        return '${DatabaseErrorMessages.defaultDatabaseError}: ${error.message ?? 'Unknown error'}';
    }
  }

  /// Convert generic errors to user-friendly messages
  static String getGenericErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return getFirestoreErrorMessage(error);
    } else if (error is AppException) {
      return error.message;
    } else if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Handle errors with logging and return user-friendly message
  static String handleError(
    String context,
    dynamic error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? additionalData,
  }) {
    logError(context, error,
        stackTrace: stackTrace, additionalData: additionalData);
    return getGenericErrorMessage(error);
  }

  /// Validate and throw appropriate exceptions
  static void validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      throw const ValidationException('Email is required');
    }

    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      throw const ValidationException('Please enter a valid email address');
    }
  }

  static void validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      throw const ValidationException('Password is required');
    }

    if (password.length < 6) {
      throw const ValidationException(
          'Password must be at least 6 characters long');
    }
  }

  static void validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      throw ValidationException('$fieldName is required');
    }
  }

  static void validatePositiveNumber(double? value, String fieldName) {
    if (value == null || value <= 0) {
      throw ValidationException('$fieldName must be a positive number');
    }
  }

  /// Network connectivity check helper
  static bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'network-request-failed' ||
          error.code == 'deadline-exceeded';
    }
    return false;
  }

  /// Permission error check helper
  static bool isPermissionError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
          error.code == 'unauthenticated';
    }
    return false;
  }

  /// Check if error requires user re-authentication
  static bool requiresReAuthentication(dynamic error) {
    if (error is FirebaseAuthException) {
      return error.code == 'requires-recent-login';
    }
    return false;
  }
}

/// Result wrapper for operations that might fail
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  const Result.success(this.data)
      : error = null,
        isSuccess = true;
  const Result.error(this.error)
      : data = null,
        isSuccess = false;

  /// Execute a function and wrap result
  static Future<Result<T>> execute<T>(Future<T> Function() operation) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (error, stackTrace) {
      final errorMessage = ErrorHandler.handleError(
        'Result.execute',
        error,
        stackTrace: stackTrace,
      );
      return Result.error(errorMessage);
    }
  }

  /// Execute a function and wrap result with custom error handling
  static Future<Result<T>> executeWithCustomError<T>(
    Future<T> Function() operation,
    String Function(dynamic error) errorHandler,
  ) async {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (error, stackTrace) {
      ErrorHandler.logError('Result.executeWithCustomError', error,
          stackTrace: stackTrace);
      final errorMessage = errorHandler(error);
      return Result.error(errorMessage);
    }
  }
}

/// Async operation wrapper with retry logic
class AsyncOperation {
  /// Execute operation with retry logic
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempts++;

        if (attempts >= maxRetries) {
          rethrow;
        }

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }

        // Don't retry permission errors or validation errors
        if (ErrorHandler.isPermissionError(error) ||
            error is ValidationException) {
          rethrow;
        }

        ErrorHandler.logError(
          'AsyncOperation.withRetry',
          error,
          additionalData: {'attempt': attempts, 'maxRetries': maxRetries},
        );

        await Future.delayed(delay * attempts);
      }
    }

    throw Exception('Operation failed after $maxRetries attempts');
  }

  /// Execute operation with timeout
  static Future<T> withTimeout<T>(
    Future<T> Function() operation, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      return await operation().timeout(timeout);
    } catch (error) {
      if (error is TimeoutException) {
        throw const NetworkException('Operation timed out. Please try again.');
      }
      rethrow;
    }
  }

  /// Execute operation with both retry and timeout
  static Future<T> withRetryAndTimeout<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    Duration timeout = const Duration(seconds: 30),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    return withRetry(
      () => withTimeout(operation, timeout: timeout),
      maxRetries: maxRetries,
      delay: delay,
      shouldRetry: shouldRetry,
    );
  }
}

/// Error boundary for widgets (conceptual - would need custom implementation)
class ErrorBoundary {
  /// Standard error messages for common scenarios
  static const String noInternetConnection =
      'No internet connection. Please check your network settings.';
  static const String serverError = 'Server error. Please try again later.';
  static const String notFound = 'The requested item was not found.';
  static const String unauthorized =
      'You are not authorized to perform this action.';
  static const String validationFailed =
      'Please check your input and try again.';
  static const String unknownError =
      'An unexpected error occurred. Please try again.';

  /// Get appropriate error message for common scenarios
  static String getStandardMessage(String errorType) {
    switch (errorType.toLowerCase()) {
      case 'network':
        return noInternetConnection;
      case 'server':
        return serverError;
      case 'notfound':
        return notFound;
      case 'unauthorized':
        return unauthorized;
      case 'validation':
        return validationFailed;
      default:
        return unknownError;
    }
  }
}
