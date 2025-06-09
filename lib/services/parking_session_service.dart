import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enum for parking session states
enum ParkingSessionState {
  none, // No active session
  entered, // User entered (gate opened once)
  exited, // User exited (gate opened then closed)
  completed, // Complete cycle: open -> close -> open -> close
}

/// Service to track parking session states based on HC-05 gate commands
class ParkingSessionService {
  static const String _sessionKeyPrefix = 'parking_session_';
  static const String _commandCountKeyPrefix = 'command_count_';
  static const String _lastCommandKeyPrefix = 'last_command_';

  /// Track a gate command for a specific booking
  static Future<void> trackGateCommand(String bookingId, String command) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKey = '$_sessionKeyPrefix$bookingId';
    final commandCountKey = '$_commandCountKeyPrefix$bookingId';
    final lastCommandKey = '$_lastCommandKeyPrefix$bookingId';

    // Get command counts
    int openCount = prefs.getInt('${commandCountKey}_open') ?? 0;
    int closeCount = prefs.getInt('${commandCountKey}_close') ?? 0;

    // Update command counts based on received command
    if (command.toUpperCase().contains('OPENED')) {
      openCount++;
      await prefs.setInt('${commandCountKey}_open', openCount);
    } else if (command.toUpperCase().contains('CLOSED')) {
      closeCount++;
      await prefs.setInt('${commandCountKey}_close', closeCount);
    }

    // Update last command
    await prefs.setString(lastCommandKey, command);
    await prefs.setInt(
        '${lastCommandKey}_timestamp', DateTime.now().millisecondsSinceEpoch);

    // Determine new state based on command counts
    ParkingSessionState newState =
        _calculateParkingState(openCount, closeCount);

    // Save new state
    await prefs.setInt(sessionKey, newState.index);

    // If session is completed, mark it for unbooking prompt
    if (newState == ParkingSessionState.completed) {
      await _markSessionForUnbooking(bookingId);
    }
  }

  /// Calculate parking state based on gate command counts
  static ParkingSessionState _calculateParkingState(
      int openCount, int closeCount) {
    if (openCount == 0 && closeCount == 0) {
      return ParkingSessionState.none;
    } else if (openCount == 1 && closeCount == 0) {
      return ParkingSessionState.entered;
    } else if (openCount == 1 && closeCount == 1) {
      return ParkingSessionState.exited;
    } else if (openCount >= 2 && closeCount >= 2) {
      return ParkingSessionState.completed;
    } else {
      // Default to entered if we have at least one open
      return openCount > 0
          ? ParkingSessionState.entered
          : ParkingSessionState.none;
    }
  }

  /// Mark a session as ready for unbooking prompt
  static Future<void> _markSessionForUnbooking(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('unbook_prompt_$bookingId', true);
    await prefs.setInt('unbook_prompt_timestamp_$bookingId',
        DateTime.now().millisecondsSinceEpoch);
  }

  /// Get current parking session state for a booking
  static Future<ParkingSessionState> getParkingSessionState(
      String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKey = '$_sessionKeyPrefix$bookingId';
    final stateIndex = prefs.getInt(sessionKey) ?? 0;
    return ParkingSessionState.values[stateIndex];
  }

  /// Get command counts for a booking
  static Future<Map<String, int>> getCommandCounts(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final commandCountKey = '$_commandCountKeyPrefix$bookingId';

    return {
      'open': prefs.getInt('${commandCountKey}_open') ?? 0,
      'close': prefs.getInt('${commandCountKey}_close') ?? 0,
    };
  }

  /// Get last command for a booking
  static Future<Map<String, dynamic>?> getLastCommand(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final lastCommandKey = '$_lastCommandKeyPrefix$bookingId';

    final command = prefs.getString(lastCommandKey);
    final timestamp = prefs.getInt('${lastCommandKey}_timestamp');

    if (command != null && timestamp != null) {
      return {
        'command': command,
        'timestamp': DateTime.fromMillisecondsSinceEpoch(timestamp),
      };
    }

    return null;
  }

  /// Get all bookings that need unbooking prompts
  static Future<List<String>> getBookingsNeedingUnbookPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final List<String> bookingIds = [];

    for (final key in keys) {
      if (key.startsWith('unbook_prompt_') && !key.contains('_timestamp')) {
        final hasPrompt = prefs.getBool(key) ?? false;
        if (hasPrompt) {
          final bookingId = key.replaceFirst('unbook_prompt_', '');
          bookingIds.add(bookingId);
        }
      }
    }

    return bookingIds;
  }

  /// Clear unbook prompt for a booking (after user responds)
  static Future<void> clearUnbookPrompt(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('unbook_prompt_$bookingId');
    await prefs.remove('unbook_prompt_timestamp_$bookingId');
  }

  /// Clear all session data for a booking (when booking is cancelled/completed)
  static Future<void> clearSessionData(String bookingId) async {
    final prefs = await SharedPreferences.getInstance();
    final sessionKey = '$_sessionKeyPrefix$bookingId';
    final commandCountKey = '$_commandCountKeyPrefix$bookingId';
    final lastCommandKey = '$_lastCommandKeyPrefix$bookingId';

    await prefs.remove(sessionKey);
    await prefs.remove('${commandCountKey}_open');
    await prefs.remove('${commandCountKey}_close');
    await prefs.remove(lastCommandKey);
    await prefs.remove('${lastCommandKey}_timestamp');
    await prefs.remove('unbook_prompt_$bookingId');
    await prefs.remove('unbook_prompt_timestamp_$bookingId');
  }

  /// Get session summary for display
  static Future<Map<String, dynamic>> getSessionSummary(
      String bookingId) async {
    final state = await getParkingSessionState(bookingId);
    final counts = await getCommandCounts(bookingId);
    final lastCommand = await getLastCommand(bookingId);

    return {
      'state': state,
      'openCount': counts['open'],
      'closeCount': counts['close'],
      'lastCommand': lastCommand,
      'stateDescription': _getStateDescription(state),
    };
  }

  /// Get human-readable description of parking state
  static String _getStateDescription(ParkingSessionState state) {
    switch (state) {
      case ParkingSessionState.none:
        return 'No activity';
      case ParkingSessionState.entered:
        return 'Vehicle entered parking';
      case ParkingSessionState.exited:
        return 'Vehicle exited parking';
      case ParkingSessionState.completed:
        return 'Parking session completed';
    }
  }

  /// Check if a booking has an active parking session
  static Future<bool> hasActiveSession(String bookingId) async {
    final state = await getParkingSessionState(bookingId);
    return state != ParkingSessionState.none;
  }

  /// Get all active sessions for current user
  static Future<List<Map<String, dynamic>>> getUserActiveSessions() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // Get user's active bookings
    final bookingsSnapshot = await FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'active')
        .get();

    final List<Map<String, dynamic>> activeSessions = [];

    for (final doc in bookingsSnapshot.docs) {
      final bookingId = doc.id;
      final bookingData = doc.data();

      if (await hasActiveSession(bookingId)) {
        final summary = await getSessionSummary(bookingId);
        activeSessions.add({
          'bookingId': bookingId,
          'bookingData': bookingData,
          'sessionSummary': summary,
        });
      }
    }

    return activeSessions;
  }

  /// Get completed sessions that need unbooking prompts
  static Future<List<String>> getCompletedSessions() async {
    return await getBookingsNeedingUnbookPrompt();
  }

  /// Clear session data (alias for clearSessionData for backward compatibility)
  static Future<void> clearSession(String bookingId) async {
    await clearSessionData(bookingId);
  }
}
