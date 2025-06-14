import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

// ExpiredSpotTracker class for background tracking of expired parking spots
class ExpiredSpotTracker {
  static Timer? _globalTimer;
  static bool _isRunning = false;

  // Start global background tracking
  static void startGlobalTracking() {
    if (_isRunning) return; // Already running

    _isRunning = true;
    _globalTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      checkAndUpdateExpiredSpots();
    });

    // Also run an immediate check
    checkAndUpdateExpiredSpots();
  }

  // Stop global tracking
  static void stopGlobalTracking() {
    _globalTimer?.cancel();
    _globalTimer = null;
    _isRunning = false;
  }

  // Method to check and update expired spots
  static Future<void> checkAndUpdateExpiredSpots() async {
    try {
      final now = DateTime.now();
      final QuerySnapshot expiredSpots = await FirebaseFirestore.instance
          .collection('parking_spots')
          .where('isAvailable', isEqualTo: true)
          .where('availableUntil', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      // Batch update expired spots to be unavailable
      if (expiredSpots.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (QueryDocumentSnapshot spot in expiredSpots.docs) {
          batch.update(spot.reference, {'isAvailable': false});
        }
        await batch.commit(); // Debug logging disabled in production
      }
    } catch (e) {
      // Debug logging disabled in production
    }
  }
}
