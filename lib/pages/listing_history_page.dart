import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_time_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/app_constants.dart';
import '../services/error_service.dart';
import 'qr_code_page.dart';
import '../services/dialog_service.dart';

class ListingHistoryPage extends StatelessWidget {
  const ListingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(AppStrings.myListedSpots)),
        body: Center(
          child: Text(AppStrings.pleaseLogInListedSpots),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.myListedSpots)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_spots')
            .where('ownerId', isEqualTo: user.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }          if (snapshot.hasError) {
            return Center(child: Text('${AppStrings.errorLoading}${snapshot.error}'));
          }
          final spots = snapshot.data?.docs ?? [];
          if (spots.isEmpty) {
            return Center(child: Text(AppStrings.noListedSpots));
          }
          return ListView.builder(
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              final data = spot.data() as Map<String, dynamic>;              final address = data['address'] as String? ?? AppStrings.noAddress;
              final spotId = spot.id;
              final isAvailable = data['isAvailable'] ==
                  true; // Check availability status based on time
              final availableUntilTimestamp =
                  data['availableUntil'] as Timestamp?;
              final DateTime? availableUntil =
                  availableUntilTimestamp?.toDate();
              final bool isTimeExpired = availableUntil != null &&
                  availableUntil.isBefore(DateTime.now());

              // Default status
              String statusText = AppStrings.available;
              Color statusColor = Colors.green;

              if (!isAvailable) {
                // Need to check if it's actually booked or just expired
                // This will be handled by the StreamBuilder below
                statusText = AppStrings.checking;
                statusColor = Colors.grey;
              } else if (isTimeExpired) {
                statusText = AppStrings.timeFinished;
                statusColor = Colors.red;
              }

              return Card(
                child: ListTile(
                  title: Text(address),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,                    children: [
                      Text('${AppStrings.spotIdPrefix}$spotId'),
                      Row(
                        children: [
                          Text(AppStrings.statusPrefix),
                          if (isTimeExpired)
                            // Show expired status for time-expired spots
                            Text(
                              AppStrings.expired,
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          else if (!isAvailable)
                            // Use StreamBuilder to check for active bookings (only for non-expired unavailable spots)
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('bookings')
                                  .where('spotId', isEqualTo: spotId)
                                  .where('status', isEqualTo: 'active')
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, bookingSnapshot) {                                if (bookingSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                    AppStrings.checking,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }

                                final hasActiveBooking =
                                    bookingSnapshot.hasData &&
                                        bookingSnapshot.data!.docs.isNotEmpty;

                                if (hasActiveBooking) {
                                  return Text(
                                    AppStrings.booked,
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                } else {
                                  return Text(
                                    AppStrings.expired,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                              },
                            )
                          else
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),                      if (availableUntil != null)
                        Text(
                          '${AppStrings.availableUntilPrefix}${DateTimeUtils.formatDateTime(context, availableUntil)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [                      // Re-enable button for expired spots (show for all expired spots, regardless of isAvailable status)
                      if (isTimeExpired)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.green),
                          tooltip: AppStrings.reEnable,
                          onPressed: () =>
                              _showReEnableDialog(context, spotId, address),
                        ),
                      // Edit button - only available for non-expired spots (available or booked)
                      if (!isTimeExpired)
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          tooltip: AppStrings.editAvailabilityLabel,
                          onPressed: () async {
                            // Check for active booking before showing dialog
                            final activeBooking = await FirebaseFirestore.instance
                                .collection('bookings')
                                .where('spotId', isEqualTo: spotId)
                                .where('status', isEqualTo: 'active')
                                .limit(1)
                                .get();
                            final bool hasActiveBooking = activeBooking.docs.isNotEmpty;
                            
                            if (context.mounted) {
                              _showEditAvailabilityDialog(context,
                                  spotId, availableUntil, isAvailable, address, hasActiveBooking);
                            }
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.teal),
                        tooltip: AppStrings.showQrLabel,
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  QrCodePage(spotId: spotId, address: address),
                            ),
                          );
                        },
                      ),                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: AppStrings.deleteLabel,
                        onPressed: () async {
                          // Check for active booking before showing confirm dialog
                          final activeBooking = await FirebaseFirestore.instance
                              .collection('bookings')
                              .where('spotId', isEqualTo: spotId)
                              .where('status', isEqualTo: 'active')
                              .limit(1)
                              .get();
                          final bool isBooked = activeBooking.docs.isNotEmpty;                          final confirm =
                              await DialogService.showDeleteWarningDialog(
                            context: context,
                            title: AppStrings.deleteSpotTitle,
                            address: address,
                            hasActiveBooking: isBooked,
                          );
                          
                          if (confirm == true && context.mounted) {
                            await ErrorService.executeWithErrorHandling(
                              context,
                              () async {
                                await FirebaseFirestore.instance
                                    .collection('parking_spots')
                                    .doc(spotId)
                                    .delete();
                                
                                if (context.mounted) {
                                  SnackBarUtils.showSuccess(
                                      context, AppStrings.spotDeletedSuccessfully);
                                }
                              },
                              operationName: ErrorStrings.deleteParkingSpotOperation,
                            );
                          }
                        },
                      ),
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
  // Method to show re-enable availability dialog for expired spots
  static Future<void> _showReEnableDialog(
    BuildContext context,
    String spotId,
    String address,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule, color: Colors.orange.shade600),
            const SizedBox(width: 8),
            Text('Spot Expired'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address: $address',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This parking spot\'s availability time has expired. Set a new availability period to make it active again.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppStrings.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.schedule, size: 18),
                const SizedBox(width: 4),
                Text('Set New Time'),
              ],
            ),
          ),
        ],
      ),    );    if (confirm == true && context.mounted) {
      _showEditAvailabilityDialog(context, spotId, null, true, address, false);
    }
  }

  // Method to show edit availability dialog
  static Future<void> _showEditAvailabilityDialog(
    BuildContext context,
    String spotId,
    DateTime? currentAvailableUntil,
    bool isAvailable,
    String address,
    bool hasActiveBooking,
  ) async {
    DateTime? selectedDateTime = currentAvailableUntil;    await showDialog(
      context: context,      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            currentAvailableUntil == null || currentAvailableUntil.isBefore(DateTime.now())
                ? 'Set Availability Time'
                : AppStrings.editAvailabilityTitle
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppStrings.addressOrDescription}: $address',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),              const SizedBox(height: 16),
              if (hasActiveBooking)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This spot is currently booked. Changing availability will affect the booking.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ListTile(
                  leading: const Icon(Icons.access_time_outlined),                  title: Text(
                    selectedDateTime == null
                        ? AppStrings.selectAvailabilityUntil
                        : '${AppStrings.availableUntilPrefix}${DateTimeUtils.formatDateTime(context, selectedDateTime!)}',
                    style: TextStyle(
                      color: selectedDateTime == null
                          ? Colors.grey[600]
                          : Colors.black87,
                    ),
                  ),
                  trailing: const Icon(Icons.keyboard_arrow_right),
                  onTap: () async {
                    final DateTime now = DateTime.now();
                    final DateTime? date = await showDatePicker(
                      context: context,
                      initialDate: selectedDateTime ??
                          now.add(const Duration(hours: 24)),
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 30)),
                      helpText: 'Select availability end date',
                    );

                    if (date != null) {
                      final TimeOfDay? time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(selectedDateTime ??
                            date.add(const Duration(hours: 1))),
                        helpText: 'Select availability end time',
                      );

                      if (time != null) {
                        setState(() {
                          selectedDateTime = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ),
            ],
          ),          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppStrings.cancel),
            ),
            ElevatedButton(
              onPressed: selectedDateTime != null &&
                      selectedDateTime!.isAfter(DateTime.now())
                  ? () {
                      Navigator.of(context).pop();
                      _updateAvailability(context, spotId, selectedDateTime!);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
              ),
              child: Text(AppStrings.update),
            ),
          ],
        ),
      ),
    );
  }
  // Method to update availability in Firestore
  static Future<void> _updateAvailability(
    BuildContext context,
    String spotId,
    DateTime newAvailableUntil,
  ) async {
    await ErrorService.executeWithErrorHandling(
      context,
      () async {
        await FirebaseFirestore.instance
            .collection('parking_spots')
            .doc(spotId)
            .update({
          'availableUntil': Timestamp.fromDate(newAvailableUntil),
          'isAvailable': true, // Re-enable availability
        });        if (context.mounted) {
          SnackBarUtils.showSuccess(context,
              '${AppStrings.availabilityUpdatedSuccessfully}${DateTimeUtils.formatDateTime(context, newAvailableUntil)}');
        }
      },
      operationName: ErrorStrings.updateParkingSpotOperation,
    );
  }
}
