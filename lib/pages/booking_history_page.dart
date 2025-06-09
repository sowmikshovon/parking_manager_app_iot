import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_time_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/app_constants.dart';
import '../services/error_service.dart';
import '../services/booking_service.dart';
import '../widgets/common_widgets.dart';
import 'qr_scanner_with_bluetooth_page.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  @override
  void initState() {
    super.initState();
    // Check for expired bookings when the page loads
    _checkExpiredBookings();
  }

  // Check and cleanup expired bookings
  Future<void> _checkExpiredBookings() async {
    await ErrorService.executeWithErrorHandling<void>(
      context,
      () async {
        await BookingService.checkAndExpireBookings();
      },
      operationName: 'Check expired bookings',
      showSnackBar: false, // Silent background operation
    );
  }

  // Method to open QR scanner for booked spots in booking history
  void _openQrScannerForBookingHistory(
      BuildContext context, String spotId, String address, String bookingId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrScannerWithBluetoothPage(
          bookingId: bookingId,
          address: address,
        ),
      ),
    );
  }

  // Method to end parking from booking history
  Future<void> _endParkingFromHistory(
    BuildContext context,
    String spotId,
    String bookingId,
  ) async {
    await ErrorService.executeWithErrorHandling(
      context,
      () async {
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
          'status': AppStrings.completedStatus,
          'endTime': Timestamp.now(),
        });

        if (context.mounted) {
          SnackBarUtils.showSuccess(
              context, AppStrings.parkingEndedSuccessfully);
        }      },
      operationName: AppStrings.endParkingOperation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.myBookingHistory)),
        body: Center(
          child: Text(AppStrings.pleaseLogInBookingHistory),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.myBookingHistory)),
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
            return Center(
              child: Text(AppStrings.noBookingHistoryFound),
            );
          }

          return ListView.builder(
            itemCount: bookings.length,            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;
              final address = data['address'] as String? ?? 'No address';
              final spotId = data['spotId'] as String? ?? '';
              final status = data['status'] as String? ?? 'active';
              final startTime = data['startTime'] as Timestamp?;
              final endTime = data['endTime'] as Timestamp?;
              final bookingId = booking.id;
              
              // Check if booking has actually expired (for active bookings)
              bool actuallyExpired = false;
              if (status == 'active') {
                // Check if this is an active booking that should be expired
                // by looking at parking spot's availableUntil time or endTime
                if (endTime != null) {
                  actuallyExpired = endTime.toDate().isBefore(DateTime.now());
                } else {
                  // For bookings without endTime, check spot's availableUntil
                  // This will be handled in a FutureBuilder below
                }
              }
              
              final String displayStatus = actuallyExpired ? 'expired' : status;
              final bool isActive = displayStatus == 'active';
              
              final String startTimeString = startTime != null
                  ? DateTimeUtils.formatDateTime(context, startTime.toDate())
                  : AppStrings.unknown;
              final String endTimeString = endTime != null
                  ? DateTimeUtils.formatDateTime(context, endTime.toDate())
                  : AppStrings.ongoing;              return Card(
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
                          // Use FutureBuilder to check if active booking is actually expired
                          if (status == 'active' && !actuallyExpired)
                            FutureBuilder<DocumentSnapshot>(
                              future: FirebaseFirestore.instance
                                  .collection('parking_spots')
                                  .doc(spotId)
                                  .get(),
                              builder: (context, spotSnapshot) {
                                String finalStatus = displayStatus;
                                
                                if (spotSnapshot.hasData && spotSnapshot.data!.exists) {
                                  final spotData = spotSnapshot.data!.data() as Map<String, dynamic>;
                                  final availableUntilTimestamp = spotData['availableUntil'] as Timestamp?;
                                  
                                  if (availableUntilTimestamp != null) {
                                    final availableUntil = availableUntilTimestamp.toDate();
                                    if (availableUntil.isBefore(DateTime.now())) {
                                      finalStatus = 'expired';
                                      // Trigger expiration check for this booking
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        _checkExpiredBookings();
                                      });
                                    }
                                  }
                                }
                                
                                return StatusChip(status: finalStatus);
                              },
                            )
                          else
                            StatusChip(status: displayStatus),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            AppStrings.startedPrefix + startTimeString,
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
                              AppStrings.endedPrefix + endTimeString,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],                      if (isActive && !actuallyExpired) ...[
                        const SizedBox(height: 16),
                        // Check if booking is still actually active (not expired)
                        FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance
                              .collection('parking_spots')
                              .doc(spotId)
                              .get(),
                          builder: (context, spotSnapshot) {
                            bool shouldShowActions = true;
                            
                            if (spotSnapshot.hasData && spotSnapshot.data!.exists) {
                              final spotData = spotSnapshot.data!.data() as Map<String, dynamic>;
                              final availableUntilTimestamp = spotData['availableUntil'] as Timestamp?;
                              
                              if (availableUntilTimestamp != null) {
                                final availableUntil = availableUntilTimestamp.toDate();
                                shouldShowActions = availableUntil.isAfter(DateTime.now());
                              }
                            }
                            
                            if (!shouldShowActions) {
                              return const SizedBox.shrink();
                            }
                            
                            return Row(
                              children: [
                                Expanded(
                                  child: ActionButton(
                                    label: AppStrings.scanLabel,
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
                                    label: AppStrings.unbookMenuItem,
                                    icon: Icons.stop_circle_outlined,
                                    onPressed: () => _endParkingFromHistory(
                                        context, spotId, bookingId),
                                    backgroundColor: Colors.red.shade600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ActionButton(
                                    label: AppStrings.mapLabel,
                                    icon: Icons.navigation,
                                    onPressed: () {
                                      SnackBarUtils.showCustom(
                                        context,
                                        AppStrings.workInProgress,
                                        backgroundColor: Colors.blueGrey[700],
                                        icon: Icons.construction,
                                      );
                                    },
                                    backgroundColor: Colors.blueGrey,
                                  ),
                                ),
                              ],
                            );
                          },
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
