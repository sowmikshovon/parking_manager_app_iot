import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'login_page.dart';
import 'list_spot_page.dart';
import 'listing_history_page.dart';
import 'booking_history_page.dart';
import 'profile_page.dart';

class BookSpotPage extends StatefulWidget {
  const BookSpotPage({super.key});

  @override
  State<BookSpotPage> createState() => _BookSpotPageState();
}

class _BookSpotPageState extends State<BookSpotPage> {
  bool _isLoading = false;
  String? _error;
  String? _selectedSpotId;
  LatLng? _selectedLatLng;
  String? _selectedAddress;

  Future<String> _getUserName(User user) async {
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        return userDoc.data()!['name'] ?? 'User';
      }
    } catch (e) {
      // Handle error appropriately
    }
    return 'User';
  }

  Future<void> _bookSpot(String spotId, String address) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
        _error = 'You must be logged in to book a spot.';
      });
      return;
    }
    try {
      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(spotId)
          .update({'isAvailable': false});
      await FirebaseFirestore.instance.collection('bookings').add({
        'spotId': spotId,
        'userId': user.uid,
        'address': address,
        'status': 'booked',
        'bookingTime': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Spot booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to book spot: \\${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Parking Spot'),
        actions: [
          // Profile Button
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
          // Logout Button
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Logout',
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
                  const SizedBox(height: 10),
                  const Text(
                    'Parking Manager',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 5),
                  if (user != null)
                    FutureBuilder<String>(
                      future: _getUserName(user),
                      builder: (context, snapshot) {
                        String name = snapshot.data ?? 'User';
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
              title: const Text('Book a Spot'),
              onTap: () {
                Navigator.pop(context); // Close drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_location_alt_outlined),
              title: const Text('List a New Spot'),
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
              title: const Text('My Listed Spots'),
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
              title: const Text('My Booking History'),
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
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFe0f7fa),
              Color(0xFFb2ebf2),
              Color(0xFF80deea),
              Color(0xFF26c6da),
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('parking_spots')
              .where('isAvailable', isEqualTo: true)
              .orderBy('created_at', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: \\${snapshot.error}'));
            }
            final spots = snapshot.data?.docs ?? [];
            if (spots.isEmpty) {
              return const Center(
                child: Text('No available spots at the moment.'),
              );
            }
            final markers = <Marker>{};
            for (final spot in spots) {
              final data = spot.data() as Map<String, dynamic>;
              final lat = (data['location']?['latitude'] as num?)?.toDouble();
              final lng = (data['location']?['longitude'] as num?)?.toDouble();
              final address = data['address'] as String? ?? 'No address';
              final spotId = spot.id;
              final ownerId = data['ownerId'] as String?;
              final user = FirebaseAuth.instance.currentUser;
              final isOwner = user != null && ownerId == user.uid;
              if (lat != null && lng != null && !isOwner) {
                markers.add(
                  Marker(
                    markerId: MarkerId(spotId),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(title: address),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedSpotId = spotId;
                        _selectedLatLng = LatLng(lat, lng);
                        _selectedAddress = address;
                      });
                    },
                  ),
                );
              }
            }
            return Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: markers.isNotEmpty
                        ? markers.first.position
                        : const LatLng(23.7624, 90.3785),
                    zoom: 14,
                  ),
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onTap: (_) {
                    setState(() {
                      _selectedSpotId = null;
                      _selectedLatLng = null;
                      _selectedAddress = null;
                    });
                  },
                ),
                if (_selectedSpotId != null && _selectedLatLng != null)
                  Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Card(
                        elevation: 8,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _selectedAddress ?? '',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Lat: \\${_selectedLatLng!.latitude.toStringAsFixed(6)}, Lng: \\${_selectedLatLng!.longitude.toStringAsFixed(6)}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _bookSpot(
                                          _selectedSpotId!,
                                          _selectedAddress ?? '',
                                        ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : const Text('Confirm Booking'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_error != null)
                  Positioned(
                    top: 40,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
