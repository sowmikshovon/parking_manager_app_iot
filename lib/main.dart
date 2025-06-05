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
//import './pages/qr_code_page.dart';
//import './pages/login_page.dart';
//import './pages/listing_history_page.dart';

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

// QrCodePage widget displays a QR code for a given parking spot

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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _obscurePassword = true;  Future<void> _signIn() async {
    // Validate empty fields before attempting authentication
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    if (email.isEmpty) {
      setState(() {
        _error = "Please enter your email address.";
      });
      return;
    }
    
    if (password.isEmpty) {
      setState(() {
        _error = "Please enter your password.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'wrong-password':
            _error = "The password you entered is incorrect. Please try again.";
            break;
          case 'user-not-found':
            _error = "No account found with this email address. Please check your email or sign up.";
            break;
          case 'invalid-email':
            _error = "The email address is not valid. Please enter a valid email.";
            break;
          case 'user-disabled':
            _error = "This account has been disabled. Please contact support.";
            break;
          case 'too-many-requests':
            _error = "Too many failed login attempts. Please try again later.";
            break;
          case 'invalid-credential':
            _error = "Invalid email or password. Please check your credentials and try again.";
            break;
          case 'network-request-failed':
            _error = "Network error. Please check your internet connection and try again.";
            break;
          default:
            _error = e.message ?? "Login failed. Please try again.";
        }
      });
    } catch (e) {
      setState(() {
        _error = "An unexpected error occurred. Please try again.";
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
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Welcome Back!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signIn,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: Text(
                      'Don\'t have an account? Sign up',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _firstNameError;
  String? _lastNameError;
  String? _emailError;
  String? _passwordError;
  bool _obscurePassword = true;

  void _validateFirstName(String value) {
    setState(() {
      if (value.isEmpty) {
        _firstNameError = 'First name cannot be empty';
      } else {
        _firstNameError = null;
      }
    });
  }

  void _validateLastName(String value) {
    setState(() {
      if (value.isEmpty) {
        _lastNameError = 'Last name cannot be empty';
      } else {
        _lastNameError = null;
      }
    });
  }

  void _validateEmail(String value) {
    setState(() {
      if (value.isEmpty) {
        _emailError = 'Email cannot be empty';
      } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
        _emailError = 'Enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePassword(String value) {
    setState(() {
      if (value.isEmpty) {
        _passwordError = 'Password cannot be empty';
      } else if (value.length < 6) {
        _passwordError = 'Password must be at least 6 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  Future<void> _signUp() async {
    _validateFirstName(_firstNameController.text);
    _validateLastName(_lastNameController.text);
    _validateEmail(_emailController.text);
    _validatePassword(_passwordController.text);

    if (_firstNameError != null ||
        _lastNameError != null ||
        _emailError != null ||
        _passwordError != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      User? user = userCredential.user;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name':
              '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
          'email': user.email,
        });
      }
      if (mounted) {
        Navigator.pop(context); // Go back to LoginPage
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign up successful! Please log in.'),
            backgroundColor: Colors.green,
          ),
        );
      }    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _error = 'This email address is already registered. Please use a different email or try logging in.';
            break;
          case 'weak-password':
            _error = 'The password is too weak. Please choose a stronger password.';
            break;
          case 'invalid-email':
            _error = 'The email address is not valid. Please enter a valid email.';
            break;
          case 'operation-not-allowed':
            _error = 'Email/password accounts are not enabled. Please contact support.';
            break;
          case 'network-request-failed':
            _error = 'Network error. Please check your internet connection and try again.';
            break;
          default:
            _error = e.message ?? 'Sign up failed. Please try again.';
        }
      });
    } catch (e) {
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'First Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      errorText: _firstNameError,
                    ),
                    onChanged: _validateFirstName,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Last Name',
                      prefixIcon: const Icon(Icons.person),
                      errorText: _lastNameError,
                    ),
                    onChanged: _validateLastName,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: _emailError,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscurePassword,
                    onChanged: _validatePassword,
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

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
            return Center(child: Text('Error: \\${snapshot.error}'));
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
              final isAvailable = data['isAvailable'] == true;              // Check availability status based on time
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
                      Text('Spot ID: $spotId'),                      Row(
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
                                if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                                  return Text(
                                    'Checking...',
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                
                                final hasActiveBooking = bookingSnapshot.hasData && 
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
                                      'Failed to delete: \\${e.toString()}',
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

class BookingHistoryPage extends StatelessWidget {
  const BookingHistoryPage({super.key});

  // Helper method to format date and time according to device settings
  static String _formatDateTime(BuildContext context, DateTime dateTime) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool is24HourFormat = mediaQuery.alwaysUse24HourFormat;

    final String date = DateFormat.yMd().format(dateTime);
    final String time = is24HourFormat
        ? DateFormat('HH:mm').format(dateTime) // 24-hour format (14:30)
        : DateFormat('h:mm a').format(dateTime); // 12-hour format (2:30 PM)
    return '$date $time';
  }
  // Method to open QR scanner for booked spots in booking history
  static void _openQrScannerForBookingHistory(BuildContext context, String spotId, String address, String bookingId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrScannerPage(
          expectedSpotId: spotId,
          address: address,
          onSuccess: () {
            // Show success message when QR is successfully scanned
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('QR Code verified successfully!'),
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
          },
          onSkip: () {
            // Show message when user skips QR scanning
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('QR scanning skipped'),
                  ],
                ),
                backgroundColor: Colors.orange[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          },
        ),
      ),
    );
  }

  // Method to end parking from booking history
  static Future<void> _endParkingFromHistory(BuildContext context, String spotId, String bookingId) async {
    try {
      // First check if the parking spot still exists
      final spotDoc = await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(spotId)
          .get();

      if (spotDoc.exists) {
        // Spot exists, proceed with normal end parking
        await FirebaseFirestore.instance
            .collection('parking_spots')
            .doc(spotId)
            .update({'isAvailable': true});
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
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
      } else {
        // Spot no longer exists, just mark booking as completed
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'spot_deleted',
          'endTime': Timestamp.now(),
          'note': 'Parking spot was deleted by owner',
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Booking ended (spot no longer available)',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      // Handle the case where spot might not exist
      if (e.toString().contains('not-found')) {
        try {
          // Just mark booking as completed since spot doesn't exist
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .update({
            'status': 'spot_deleted',
            'endTime': Timestamp.now(),
            'note': 'Parking spot no longer available',
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Booking ended (spot no longer available)',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (updateError) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error ending booking: ${updateError.toString()}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to end parking: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
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

              final startTimeString = startTime != null
                  ? _formatDateTime(context, startTime.toDate())
                  : 'Unknown';
              final endTimeString = endTime != null
                  ? _formatDateTime(context, endTime.toDate())
                  : 'Ongoing';

              final isActive = status == 'active';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isActive ? Icons.directions_car : Icons.history,
                            color: isActive ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              address,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isActive ? Colors.green.shade100 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isActive ? 'Active' : status.toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Started: $startTimeString',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      if (!isActive) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.schedule, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'Ended: $endTimeString',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                      if (isActive) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // QR Scanner button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openQrScannerForBookingHistory(context, spotId, address, bookingId),
                                icon: const Icon(Icons.qr_code_scanner, size: 18),
                                label: const Text(
                                  'Scan QR',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                            // End Parking button
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _endParkingFromHistory(context, spotId, bookingId),
                                icon: const Icon(Icons.stop_circle_outlined, size: 18),
                                label: const Text(
                                  'End Parking',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red.shade600,
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

class ListSpotPage extends StatefulWidget {
  const ListSpotPage({super.key});

  @override
  State<ListSpotPage> createState() => _ListSpotPageState();
}

class _ListSpotPageState extends State<ListSpotPage> {
  LatLng? _selectedLatLng;
  GoogleMapController? _mapController; // Add map controller

  Future<CameraPosition> _getInitialCameraPosition() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      return CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14,
      );
    } // Fallback to default coordinates if location is not available
    return const CameraPosition(
      target: LatLng(23.7624, 90.3785),
      zoom: 14,
    );
  }

  // Method to move camera to selected spot
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
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: FutureBuilder<CameraPosition>(
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
                markers: _selectedLatLng == null
                    ? {}
                    : {
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: _selectedLatLng!,
                        ),
                      },
                onTap: (latLng) {
                  setState(() {
                    _selectedLatLng = latLng;
                  });
                },
                myLocationEnabled: true,
                myLocationButtonEnabled:
                    false, // Disable default to use custom button
                onMapCreated: (GoogleMapController controller) async {
                  _mapController = controller; // Store controller reference
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
              if (_selectedLatLng != null)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddressEntryPage(
                                selectedLatLng: _selectedLatLng!),
                          ),
                        );
                      },
                      child: const Text('Next'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AddressEntryPage extends StatefulWidget {
  final LatLng selectedLatLng;
  const AddressEntryPage({super.key, required this.selectedLatLng});

  @override
  State<AddressEntryPage> createState() => _AddressEntryPageState();
}

class _AddressEntryPageState extends State<AddressEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  String _formatDateTime(BuildContext context, DateTime dateTime) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool is24HourFormat = mediaQuery.alwaysUse24HourFormat;

    final String date = DateFormat.yMd().format(dateTime);
    final String time = is24HourFormat
        ? DateFormat('HH:mm').format(dateTime) // 24-hour format (14:30)
        : DateFormat('h:mm a').format(dateTime); // 12-hour format (2:30 PM)
    return '$date $time';
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'SELECT AVAILABILITY END DATE',
    );

    if (date != null && context.mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _selectedDateTime ?? date.add(const Duration(hours: 1))),
        helpText: 'SELECT AVAILABILITY END TIME',
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitSpot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Please select the date and time the spot will be available until.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    // Ensure the selected date and time is in the future
    if (_selectedDateTime!
        .isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Availability must be at least 5 minutes in the future.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to list a spot.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('parking_spots').add({
        'address': _addressController.text,
        'latitude': widget.selectedLatLng.latitude,
        'longitude': widget.selectedLatLng.longitude,
        'isAvailable': true,
        'availableUntil': Timestamp.fromDate(_selectedDateTime!),
        'ownerId': user.uid,
        'created_at': FieldValue.serverTimestamp(),
        'userEmail': user.email,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parking spot listed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to the previous screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error listing spot: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Spot Details'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Location:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${widget.selectedLatLng.latitude.toStringAsFixed(6)}, Lng: ${widget.selectedLatLng.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address or Description',
                  hintText: 'e.g., Near the park entrance',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an address or description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Available Until:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        // Wrap the Text widget with Expanded
                        child: Text(
                          _selectedDateTime == null
                              ? 'Select Date & Time'
                              : 'Ends: ${_formatDateTime(context, _selectedDateTime!)}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: _selectedDateTime == null
                                        ? Theme.of(context).hintColor
                                        : null,
                                  ),
                          overflow: TextOverflow.ellipsis, // Prevent overflow
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              if (_selectedDateTime == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select when your spot will be available until.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label:
                    Text(_isLoading ? 'LISTING...' : 'CONFIRM AND LIST SPOT'),
                onPressed: _isLoading ? null : _submitSpot,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // Check for expired spots once when page loads
    // Global tracker will handle periodic updates
    _checkExpiredSpotsOnLoad();
  }

  // Check expired spots once when page loads using global tracker
  Future<void> _checkExpiredSpotsOnLoad() async {
    try {
      await ExpiredSpotTracker.checkAndUpdateExpiredSpots();
    } catch (e) {
      print('Error checking expired spots on HomePage load: $e');
    }
  }

  // Helper method to format just time according to device settings
  static String _formatTime(BuildContext context, DateTime dateTime) {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final bool is24HourFormat = mediaQuery.alwaysUse24HourFormat;    return is24HourFormat
        ? DateFormat('HH:mm').format(dateTime) // 24-hour format (14:30)
        : DateFormat('h:mm a').format(dateTime); // 12-hour format (2:30 PM)
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
    required String expectedEndTime, // This now contains remaining time
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
                            const SizedBox(width: 4),
                            Text(
                              'Booked at $timeString',
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
                      onPressed: () => _openQrScannerForBookedSpot(context, spotId, address),
                      icon: const Icon(Icons.qr_code_scanner, size: 18),
                      label: const Text(
                        'Scan QR',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                      onPressed: () => _showUnbookingDialog(context, spotId, address, bookingId),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text(
                        'Unbook',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Method to open QR scanner for booked spots
  void _openQrScannerForBookedSpot(BuildContext context, String spotId, String address) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrScannerPage(
          expectedSpotId: spotId,
          address: address,
          onSuccess: () {
            // Show success message when QR is successfully scanned
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('QR Code verified successfully!'),
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
          },
          onSkip: () {
            // Show message when user skips QR scanning
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white),
                    SizedBox(width: 12),
                    Text('QR scanning skipped'),
                  ],
                ),
                backgroundColor: Colors.orange[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text(
              'Unbook Spot',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to unbook this parking spot?',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Address:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This will make the spot available for others to book.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Unbook'),
          ),
        ],
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Parking spot successfully unbooked!'),
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
      // Handle the case where spot might not exist
      if (e.toString().contains('not-found')) {
        try {
          // Just mark booking as completed since spot doesn't exist
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .update({
            'status': 'spot_deleted',
            'endTime': Timestamp.now(),
            'note': 'Parking spot no longer available',
          });
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Booking ended (spot no longer available)',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (updateError) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Error ending booking: ${updateError.toString()}',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to unbook: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parking Manager')),
        body: const Center(
          child: Text('Please log in to access the app.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Manager'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
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
                  ),                  const SizedBox(height: 5),                  FutureBuilder<String>(
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
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const BookSpotPage()),
                );
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
                  builder: (context, snapshot) {
                    String name = snapshot.data ?? 'User';
                    return Text(
                      'Welcome, $name!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Manage your parking spots and bookings',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.teal.shade600,
                  ),
                ),
                const SizedBox(height: 16),                // Current bookings section
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('userId', isEqualTo: user.uid)
                      .where('status', isEqualTo: 'active')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      final booking = snapshot.data!.docs.first;
                      final data = booking.data() as Map<String, dynamic>;
                      final address = data['address'] as String? ?? 'No address';
                      final startTime = (data['startTime'] as Timestamp).toDate();
                      final timeString = _formatTime(context, startTime);
                      final spotId = data['spotId'] as String? ?? '';
                      final bookingId = booking.id;
                      
                      // Get the spot's availableUntil time to calculate correct remaining time
                      return FutureBuilder<DocumentSnapshot>(
                        future: FirebaseFirestore.instance
                            .collection('parking_spots')
                            .doc(spotId)
                            .get(),
                        builder: (context, spotSnapshot) {
                          String remainingText = 'Loading...';
                          
                          if (spotSnapshot.hasData && spotSnapshot.data!.exists) {
                            final spotData = spotSnapshot.data!.data() as Map<String, dynamic>;
                            final availableUntilTimestamp = spotData['availableUntil'] as Timestamp?;
                            
                            if (availableUntilTimestamp != null) {
                              final availableUntil = availableUntilTimestamp.toDate();
                              final now = DateTime.now();
                              final remaining = availableUntil.difference(now);
                              
                              remainingText = remaining.isNegative 
                                  ? 'Expired' 
                                  : '${remaining.inHours}h ${remaining.inMinutes % 60}m remaining';
                            } else {
                              remainingText = 'No time limit';
                            }
                          } else {
                            remainingText = 'Spot unavailable';
                          }                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current Booking',
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
                children: [
                  Text(
                    'Quick Actions',
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
                    label: 'Book a Parking Spot',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const BookSpotPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildHomeButton(
                    context,
                    icon: Icons.add_location_alt_outlined,
                    label: 'List a New Spot',
                    backgroundColor: Colors.orange.shade400,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => const ListSpotPage()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildHomeButton(
                    context,
                    icon: Icons.receipt_long_outlined,
                    label: 'My Booking History',
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
                    label: 'My Listed Spots',
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
    
    // Final fallback to email username
    if (user.email != null && user.email!.contains('@')) {
      return user.email!.split('@')[0];
    }
    
    return 'User';
  }
}

class QrCodePage extends StatelessWidget {
  final String spotId;
  final String address;

  const QrCodePage({super.key, required this.spotId, required this.address});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot QR Code')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Parking Spot QR Code',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                QrImageView(
                  data: spotId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 16),
                Text(
                  address,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Scan this QR code to verify parking spot',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download QR as PDF'),
                  onPressed: () async {
                    await saveQrCodeAsPdf(
                      context: context,
                      spotId: spotId,
                      address: address,
                      qrData: spotId,
                    );
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.home),
                  label: const Text('Return to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const HomePage()),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
      final availableUntil = (spotData['availableUntil'] as Timestamp?)?.toDate();

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
        );

        // Clear selection and navigate back
        setState(() {
          _selectedSpotId = null;
          _selectedLatLng = null;
          _selectedAddress = null;
        });
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
  }

  // Method to move camera to selected spot
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
                  const SizedBox(height: 10),                  const Text(
                    'Parking Manager',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),                  const SizedBox(height: 5),
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
              return Center(child: Text('Error: \\${snapshot.error}'));
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
                    onTap: () {
                      final spotLocation = LatLng(lat, lng);
                      setState(() {
                        _selectedSpotId = spotId;
                        _selectedLatLng = spotLocation;
                        _selectedAddress = address;
                      });
                      // Move camera to center on the selected spot
                      _moveCameraToSpot(spotLocation);
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
                                    'Lat: \\${_selectedLatLng!.latitude.toStringAsFixed(6)}, Lng: \\${_selectedLatLng!.longitude.toStringAsFixed(6)}',
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
                                          : const Icon(Icons.check_circle_outline),
                                      label: Text(_isLoading ? 'BOOKING...' : 'Confirm Booking'),
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
