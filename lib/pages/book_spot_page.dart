import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/expired_spot_tracker.dart';
import 'profile_page.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'list_spot_page.dart';
import 'listing_history_page.dart';
import 'booking_history_page.dart';

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
  GoogleMapController? _mapController; // Add map controller
  CameraPosition?
      _cameraPositionBeforeSelection; // Store camera position before spot selection
  CameraPosition? _currentCameraPosition; // Track current camera position

  @override
  void initState() {
    super.initState();
    // Trigger an immediate check when the page loads
    ExpiredSpotTracker.checkAndUpdateExpiredSpots();
  }

  // Method to get user name for display
  Future<String> _getUserName(User user) async {
    try {
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
    } catch (e) {
      print('Error getting user name: $e');
    }

    // Fallback to display name or email
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }
    if (user.email != null && user.email!.contains('@')) {
      return user.email!.split('@')[0];
    }
    return 'User';
  }

  // Method to book a parking spot
  Future<void> _bookSpot(String spotId, String address) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _error = 'You must be logged in to book a spot.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Check if spot is still available
      final spotDoc = await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(spotId)
          .get();

      if (!spotDoc.exists) {
        setState(() {
          _error = 'This parking spot is no longer available.';
          _isLoading = false;
        });
        return;
      }

      final spotData = spotDoc.data() as Map<String, dynamic>;
      final isAvailable = spotData['isAvailable'] == true;
      final availableUntil =
          (spotData['availableUntil'] as Timestamp?)?.toDate();

      if (!isAvailable) {
        setState(() {
          _error = 'This parking spot has already been booked.';
          _isLoading = false;
        });
        return;
      }

      if (availableUntil != null && availableUntil.isBefore(DateTime.now())) {
        setState(() {
          _error = 'This parking spot has expired.';
          _isLoading = false;
        });
        return;
      }

      // Create booking
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'spotId': spotId,
        'address': address,
        'startTime': Timestamp.now(),
        'status': 'active',
        'userEmail': user.email,
      });

      // Mark spot as booked
      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(spotId)
          .update({'isAvailable': false});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Parking spot booked successfully!'),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        ); // Redirect to homepage after successful booking
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to book parking spot: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<CameraPosition> _getInitialCameraPosition() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      return CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14,
      );
    }
    // Fallback to default coordinates if location is not available
    return const CameraPosition(
      target: LatLng(23.7624, 90.3785),
      zoom: 14,
    );
  } // Method to move camera to selected spot

  Future<void> _moveCameraToSpot(LatLng spotLocation) async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: spotLocation,
            zoom: 16, // Zoom in closer to the selected spot
          ),
        ),
      );
    }
  }

  // Method to restore camera to position before spot selection
  Future<void> _restorePreviousCamera() async {
    if (_mapController != null && _cameraPositionBeforeSelection != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(_cameraPositionBeforeSelection!),
      );
    }
  }

  // Method to move camera to user location
  Future<void> _moveToUserLocation() async {
    try {
      if (_mapController != null) {
        await LocationService.moveToUserLocation(_mapController!);
      } else {
        print('Map controller is not initialized');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Map is not ready yet. Please try again.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _moveToUserLocation: $e');
      // Show user-friendly error message based on error type
      if (mounted) {
        String errorMessage = 'Could not get your location.';

        if (e.toString().contains('No location permissions') ||
            e.toString().contains('permissions')) {
          errorMessage =
              'Location permission required. Please enable location access in Settings.';
        } else if (e.toString().contains('Location services') ||
            e.toString().contains('disabled')) {
          errorMessage =
              'Location services are disabled. Please enable them in Settings.';
        } else if (e.toString().contains('timeout') ||
            e.toString().contains('TimeoutException')) {
          errorMessage = 'Location request timed out. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _moveToUserLocation(),
            ),
          ),
        );
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
                  FutureBuilder<String>(
                    future: _getUserName(user!),
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

            // Separate spots into available and expired
            final availableSpots = <QueryDocumentSnapshot>[];
            final expiredSpots = <QueryDocumentSnapshot>[];

            for (final spot in spots) {
              final data = spot.data() as Map<String, dynamic>;
              final availableUntilTimestamp =
                  data['availableUntil'] as Timestamp?;
              final isCurrentlyAvailable =
                  data['isAvailable'] as bool? ?? false;

              if (availableUntilTimestamp == null) {
                // No time restriction, check isAvailable flag
                if (isCurrentlyAvailable) {
                  availableSpots.add(spot);
                } else {
                  expiredSpots.add(spot);
                }
              } else {
                final availableUntil = availableUntilTimestamp.toDate();
                if (availableUntil.isAfter(DateTime.now()) &&
                    isCurrentlyAvailable) {
                  availableSpots.add(spot);
                } else {
                  expiredSpots.add(spot);
                }
              }
            }

            final markers = <Marker>{};
            final user = FirebaseAuth.instance.currentUser;

            // Add available spots with blue markers
            for (final spot in availableSpots) {
              final data = spot.data() as Map<String, dynamic>;
              // Check for both old nested format and new direct format
              final lat = (data['location']?['latitude'] as num?)?.toDouble() ??
                  (data['latitude'] as num?)?.toDouble();
              final lng =
                  (data['location']?['longitude'] as num?)?.toDouble() ??
                      (data['longitude'] as num?)?.toDouble();
              final address = data['address'] as String? ?? 'No address';
              final spotId = spot.id;
              final ownerId = data['ownerId'] as String?;
              final isOwner = user != null && ownerId == user.uid;

              if (lat != null && lng != null && !isOwner) {
                markers.add(
                  Marker(
                    markerId: MarkerId(spotId),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(title: address),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure, // Blue for available spots
                    ),
                    onTap: () async {
                      final spotLocation = LatLng(lat, lng);

                      // Capture current camera position before moving to spot
                      _cameraPositionBeforeSelection = _currentCameraPosition;

                      // Move camera to center on the selected spot first
                      await _moveCameraToSpot(spotLocation);

                      // Then immediately restore to previous position while keeping spot selected
                      await _restorePreviousCamera();

                      setState(() {
                        _selectedSpotId = spotId;
                        _selectedLatLng = spotLocation;
                        _selectedAddress = address;
                      });
                    },
                  ),
                );
              }
            }

            // Add expired spots with red markers
            for (final spot in expiredSpots) {
              final data = spot.data() as Map<String, dynamic>;
              // Check for both old nested format and new direct format
              final lat = (data['location']?['latitude'] as num?)?.toDouble() ??
                  (data['latitude'] as num?)?.toDouble();
              final lng =
                  (data['location']?['longitude'] as num?)?.toDouble() ??
                      (data['longitude'] as num?)?.toDouble();
              final address = data['address'] as String? ?? 'No address';
              final spotId = spot.id;
              final ownerId = data['ownerId'] as String?;
              final isOwner = user != null && ownerId == user.uid;

              if (lat != null && lng != null && !isOwner) {
                markers.add(
                  Marker(
                    markerId: MarkerId('expired_$spotId'),
                    position: LatLng(lat, lng),
                    infoWindow: InfoWindow(title: '$address (Unavailable)'),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed, // Red for expired spots
                    ),
                    onTap: () {
                      // Show unavailable message for expired spots
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'This spot is unavailable. Please look for another one.',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: Colors.orange.shade600,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          margin: const EdgeInsets.all(16),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                      // Clear any selected spot
                      setState(() {
                        _selectedSpotId = null;
                        _selectedLatLng = null;
                        _selectedAddress = null;
                      });
                    },
                  ),
                );
              }
            }

            // Show message if no available spots
            if (availableSpots.isEmpty && expiredSpots.isEmpty) {
              return const Center(
                child: Text('No parking spots found at the moment.'),
              );
            }
            if (availableSpots.isEmpty && expiredSpots.isNotEmpty) {
              return FutureBuilder<CameraPosition>(
                future: _getInitialCameraPosition(),
                builder: (context, cameraSnapshot) {
                  if (cameraSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final initialPosition = cameraSnapshot.data ??
                      const CameraPosition(
                        target: LatLng(23.7624, 90.3785),
                        zoom: 14,
                      );
                  return Stack(
                    children: [
                      GoogleMap(
                        initialCameraPosition: initialPosition,
                        markers: markers,
                        myLocationEnabled: true,
                        myLocationButtonEnabled:
                            false, // Disable default to use custom button
                        onMapCreated: (GoogleMapController controller) async {
                          _mapController = controller;
                        },
                        onTap: (_) {
                          setState(() {
                            _selectedSpotId = null;
                            _selectedLatLng = null;
                            _selectedAddress = null;
                          });
                        },
                      ),
                      // Custom My Location button
                      Positioned(
                        top: 16,
                        right: 16,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.teal,
                          onPressed: _moveToUserLocation,
                          tooltip: 'My Location',
                          child: const Icon(Icons.my_location),
                        ),
                      ),
                      Positioned(
                        top: 100,
                        left: 16,
                        right: 16,
                        child: Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange.shade600),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'No available spots at the moment. Red markers show unavailable spots.',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            }
            return FutureBuilder<CameraPosition>(
              future: _getInitialCameraPosition(),
              builder: (context, cameraSnapshot) {
                if (cameraSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final initialPosition = cameraSnapshot.data ??
                    const CameraPosition(
                      target: LatLng(23.7624, 90.3785),
                      zoom: 14,
                    );
                return Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: initialPosition,
                      markers: markers,
                      myLocationEnabled: true,
                      myLocationButtonEnabled:
                          false, // Disable default to use custom button
                      onMapCreated: (GoogleMapController controller) async {
                        _mapController = controller;
                        // Initialize current camera position
                        _currentCameraPosition = initialPosition;
                      },
                      onCameraMove: (CameraPosition position) {
                        // Track camera position changes
                        _currentCameraPosition = position;
                      },
                      onTap: (_) {
                        setState(() {
                          _selectedSpotId = null;
                          _selectedLatLng = null;
                          _selectedAddress = null;
                        });
                      },
                    ),
                    // Custom My Location button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.teal,
                        onPressed: _moveToUserLocation,
                        tooltip: 'My Location',
                        child: const Icon(Icons.my_location),
                      ),
                    ),
                    // Legend for marker colors
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('Available',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('Unavailable',
                                      style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
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
                                    'Lat: ${_selectedLatLng!.latitude.toStringAsFixed(6)}, Lng: ${_selectedLatLng!.longitude.toStringAsFixed(6)}',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(height: 16),
                                  // Confirm Booking Button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading
                                          ? null
                                          : () => _bookSpot(
                                                _selectedSpotId!,
                                                _selectedAddress ?? '',
                                              ),
                                      icon: _isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.check_circle_outline),
                                      label: Text(_isLoading
                                          ? 'BOOKING...'
                                          : 'Confirm Booking'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal[600],
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        elevation: 4,
                                      ),
                                    ),
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
            );
          },
        ),
      ),
    );
  }
}
