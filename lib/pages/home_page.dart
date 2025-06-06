import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/expired_spot_tracker.dart';
import '../services/dialog_service.dart';
import '../services/error_service.dart';
import '../utils/snackbar_utils.dart';
import '../utils/date_time_utils.dart';
import '../utils/app_constants.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'qr_scanner_page.dart';
import 'booking_history_page.dart';
import 'listing_history_page.dart';
import 'book_spot_page.dart';
import 'list_spot_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {  @override
  void initState() {
    super.initState();
    // Check for expired spots once when page loads
    // Global tracker will handle periodic updates
    _checkExpiredSpotsOnLoad();
  }

  // Check expired spots once when page loads using global tracker
  Future<void> _checkExpiredSpotsOnLoad() async {
    await ErrorService.executeWithErrorHandling<void>(
      context,
      () async {
        await ExpiredSpotTracker.checkAndUpdateExpiredSpots();
      },
      operationName: AppStrings.checkExpiredSpotsOperation,
      showSnackBar: false, // Silent background operation
    );
  }

  Widget _buildHomeButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? backgroundColor,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.teal.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              backgroundColor ?? Colors.teal.shade400,
              backgroundColor?.withValues(alpha: 0.8) ?? Colors.teal.shade600,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onPressed,
            splashColor: Colors.white.withValues(alpha: 0.3),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookedSpotCard(
    BuildContext context, {
    required String spotId,
    required String address,
    required String timeString,
    required String bookingId,
    required String expectedEndTime,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.orange.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.orange.shade100,
              Colors.orange.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.orange.shade300,
            width: 1.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade600,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.local_parking,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          address.length > 35
                              ? '${address.substring(0, 35)}...'
                              : address,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 4),                            Text(
                              AppStrings.bookedAtPrefix + timeString,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.orange.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              expectedEndTime,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons row
              Row(
                children: [
                  // QR Scanner button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _openQrScannerForBookedSpot(context, spotId, address),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),                      label: Text(
                        AppStrings.scanQrCodeMenuItem,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Unbook button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showUnbookingDialog(
                          context, spotId, address, bookingId),
                      icon: const Icon(Icons.close, size: 18),                      label: Text(
                        AppStrings.unbookMenuItem,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8), // More button (work in progress)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {                        SnackBarUtils.showCustom(
                          context,
                          AppStrings.workInProgress,
                          backgroundColor: Colors.blueGrey[700],
                          icon: Icons.construction,
                        );
                      },
                      icon: const Icon(Icons.navigation, size: 18),                      label: Text(
                        AppStrings.navigateMenuItem,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to open QR scanner for booked spots
  void _openQrScannerForBookedSpot(
      BuildContext context, String spotId, String address) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrScannerPage(
          expectedSpotId: spotId,
          address: address,
          onSuccess: () {            SnackBarUtils.showSuccess(
                context, AppStrings.qrCodeVerifiedSuccessfully);
          },
          onSkip: () {
            SnackBarUtils.showWarning(context, AppStrings.qrScanningSkipped);
          },
        ),
      ),
    );
  }

  Future<void> _showUnbookingDialog(
    BuildContext context,
    String spotId,
    String address,
    String bookingId,
  ) async {
    final confirmed = await DialogService.showUnbookDialog(
      context: context,
      address: address,
    );

    if (confirmed == true) {
      await _unbookSpot(context, spotId, bookingId);
    }
  }
  Future<void> _unbookSpot(
    BuildContext context,
    String spotId,
    String bookingId,
  ) async {
    final result = await ErrorService.executeWithErrorHandling<bool>(
      context,
      () async {
        // Update the parking spot to be available
        await FirebaseFirestore.instance
            .collection('parking_spots')
            .doc(spotId)            .update({'isAvailable': true});

        // Update the booking status to completed
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': AppStrings.completedStatus,
          'endTime': Timestamp.now(),
        });

        return true;
      },
      operationName: AppStrings.unbookParkingSpotOperation,
      showSnackBar: true,
    );

    if (result != null && result == true) {
      if (context.mounted) {        SnackBarUtils.showSuccess(
            context, AppStrings.parkingSpotSuccessfullyUnbooked);
      }
    } else {
      // Handle the case where spot might not exist - try alternative approach
      final fallbackResult = await ErrorService.executeWithErrorHandling<bool>(
        context,
        () async {
          // Just mark booking as completed since spot might not exist
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .update({            'status': AppStrings.spotDeletedStatus,
            'endTime': Timestamp.now(),
            'note': AppStrings.parkingSpotNoLongerAvailable,
          });
          return true;
        },
        operationName: AppStrings.endBookingSpotUnavailableOperation,
        showSnackBar: false, // Don't show error for this fallback
      );

      if (fallbackResult != null && fallbackResult == true) {
        if (context.mounted) {          SnackBarUtils.showWarning(
              context, AppStrings.bookingEndedSpotUnavailable);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(        appBar: AppBar(title: Text(AppStrings.appTitle)),
        body: Center(
          child: Text(AppStrings.pleaseLogInToAccess),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.appTitle),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Profile Button
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: AppStrings.profileTooltip,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: AppStrings.logoutTooltip,
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.directions_car,
                      color: Colors.teal,
                      size: 35,
                    ),
                  ),
                  const SizedBox(height: 10),                  Text(
                    AppStrings.parkingManagerTitle,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  FutureBuilder<String>(
                    future: _getUserName(user),
                    builder: (context, snapshot) {
                      String name = snapshot.data ?? AppStrings.defaultUserName;
                      return Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search_outlined),
              title: Text(AppStrings.bookASpot),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BookSpotPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: Text(AppStrings.listANewSpot),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ListSpotPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: Text(AppStrings.myListedSpots),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const ListingHistoryPage(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long_outlined),
              title: Text(AppStrings.myBookingHistory),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const BookingHistoryPage(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: Text(AppStrings.profile),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(AppStrings.logout),
              onTap: () async {
                Navigator.pop(context); // Close drawer
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Welcome section with current bookings
          Container(
            width: double.infinity,
            color: Colors.teal.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<String>(
                  future: _getUserName(user),
                  builder: (context, snapshot) {                    String name = snapshot.data ?? AppStrings.defaultUserName;
                    return Text(
                      '${AppStrings.welcomeUser}$name!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),                Text(
                  AppStrings.manageParkingMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal.shade600,
                  ),
                ),
                const SizedBox(height: 16), // Current bookings section
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: user.uid)
                      .where('status', isEqualTo: AppStrings.activeStatus)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final booking = snapshot.data!.docs.first;
                      final data = booking.data() as Map<String, dynamic>;
                      final address =
                          data['address'] as String? ?? 'No address';
                      final startTime =
                          (data['startTime'] as Timestamp).toDate();
                      final timeString =
                          DateTimeUtils.formatTime(context, startTime);
                      final spotId = data['spotId'] as String? ?? '';
                      final bookingId = booking.id;

                      // Get the spot's availableUntil time to calculate correct remaining time
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('parking_spots')
                            .doc(spotId)
                            .get(),
                        builder: (context, spotSnapshot) {
                          String remainingText = AppStrings.loading;

                          if (spotSnapshot.hasData &&
                              spotSnapshot.data!.exists) {
                            final spotData = spotSnapshot.data!.data()
                                as Map<String, dynamic>;
                            final availableUntilTimestamp =
                                spotData['availableUntil'] as Timestamp?;

                            if (availableUntilTimestamp != null) {
                              final availableUntil =
                                  availableUntilTimestamp.toDate();
                              final now = DateTime.now();
                              final remaining = availableUntil.difference(now);                              remainingText = remaining.isNegative
                                  ? AppStrings.expired
                                  : '${remaining.inHours}${AppStrings.hoursMinutesRemaining}${remaining.inMinutes % 60}${AppStrings.minutesRemaining}';
                            } else {
                              remainingText = AppStrings.noTimeLimit;
                            }
                          } else {
                            remainingText = AppStrings.spotUnavailable;
                          }
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [                              Text(
                                AppStrings.currentBooking,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildBookedSpotCard(
                                context,
                                spotId: spotId,
                                address: address,
                                timeString: timeString,
                                bookingId: bookingId,
                                expectedEndTime: remainingText,
                              ),
                            ],
                          );
                        },
                      );
                    }
                    return Container();
                  },
                ),
              ],
            ),
          ),
          // Quick actions
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [                  Text(
                    AppStrings.quickActions,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildHomeButton(
                    context,
                    icon: Icons.search_outlined,
                    label: AppStrings.bookAParkingSpot,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const BookSpotPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildHomeButton(
                    context,
                    icon: Icons.add_location_alt_outlined,
                    label: AppStrings.listANewSpot,
                    backgroundColor: Colors.orange.shade400,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const ListSpotPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildHomeButton(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: AppStrings.myBookingHistory,
                    backgroundColor: Colors.purple.shade400,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const BookingHistoryPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildHomeButton(
                    context,
                    icon: Icons.history_edu_outlined,
                    label: AppStrings.myListedSpots,
                    backgroundColor: Colors.blue.shade400,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ListingHistoryPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  // Helper method to get user name for display
  Future<String> _getUserName(User user) async {
    final result = await ErrorService.executeWithErrorHandling<String>(
      context,
      () async {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data()!;
          final name = data['name'] as String? ?? '';
          if (name.isNotEmpty) {
            return name;
          }
        }
        throw Exception('User name not found');
      },
      operationName: AppStrings.getUserNameOperation,
      showSnackBar: false, // Silent operation for background user name fetching
    );

    if (result != null) {
      return result;
    }

    // Fallback to display name or email
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    // Final fallback to email username
    if (user.email != null && user.email!.contains('@')) {
      return user.email!.split('@')[0];
    }

    return AppStrings.defaultUserName;
  }
}
