import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Booking History')),
        body: const Center(
          child: Text('Please log in to see booking history.'),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('My Booking History')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: user.uid)
            .orderBy('bookingTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final bookings = snapshot.data?.docs ?? [];
          if (bookings.isEmpty) {
            return const Center(child: Text('No booking history.'));
          }
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              final data = booking.data() as Map<String, dynamic>;
              final spotId = data['spotId'] as String? ?? 'N/A';
              final status = data['status'] as String? ?? 'Unknown';
              final bookingTimeTimestamp = data['bookingTime'] as Timestamp?;
              final endTimeTimestamp = data['endTime'] as Timestamp?;
              final bookingTime = bookingTimeTimestamp != null
                  ? bookingTimeTimestamp
                        .toDate()
                        .toLocal()
                        .toString()
                        .substring(0, 16)
                  : 'N/A';
              final endTime = endTimeTimestamp != null
                  ? endTimeTimestamp.toDate().toLocal().toString().substring(
                      0,
                      16,
                    )
                  : 'N/A';

              return Card(
                child: ListTile(
                  title: Text('Spot ID: $spotId'),
                  subtitle: Text(
                    'Status: $status\nBooked: $bookingTime\nEnded: $endTime',
                  ),
                  trailing: status == 'booked'
                      ? ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                          ),
                          onPressed: () async {
                            try {
                              await FirebaseFirestore.instance
                                  .collection('parking_spots')
                                  .doc(spotId)
                                  .update({'isAvailable': true});
                              await FirebaseFirestore.instance
                                  .collection('bookings')
                                  .doc(booking.id)
                                  .update({
                                    'status': 'completed',
                                    'endTime': Timestamp.now(),
                                  });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Parking ended and spot relisted!',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to end parking: \\${e.toString()}',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('End Parking'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
