import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_time_utils.dart';
import '../utils/snackbar_utils.dart';
import '../widgets/common_widgets.dart';
import 'qr_scanner_page.dart';

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  // Method to open QR scanner for booked spots in booking history
  static void _openQrScannerForBookingHistory(
      BuildContext context, String spotId, String address, String bookingId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrScannerPage(
          expectedSpotId: spotId,
          address: address,
          onSuccess: () {
            // Show success message when QR is successfully scanned
            SnackBarUtils.showSuccess(
                context, 'QR Code verified successfully!');
          },
          onSkip: () {
            // Show message when user skips QR scanning
            SnackBarUtils.showWarning(context, 'QR scanning skipped');
          },
        ),
      ),
    );
  } // Method to end parking from booking history

  static Future<void> _endParkingFromHistory(
    BuildContext context,
    String spotId,
    String bookingId,
  ) async {
    try {
      // Update the parking spot to be available
      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(spotId)
          .update({'isAvailable': true});

      // Update the booking status to completed
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'completed',
        'endTime': Timestamp.now(),
      });

      if (context.mounted) {
        SnackBarUtils.showSuccess(context, 'Parking ended successfully!');
      }
    } catch (e) {
      // If updating spot availability fails, still try to end the booking
      if (e.toString().contains('document does not exist') ||
          e.toString().contains('not found')) {
        // The parking spot document doesn't exist, but we can still end the booking
        try {
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .update({
            'status': 'completed',
            'endTime': Timestamp.now(),
          });

          if (context.mounted) {
            SnackBarUtils.showSuccess(context, 'Parking ended successfully!');
          }
        } catch (updateError) {
          if (context.mounted) {
            SnackBarUtils.showError(
                context, 'Error ending booking: ${updateError.toString()}');
          }
        }
      } else {
        if (context.mounted) {
          SnackBarUtils.showError(
              context, 'Failed to end parking: ${e.toString()}');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Booking History')),
        body: const Center(
          child: Text('Please log in to see your booking history.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Booking History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('startTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final bookings = snapshot.data?.docs ?? [];
          if (bookings.isEmpty) {
            return const Center(
              child: Text('No booking history found.'),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;
              final address = data['address'] as String? ?? 'No address';
              final spotId = data['spotId'] as String? ?? '';
              final status = data['status'] as String? ?? 'active';
              final startTime = data['startTime'] as Timestamp?;
              final endTime = data['endTime'] as Timestamp?;
              final bookingId = booking.id;
              final bool isActive = status == 'active';
              final String startTimeString = startTime != null
                  ? DateTimeUtils.formatDateTime(context, startTime.toDate())
                  : 'Unknown';
              final String endTimeString = endTime != null
                  ? DateTimeUtils.formatDateTime(context, endTime.toDate())
                  : 'Ongoing';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          StatusChip(
                            status: isActive ? 'active' : status,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Started: $startTimeString',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (!isActive) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Ended: $endTimeString',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                      if (isActive) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ActionButton(
                                label: "Scan",
                                icon: Icons.qr_code_scanner,
                                onPressed: () =>
                                    _openQrScannerForBookingHistory(
                                        context, spotId, address, bookingId),
                                backgroundColor: Colors.teal.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ActionButton(
                                label: 'Unbook',
                                icon: Icons.stop_circle_outlined,
                                onPressed: () => _endParkingFromHistory(
                                    context, spotId, bookingId),
                                backgroundColor: Colors.red.shade600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ActionButton(
                                label: 'Map',
                                icon: Icons.navigation,
                                onPressed: () {
                                  SnackBarUtils.showCustom(
                                    context,
                                    'Work in progress',
                                    backgroundColor: Colors.blueGrey[700],
                                    icon: Icons.construction,
                                  );
                                },
                                backgroundColor: Colors.blueGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
