import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import './pages/permission_setup_page.dart';
import './services/expired_spot_tracker.dart';
import './services/booking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Start global expired spot tracking
  ExpiredSpotTracker.startGlobalTracking();
  
  // Start periodic booking expiration checking
  _startBookingExpirationChecking();

  runApp(const MyApp());
}

/// Start periodic checking for expired bookings
void _startBookingExpirationChecking() {
  // Check expired bookings every 2 minutes
  Stream.periodic(const Duration(minutes: 2)).listen((_) async {
    try {
      await BookingService.checkAndExpireBookings();
    } catch (e) {
      print('Error in periodic booking expiration check: $e');
    }
  });
  
  // Also check immediately on app start
  Future.delayed(const Duration(seconds: 5), () async {
    try {
      await BookingService.checkAndExpireBookings();
    } catch (e) {
      print('Error in initial booking expiration check: $e');
    }
  });
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
      home: const PermissionSetupPage(),
    );
  }
}
