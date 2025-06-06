import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for Firebase operations related to parking spots
class SpotOperationsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Deletes a parking spot by its document ID
  static Future<void> deleteSpot(String spotId) async {
    try {
      await _firestore.collection('parkingSpots').doc(spotId).delete();
    } catch (e) {
      throw Exception('Failed to delete spot: $e');
    }
  }

  /// Checks if a spot has an active booking
  static Future<bool> hasActiveBooking(String spotId) async {
    try {
      final bookingQuery = await _firestore
          .collection('bookings')
          .where('spotId', isEqualTo: spotId)
          .where('status', isEqualTo: 'active')
          .get();

      return bookingQuery.docs.isNotEmpty;
    } catch (e) {
      return false; // Default to false if error occurs
    }
  }

  /// Gets booking details for a specific spot
  static Future<Map<String, dynamic>?> getActiveBookingForSpot(
      String spotId) async {
    try {
      final bookingQuery = await _firestore
          .collection('bookings')
          .where('spotId', isEqualTo: spotId)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (bookingQuery.docs.isNotEmpty) {
        return bookingQuery.docs.first.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Unbooks a parking spot
  static Future<void> unbookSpot(String bookingId) async {
    try {
      await _firestore.collection('bookings').doc(bookingId).update({
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to unbook spot: $e');
    }
  }

  /// Updates spot status
  static Future<void> updateSpotStatus(String spotId, String status) async {
    try {
      await _firestore.collection('parkingSpots').doc(spotId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update spot status: $e');
    }
  }

  /// Gets user's current booking
  static Future<Map<String, dynamic>?> getCurrentUserBooking() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final bookingQuery = await _firestore
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'active')
          .limit(1)
          .get();

      if (bookingQuery.docs.isNotEmpty) {
        final bookingData = bookingQuery.docs.first.data();
        bookingData['id'] = bookingQuery.docs.first.id;
        return bookingData;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Gets user's booking history
  static Stream<QuerySnapshot> getUserBookingHistory() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Gets user's parking spots
  static Stream<QuerySnapshot> getUserParkingSpots() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('parkingSpots')
        .where('ownerId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Gets available parking spots
  static Stream<QuerySnapshot> getAvailableParkingSpots() {
    return _firestore
        .collection('parkingSpots')
        .where('status', whereIn: ['available', 'expired'])
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Books a parking spot
  static Future<String> bookSpot({
    required String spotId,
    required String spotAddress,
    required double hourlyRate,
    required int duration,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final bookingData = {
        'userId': user.uid,
        'spotId': spotId,
        'spotAddress': spotAddress,
        'hourlyRate': hourlyRate,
        'duration': duration,
        'totalCost': hourlyRate * duration,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'startTime': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('bookings').add(bookingData);

      // Update spot status to booked
      await updateSpotStatus(spotId, 'booked');

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to book spot: $e');
    }
  }
}
