import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart'; // Add intl import for date formatting
import 'qr_pdf_util.dart';
import 'dart:async'; // Add Timer import for background tracking

import './pages/qr_scanner_page.dart';
import './pages/profile_page.dart';
import './pages/qr_code_page.dart';
import './pages/login_page.dart';
import './pages/signup_page.dart';
import './pages/home_page.dart';
import './pages/booking_history_page.dart';
import './pages/listing_history_page.dart';
import './pages/book_spot_page.dart';
import './pages/list_spot_page.dart';
import './pages/address_entry_page.dart';

// LocationService class for handling geolocation
class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      print('LocationService: Starting location request...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('LocationService: Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('LocationService: Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        print('LocationService: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('LocationService: Permission after request: $permission');
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print(
            'Location permissions are permanently denied, we cannot request permissions.');
        // For permanently denied permissions, we could open app settings
        return null;
      }

      print('LocationService: Getting current position...');
      // Get current position with better accuracy settings
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Increased timeout
      );

      print('Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting location: $e');
      // Check if this is a specific geolocator error
      if (e.toString().contains('No location permissions')) {
        print('LocationService: Permissions issue detected');
      }
      return null;
    }
  }

  static Future<void> moveToUserLocation(GoogleMapController controller) async {
    try {
      final position = await getCurrentLocation();
      if (position != null) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16,
            ),
          ),
        );
        print('Camera moved to user location');
      } else {
        print('Could not get user location to move camera');
      }
    } catch (e) {
      print('Error moving camera to user location: $e');
    }
  }
}

// Utility class for managing expired spot tracking
class ExpiredSpotTracker {
  static Timer? _globalTimer;
  static bool _isRunning = false;

  // Start global background tracking
  static void startGlobalTracking() {
    if (_isRunning) return; // Already running

    _isRunning = true;
    _globalTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      checkAndUpdateExpiredSpots();
    });

    // Also run an immediate check
    checkAndUpdateExpiredSpots();
  }

  // Stop global tracking
  static void stopGlobalTracking() {
    _globalTimer?.cancel();
    _globalTimer = null;
    _isRunning = false;
  }

  // Method to check and update expired spots
  static Future<void> checkAndUpdateExpiredSpots() async {
    try {
      final now = DateTime.now();
      final QuerySnapshot expiredSpots = await FirebaseFirestore.instance
          .collection('parking_spots')
          .where('isAvailable', isEqualTo: true)
          .where('availableUntil', isLessThanOrEqualTo: Timestamp.fromDate(now))
          .get();

      // Batch update expired spots to be unavailable
      if (expiredSpots.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (QueryDocumentSnapshot spot in expiredSpots.docs) {
          batch.update(spot.reference, {'isAvailable': false});
        }
        await batch.commit();

        print(
            'ExpiredSpotTracker: Updated ${expiredSpots.docs.length} expired spots to unavailable');
      }
    } catch (e) {
      print('Error in ExpiredSpotTracker: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Start global expired spot tracking
  ExpiredSpotTracker.startGlobalTracking();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parking Manager',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          elevation: 4.0,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.teal.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          labelStyle: TextStyle(color: Colors.teal.shade700),
          hintStyle: TextStyle(color: Colors.grey[600]),
          prefixIconColor: Colors.teal.shade700,
        ),
        cardTheme: CardThemeData(
          elevation: 3.0,
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textTheme: TextTheme(
          headlineSmall: TextStyle(
            color: Colors.teal[800],
            fontWeight: FontWeight.bold,
          ),
          titleLarge: TextStyle(
            color: Colors.teal[700],
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(
            color: Colors.teal[600],
            fontWeight: FontWeight.w500,
          ),
          bodyMedium: TextStyle(color: Colors.grey[800], fontSize: 14),
          bodySmall: TextStyle(color: Colors.grey[700], fontSize: 12),
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        iconTheme: IconThemeData(color: Colors.teal[700]),
      ),
      home: const LoginPage(),
    );
  }
}
