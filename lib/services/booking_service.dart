/// Business logic service for booking operations
/// Handles all booking-related operations including creation, updates, and queries
library;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/data_models.dart';
import '../utils/app_constants.dart';

/// Service class for managing parking spot bookings
class BookingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Collection references
  static CollectionReference get _bookingsCollection =>
      _firestore.collection(AppConfig.bookingsCollection);
  static CollectionReference get _spotsCollection =>
      _firestore.collection(AppConfig.spotsCollection);

  /// Create a new booking
  static Future<String> createBooking({
    required String spotId,
    required DateTime startTime,
    required DateTime endTime,
    required double totalCost,
    String? notes,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    // Create booking data
    final booking = Booking(
      id: '', // Will be set by Firestore
      userId: user.uid,
      userEmail: user.email ?? '',
      spotId: spotId,
      startTime: startTime,
      endTime: endTime,
      totalCost: totalCost,
      status: BookingStatus.active,
      createdAt: DateTime.now(),
      notes: notes,
    );

    // Add booking to Firestore
    final docRef = await _bookingsCollection.add(booking.toMap());

    // Update the spot status
    await _spotsCollection.doc(spotId).update({
      'status': SpotStatus.occupied.name,
      'currentBookingId': docRef.id,
      'occupiedUntil': Timestamp.fromDate(endTime),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });

    return docRef.id;
  }

  /// Get booking by ID
  static Future<Booking?> getBookingById(String bookingId) async {
    try {
      final doc = await _bookingsCollection.doc(bookingId).get();
      if (doc.exists) {
        return Booking.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  /// Get all bookings for current user
  static Future<List<Booking>> getUserBookings({
    BookingStatus? status,
    int? limit,
    DocumentSnapshot? startAfter,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      Query query = _bookingsCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  /// Get active bookings for current user
  static Future<List<Booking>> getActiveBookings() async {
    return getUserBookings(status: BookingStatus.active);
  }

  /// Get booking history for current user
  static Future<List<Booking>> getBookingHistory() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      final querySnapshot = await _bookingsCollection
          .where('userId', isEqualTo: user.uid)
          .where('status', whereIn: [
            BookingStatus.completed.name,
            BookingStatus.cancelled.name,
            BookingStatus.expired.name,
          ])
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get booking history: $e');
    }
  }

  /// Update booking status
  static Future<void> updateBookingStatus(
    String bookingId,
    BookingStatus newStatus,
  ) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'status': newStatus.name,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // If completing or cancelling booking, update spot status
      if (newStatus == BookingStatus.completed ||
          newStatus == BookingStatus.cancelled) {
        final booking = await getBookingById(bookingId);
        if (booking != null) {
          await _spotsCollection.doc(booking.spotId).update({
            'status': SpotStatus.available.name,
            'currentBookingId': null,
            'occupiedUntil': null,
            'updatedAt': Timestamp.fromDate(DateTime.now()),
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  /// Complete a booking
  static Future<void> completeBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.completed);
  }

  /// Cancel a booking
  static Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, BookingStatus.cancelled);
  }

  /// Verify booking with QR code
  static Future<void> verifyBooking(String bookingId) async {
    try {
      await _bookingsCollection.doc(bookingId).update({
        'isVerified': true,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to verify booking: $e');
    }
  }

  /// Extend booking duration
  static Future<void> extendBooking(
    String bookingId,
    DateTime newEndTime,
    double additionalCost,
  ) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      final newTotalCost = booking.totalCost + additionalCost;

      await _bookingsCollection.doc(bookingId).update({
        'endTime': Timestamp.fromDate(newEndTime),
        'totalCost': newTotalCost,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      // Update spot's occupied until time
      await _spotsCollection.doc(booking.spotId).update({
        'occupiedUntil': Timestamp.fromDate(newEndTime),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Failed to extend booking: $e');
    }
  }

  /// Calculate booking cost
  static double calculateBookingCost({
    required double hourlyRate,
    required DateTime startTime,
    required DateTime endTime,
  }) {
    final duration = endTime.difference(startTime);
    final hours = duration.inMinutes / 60.0;
    return hours * hourlyRate;
  }

  /// Check if user has any active bookings
  static Future<bool> hasActiveBookings() async {
    final activeBookings = await getActiveBookings();
    return activeBookings.isNotEmpty;
  }

  /// Get current active booking for user
  static Future<Booking?> getCurrentActiveBooking() async {
    final activeBookings = await getActiveBookings();
    if (activeBookings.isEmpty) return null;

    // Return the most recent active booking
    for (final booking in activeBookings) {
      if (booking.isCurrentlyActive) {
        return booking;
      }
    }
    return null;
  }

  /// Mark expired bookings
  static Future<void> markExpiredBookings() async {
    try {
      final now = DateTime.now();
      final expiredBookingsQuery = await _bookingsCollection
          .where('status', isEqualTo: BookingStatus.active.name)
          .where('endTime', isLessThan: Timestamp.fromDate(now))
          .get();

      final batch = _firestore.batch();
      final List<String> expiredSpotIds = [];

      for (final doc in expiredBookingsQuery.docs) {
        final booking = Booking.fromFirestore(doc);

        // Mark booking as expired
        batch.update(doc.reference, {
          'status': BookingStatus.expired.name,
          'updatedAt': Timestamp.fromDate(now),
        });

        expiredSpotIds.add(booking.spotId);
      }

      // Mark associated spots as expired
      for (final spotId in expiredSpotIds) {
        batch.update(_spotsCollection.doc(spotId), {
          'status': SpotStatus.expired.name,
          'updatedAt': Timestamp.fromDate(now),
        });
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark expired bookings: $e');
    }
  }

  /// Get bookings for a specific spot
  static Future<List<Booking>> getSpotBookings(
    String spotId, {
    BookingStatus? status,
    int? limit,
  }) async {
    try {
      Query query = _bookingsCollection
          .where('spotId', isEqualTo: spotId)
          .orderBy('createdAt', descending: true);

      if (status != null) {
        query = query.where('status', isEqualTo: status.name);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => Booking.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get spot bookings: $e');
    }
  }

  /// Get bookings with spot details populated
  static Future<List<Booking>> getBookingsWithSpotDetails(
    List<Booking> bookings,
  ) async {
    try {
      final List<Booking> populatedBookings = [];

      for (final booking in bookings) {
        final spotDoc = await _spotsCollection.doc(booking.spotId).get();
        if (spotDoc.exists) {
          final spot = ParkingSpot.fromFirestore(spotDoc);
          final populatedBooking = booking.copyWith(spot: spot);
          populatedBookings.add(populatedBooking);
        } else {
          populatedBookings.add(booking);
        }
      }

      return populatedBookings;
    } catch (e) {
      throw Exception('Failed to populate booking spot details: $e');
    }
  }

  /// Stream of user's bookings
  static Stream<List<Booking>> streamUserBookings({
    BookingStatus? status,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.error('User not authenticated');
    }

    Query query = _bookingsCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true);

    if (status != null) {
      query = query.where('status', isEqualTo: status.name);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Booking.fromFirestore(doc)).toList();
    });
  }

  /// Stream of active bookings
  static Stream<List<Booking>> streamActiveBookings() {
    return streamUserBookings(status: BookingStatus.active);
  }

  /// Delete a booking (admin only or cancellation)
  static Future<void> deleteBooking(String bookingId) async {
    try {
      final booking = await getBookingById(bookingId);
      if (booking == null) {
        throw Exception('Booking not found');
      }

      // Update spot status if booking was active
      if (booking.status == BookingStatus.active) {
        await _spotsCollection.doc(booking.spotId).update({
          'status': SpotStatus.available.name,
          'currentBookingId': null,
          'occupiedUntil': null,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      // Delete the booking
      await _bookingsCollection.doc(bookingId).delete();
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }
}
