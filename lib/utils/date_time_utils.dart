import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Utility class for consistent date and time formatting across the app
class DateTimeUtils {
  /// Formats a DateTime to string based on device's 24-hour format preference
  /// Returns format like "12/25/2023 2:30 PM" or "25/12/2023 14:30"
  static String formatDateTime(BuildContext context, DateTime dateTime) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool is24HourFormat = mediaQuery.alwaysUse24HourFormat;

    final String date = DateFormat.yMd().format(dateTime);
    final String time = is24HourFormat
        ? DateFormat('HH:mm').format(dateTime) // 24-hour format (14:30)
        : DateFormat('h:mm a').format(dateTime); // 12-hour format (2:30 PM)
    return '$date $time';
  }

  /// Formats just the time portion based on device's 24-hour format preference
  /// Returns format like "2:30 PM" or "14:30"
  static String formatTime(BuildContext context, DateTime dateTime) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool is24HourFormat = mediaQuery.alwaysUse24HourFormat;
    
    return is24HourFormat
        ? DateFormat('HH:mm').format(dateTime) // 24-hour format (14:30)
        : DateFormat('h:mm a').format(dateTime); // 12-hour format (2:30 PM)
  }

  /// Formats just the date portion
  /// Returns format like "12/25/2023"
  static String formatDate(DateTime dateTime) {
    return DateFormat.yMd().format(dateTime);
  }

  /// Calculates and formats the remaining time until expiration
  /// Returns format like "2h 30m remaining" or "Expired"
  static String calculateRemainingTime(DateTime endTime) {
    final now = DateTime.now();
    final remaining = endTime.difference(now);
    
    if (remaining.isNegative) return 'Expired';
    
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m remaining';
    } else if (minutes > 0) {
      return '${minutes}m remaining';
    } else {
      return 'Less than 1m remaining';
    }
  }

  /// Checks if a DateTime is expired (in the past)
  static bool isExpired(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }

  /// Checks if a DateTime is in the future by at least the specified minutes
  static bool isFutureByMinutes(DateTime dateTime, int minimumMinutes) {
    return dateTime.isAfter(DateTime.now().add(Duration(minutes: minimumMinutes)));
  }

  /// Creates a DateTime for the start of today
  static DateTime get startOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// Creates a DateTime for the end of today
  static DateTime get endOfToday {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  /// Combines a date and time into a single DateTime object
  static DateTime combineDateTime(DateTime date, TimeOfDay time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
  }
}
