import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'qr_code_page.dart';

class ListingHistoryPage extends StatelessWidget {
  const ListingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Listed Spots')),
        body: const Center(
          child: Text('Please log in to see your listed spots.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Listed Spots')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('parking_spots')
            .where('ownerId', isEqualTo: user.uid)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final spots = snapshot.data?.docs ?? [];
          if (spots.isEmpty) {
            return const Center(child: Text('No listed spots.'));
          }
          return ListView.builder(
            itemCount: spots.length,
            itemBuilder: (context, index) {
              final spot = spots[index];
              final data = spot.data() as Map<String, dynamic>;
              final address = data['address'] as String? ?? 'No address';
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
              String statusText = 'Available';
              Color statusColor = Colors.green;

              if (!isAvailable) {
                // Need to check if it's actually booked or just expired
                // This will be handled by the StreamBuilder below
                statusText = 'Checking...';
                statusColor = Colors.grey;
              } else if (isTimeExpired) {
                statusText = 'Time Finished';
                statusColor = Colors.red;
              }

              return Card(
                child: ListTile(
                  title: Text(address),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Spot ID: $spotId'),
                      Row(
                        children: [
                          Text('Status: '),
                          if (!isAvailable)
                            // Use StreamBuilder to check for active bookings
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('bookings')
                                  .where('spotId', isEqualTo: spotId)
                                  .where('status', isEqualTo: 'active')
                                  .limit(1)
                                  .snapshots(),
                              builder: (context, bookingSnapshot) {
                                if (bookingSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Text(
                                    'Checking...',
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
                                    'Booked',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                } else {
                                  return Text(
                                    'Expired',
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
                      ),
                      if (availableUntil != null)
                        Text(
                          'Available until: ${DateFormat.yMd().add_jm().format(availableUntil)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Re-enable button for expired spots
                      if (isTimeExpired && isAvailable)
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.green),
                          tooltip: 'Re-enable Availability',
                          onPressed: () =>
                              _showReEnableDialog(context, spotId, address),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'Edit Availability',
                        onPressed: () => _showEditAvailabilityDialog(context,
                            spotId, availableUntil, isAvailable, address),
                      ),
                      IconButton(
                        icon: const Icon(Icons.qr_code, color: Colors.teal),
                        tooltip: 'Show QR Code',
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  QrCodePage(spotId: spotId, address: address),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'Delete Listing',
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Listing'),
                              content: const Text(
                                'Are you sure you want to delete this listing?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('parking_spots')
                                  .doc(spotId)
                                  .delete();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Listing deleted.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to delete: ${e.toString()}',
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
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
        title: const Text('Re-enable Availability'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: $address'),
            const SizedBox(height: 16),
            const Text(
                'This spot\'s availability has expired. Would you like to set a new availability period?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Re-enable'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _showEditAvailabilityDialog(context, spotId, null, true, address);
    }
  }

  // Method to show edit availability dialog
  static Future<void> _showEditAvailabilityDialog(
    BuildContext context,
    String spotId,
    DateTime? currentAvailableUntil,
    bool isAvailable,
    String address,
  ) async {
    DateTime? selectedDateTime = currentAvailableUntil;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Availability'),
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
              if (!isAvailable)
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
                  leading: const Icon(Icons.access_time_outlined),
                  title: Text(
                    selectedDateTime == null
                        ? 'Select new availability end time'
                        : 'Available until: ${DateFormat.yMd().add_jm().format(selectedDateTime!)}',
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
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('Update'),
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
    try {
      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(spotId)
          .update({
        'availableUntil': Timestamp.fromDate(newAvailableUntil),
        'isAvailable': true, // Re-enable availability
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                    'Availability updated until ${DateFormat.yMd().add_jm().format(newAvailableUntil)}'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to update availability: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}
