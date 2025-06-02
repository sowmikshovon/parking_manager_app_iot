import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'firebase_options.dart';
import 'package:intl/intl.dart'; // Add intl import for date formatting
import 'qr_pdf_util.dart';
import 'dart:async'; // Add Timer import for background tracking

import './pages/qr_scanner_page.dart';
import './pages/profile_page.dart';
//import './pages/qr_code_page.dart';
//import './pages/login_page.dart';
//import './pages/listing_history_page.dart';

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
  bool _obscurePassword = true;

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? "An unknown error occurred.";
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
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'email-already-in-use') {
          _error = 'This email address is already in use.';
        } else {
          _error = e.message ?? 'An unknown error occurred.';
        }
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
              final isAvailable = data['isAvailable'] == true;

              // Check availability status based on time
              final availableUntilTimestamp =
                  data['availableUntil'] as Timestamp?;
              final DateTime? availableUntil =
                  availableUntilTimestamp?.toDate();
              final bool isTimeExpired = availableUntil != null &&
                  availableUntil.isBefore(DateTime.now());

              String statusText = 'Available';
              Color statusColor = Colors.green;
              if (!isAvailable) {
                statusText = 'Booked';
                statusColor = Colors.orange;
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

  // Helper method to check if parking spot exists and clean up orphaned bookings
  static Future<void> _cleanupOrphanedBooking(
      String bookingId, String spotId) async {
    try {
      // Check if the parking spot still exists
      final spotDoc = await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(spotId)
          .get();

      // If spot doesn't exist, mark booking as completed and remove from active bookings
      if (!spotDoc.exists) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'spot_deleted',
          'endTime': Timestamp.now(),
          'note': 'Parking spot was deleted by owner',
        });
      }
    } catch (e) {
      // If there's an error checking the spot, it likely doesn't exist
      // Mark the booking as completed
      try {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({
          'status': 'spot_deleted',
          'endTime': Timestamp.now(),
          'note': 'Parking spot no longer available',
        });
      } catch (updateError) {
        // If we can't update the booking, at least we tried
        print('Error cleaning up orphaned booking: $updateError');
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
              final address = data['address'] as String? ?? 'No address';
              final status = data['status'] as String? ?? 'Unknown';
              final bookingTimeTimestamp = data['bookingTime'] as Timestamp?;
              final endTimeTimestamp = data['endTime'] as Timestamp?;
              final bookingTime = bookingTimeTimestamp != null
                  ? _formatDateTime(
                      context, bookingTimeTimestamp.toDate().toLocal())
                  : 'N/A';
              final endTime = endTimeTimestamp != null
                  ? _formatDateTime(
                      context, endTimeTimestamp.toDate().toLocal())
                  : 'N/A';

              return Card(
                child: ListTile(
                  title: Text(address),
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
                              } else {
                                // Spot no longer exists, just mark booking as completed
                                await FirebaseFirestore.instance
                                    .collection('bookings')
                                    .doc(booking.id)
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
                                      .doc(booking.id)
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

class ListSpotPage extends StatefulWidget {
  const ListSpotPage({super.key});

  @override
  State<ListSpotPage> createState() => _ListSpotPageState();
}

class _ListSpotPageState extends State<ListSpotPage> {
  LatLng? _selectedLatLng;
  static const LatLng _initialLatLng = LatLng(23.7624, 90.3785);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialLatLng,
              zoom: 14,
            ),
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
            myLocationButtonEnabled: true,
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
                        builder: (context) =>
                            AddressEntryPage(selectedLatLng: _selectedLatLng!),
                      ),
                    );
                  },
                  child: const Text('Next'),
                ),
              ),
            ),
        ],
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
    final bool is24HourFormat = mediaQuery.alwaysUse24HourFormat;

    return is24HourFormat
        ? DateFormat('HH:mm').format(dateTime) // 24-hour format (14:30)
        : DateFormat('h:mm a').format(dateTime); // 12-hour format (2:30 PM)
  }

  Future<Map<String, String>> _getUserDetails(User user) async {
    String userName = 'User'; // Default
    String profileImageUrl = ''; // Default

    // Try Firebase Auth display name first if available
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      userName = user.displayName!;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;

        // Prioritize Firestore 'name' field if it exists and is not empty
        String firestoreFullName = data['name'] as String? ?? '';
        if (firestoreFullName.isNotEmpty) {
          userName = firestoreFullName;
        } else {
          // Fallback to constructing name from firstName and lastName if 'name' is not available
          final firstName = data['firstName'] as String? ?? '';
          final lastName = data['lastName'] as String? ?? '';
          if (firstName.isNotEmpty && lastName.isNotEmpty) {
            userName = '$firstName $lastName'.trim();
          } else if (firstName.isNotEmpty) {
            userName = firstName.trim();
          } else if (lastName.isNotEmpty) {
            userName = lastName.trim();
          }
          // If userName is still 'User' (meaning no name from auth and no specific name from Firestore fields)
          // it will be handled by the fallback logic below.
        }
        profileImageUrl = data['profileImageUrl'] as String? ?? '';
      }
    } catch (e) {
      print('Error getting user details from Firestore: $e');
      // In case of error, defaults or auth data (if already set to userName) will be used.
    }

    // Fallback to email if userName is still the generic 'User' or empty,
    // and auth display name was also null/empty.
    if ((userName == 'User' || userName.trim().isEmpty) &&
        (user.displayName == null || user.displayName!.isEmpty)) {
      if (user.email != null && user.email!.contains('@')) {
        userName = user.email!.split('@')[0];
      }
    }

    // Final fallback to ensure userName is not empty.
    if (userName.trim().isEmpty) {
      userName = 'User';
    }

    return {'userName': userName, 'profileImageUrl': profileImageUrl};
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
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () =>
                _showUnbookingDialog(context, spotId, address, bookingId),
            splashColor: Colors.orange.withValues(alpha: 0.2),
            highlightColor: Colors.orange.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
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
                  Column(
                    children: [
                      Icon(
                        Icons.touch_app,
                        color: Colors.orange.shade600,
                        size: 16,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to unbook',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.orange.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
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
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Failed to unbook: ${e.toString()}'),
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

  Widget _buildDrawerListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          highlightColor:
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
          onTap: () {
            Navigator.pop(context); // Close the drawer
            onTap(); // Perform the action
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    color: Colors.grey[400],
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Method to automatically expire a booking and move it to history
  Future<void> _expireBooking(String bookingId, String spotId) async {
    try {
      // Update the booking status to expired
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
        'status': 'expired',
        'endTime': Timestamp.now(),
      });

      // Update the parking spot to be available again
      await FirebaseFirestore.instance
          .collection('parking_spots')
          .doc(spotId)
          .update({'isAvailable': true});

      print('Booking $bookingId automatically expired and moved to history');
    } catch (e) {
      print('Error expiring booking $bookingId: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Parking Manager',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        // The hamburger icon will appear automatically due to the drawer property
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            if (user != null)
              FutureBuilder<Map<String, String>>(
                future: _getUserDetails(user), // Uses the updated method
                builder: (context, snapshot) {
                  String userName;
                  String profileImageUrl = ''; // Default to empty
                  String userEmail = user.email ?? 'No email provided';

                  if (snapshot.connectionState == ConnectionState.done) {
                    if (snapshot.hasData) {
                      // Use fetched data, fallback to auth display name or 'User'
                      userName = snapshot.data!['userName'] ??
                          (user.displayName ?? 'User');
                      profileImageUrl = snapshot.data!['profileImageUrl'] ?? '';
                    } else {
                      // Error state: Fallback to auth display name or 'User'
                      print(
                          'Error fetching user details for drawer: ${snapshot.error}');
                      userName = user.displayName ?? 'User';
                      // profileImageUrl remains empty
                    }
                  } else {
                    // Waiting state: Show auth display name or 'Loading...'
                    // Avoid showing "Loading..." if auth name is available, provides a better UX.
                    userName = user.displayName ?? 'Loading...';
                    // profileImageUrl remains empty until data is loaded
                  }

                  // If after all logic, userName is still generic ('User' or 'Loading...')
                  // and auth display name was empty, try deriving from email.
                  if ((userName == 'User' || userName == 'Loading...') &&
                      (user.displayName == null || user.displayName!.isEmpty)) {
                    if (user.email != null &&
                        user.email!.isNotEmpty &&
                        user.email!.contains('@')) {
                      userName = user.email!.split('@')[0];
                    } else {
                      // If email also doesn't help, ensure it's 'User' not 'Loading...'
                      userName = 'User';
                    }
                  }

                  // Final check to ensure userName is not empty if all else fails.
                  if (userName.trim().isEmpty) {
                    userName = 'User';
                  }

                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.teal.shade400,
                          Colors.teal.shade600,
                          Colors.teal.shade800,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 15, 20, 15), // Adjusted padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.white,
                                  backgroundImage: profileImageUrl.isNotEmpty
                                      ? NetworkImage(profileImageUrl)
                                      : null,
                                  child: profileImageUrl.isEmpty
                                      ? Text(
                                          userName.isNotEmpty
                                              ? userName[0].toUpperCase()
                                              : 'U',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade700,
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Hello!',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color:
                                            Colors.white.withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.email_outlined,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    userEmail,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.directions_car,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Parking Manager',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            else
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Text(
                  'Parking Manager',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
              ),
            _buildDrawerListTile(
              context,
              icon: Icons.account_circle_outlined,
              title: 'Profile',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
            ),
            _buildDrawerListTile(
              context,
              icon: Icons.add_location_alt_outlined,
              title: 'List a New Spot',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ListSpotPage()),
                );
              },
            ),
            _buildDrawerListTile(
              context,
              icon: Icons.history_edu_outlined,
              title: 'My Listed Spots',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ListingHistoryPage()),
                );
              },
            ),
            _buildDrawerListTile(
              context,
              icon: Icons.receipt_long_outlined,
              title: 'My Booking History',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const BookingHistoryPage()),
                );
              },
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.grey.shade300,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            _buildDrawerListTile(
              context,
              icon: Icons.logout,
              title: 'Logout',
              onTap: () async {
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade50,
              Colors.white,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Welcome Card
                if (user != null)
                  Card(
                    elevation: 6,
                    shadowColor: Colors.teal.withValues(alpha: 0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          colors: [
                            Colors.white,
                            Colors.teal.shade50,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: FutureBuilder<Map<String, String>>(
                        future: _getUserDetails(user),
                        builder: (context, snapshot) {
                          String welcomeName = 'User';
                          if (snapshot.connectionState ==
                                  ConnectionState.done &&
                              snapshot.hasData) {
                            welcomeName = snapshot.data!['userName'] ?? 'User';
                          } else if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            welcomeName = 'Loading...';
                          } else if (snapshot.hasError) {
                            // Keep default welcomeName
                          }
                          if (welcomeName == 'User' &&
                              (user.displayName == null ||
                                  user.displayName!.isEmpty) &&
                              user.email != null &&
                              user.email!.contains('@')) {
                            welcomeName = user.email!.split('@')[0];
                          }

                          return Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.teal.shade100,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      Icons.waving_hand,
                                      color: Colors.teal.shade700,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back!',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          welcomeName,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal.shade800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.teal.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.teal.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Ready to find your perfect parking spot?',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.teal.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                // Quick Action Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.flash_on,
                              color: Colors.teal.shade700,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Quick Action',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Book a Parking Spot button
                              _buildHomeButton(
                                context,
                                icon: Icons.search_outlined,
                                label: 'Book a Parking Spot',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const BookSpotPage(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),

                              // Booked Spots Section
                              if (user != null)
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('bookings')
                                      .where('userId', isEqualTo: user.uid)
                                      .where('status', isEqualTo: 'booked')
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const SizedBox(
                                        height: 50,
                                        child: Center(
                                            child: CircularProgressIndicator()),
                                      );
                                    }

                                    if (snapshot.hasError) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.red.shade200,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red[600],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                'Error loading booked spots',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red[700],
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }

                                    final bookings = snapshot.data?.docs ?? [];

                                    if (bookings.isNotEmpty) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Booked spots header
                                          Row(
                                            children: [
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Icon(
                                                  Icons.local_parking,
                                                  color: Colors.orange.shade700,
                                                  size: 16,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Your Booked Spots',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.shade600,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Text(
                                                  '${bookings.length}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                              height: 12), // Booked spots list
                                          ...bookings.map((booking) {
                                            final data = booking.data()
                                                as Map<String, dynamic>;
                                            final spotId =
                                                data['spotId'] as String? ??
                                                    'Unknown';
                                            final address =
                                                data['address'] as String? ??
                                                    'No address';
                                            final bookingTime =
                                                data['bookingTime']
                                                    as Timestamp?;
                                            final timeString =
                                                bookingTime != null
                                                    ? _formatTime(
                                                        context,
                                                        bookingTime
                                                            .toDate()
                                                            .toLocal())
                                                    : 'Unknown';

                                            return Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: FutureBuilder<
                                                  DocumentSnapshot>(
                                                future: FirebaseFirestore
                                                    .instance
                                                    .collection('parking_spots')
                                                    .doc(spotId)
                                                    .get(),
                                                builder:
                                                    (context, spotSnapshot) {
                                                  // Check if parking spot exists
                                                  if (spotSnapshot.hasData &&
                                                      !spotSnapshot
                                                          .data!.exists) {
                                                    // Parking spot doesn't exist - this is an orphaned booking
                                                    // Clean it up asynchronously and don't display it

                                                    WidgetsBinding.instance
                                                        .addPostFrameCallback(
                                                            (_) {
                                                      BookingHistoryPage
                                                          ._cleanupOrphanedBooking(
                                                              booking.id,
                                                              spotId);
                                                    });
                                                    return const SizedBox
                                                        .shrink(); // Hide this booking from UI
                                                  }

                                                  // Default to 2 hours if spot data is not available
                                                  int parkingDurationHours = 2;

                                                  if (spotSnapshot.hasData &&
                                                      spotSnapshot
                                                          .data!.exists) {
                                                    final spotData =
                                                        spotSnapshot.data!
                                                                .data()
                                                            as Map<String,
                                                                dynamic>?;
                                                    parkingDurationHours =
                                                        spotData?['parkingDurationHours']
                                                                as int? ??
                                                            24;
                                                  } // Calculate remaining time until end and handle expiration
                                                  String remainingTime =
                                                      'Unknown';
                                                  if (bookingTime != null) {
                                                    final endTime = bookingTime
                                                        .toDate()
                                                        .toLocal()
                                                        .add(Duration(
                                                            hours:
                                                                parkingDurationHours));
                                                    final now = DateTime.now();
                                                    final difference =
                                                        endTime.difference(now);

                                                    if (difference.isNegative) {
                                                      // Automatically expire the booking
                                                      _expireBooking(
                                                          booking.id, spotId);
                                                      return const SizedBox
                                                          .shrink(); // Don't show expired bookings
                                                    } else {
                                                      final hours =
                                                          difference.inHours;
                                                      final minutes =
                                                          difference.inMinutes %
                                                              60;
                                                      if (hours > 0) {
                                                        remainingTime =
                                                            '${hours}h ${minutes}m remaining';
                                                      } else {
                                                        remainingTime =
                                                            '${minutes}m remaining';
                                                      }
                                                    }
                                                  }

                                                  return _buildBookedSpotCard(
                                                    context,
                                                    spotId: spotId,
                                                    address: address,
                                                    timeString: timeString,
                                                    bookingId: booking.id,
                                                    expectedEndTime:
                                                        remainingTime,
                                                  );
                                                },
                                              ),
                                            );
                                          }).toList(),
                                          const SizedBox(height: 8),
                                        ],
                                      );
                                    }

                                    return const SizedBox.shrink();
                                  },
                                ),

                              // Additional features hint
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.menu,
                                      color: Colors.grey[600],
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Explore more features in the menu',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.grey[400],
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// QrCodePage widget displays a QR code for a given parking spot

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

  @override
  void initState() {
    super.initState();
    // Trigger an immediate check when the page loads
    ExpiredSpotTracker.checkAndUpdateExpiredSpots();
  }

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

  void _openQrScanner() {
    if (_selectedSpotId == null || _selectedAddress == null) {
      setState(() {
        _error = 'Please select a parking spot first.';
      });
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QrScannerPage(
          expectedSpotId: _selectedSpotId!,
          address: _selectedAddress!,
          onSuccess: () {
            // This will be called when QR scan is successful
            _bookSpot(_selectedSpotId!, _selectedAddress!);
          },
          onSkip: () {
            // This will be called when user chooses to continue without QR scan
            Navigator.of(context).pop(); // Close scanner page
            _bookSpot(_selectedSpotId!, _selectedAddress!);
          },
        ),
      ),
    );
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
                              // QR Scanner Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _openQrScanner(),
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text('Scan QR Code'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal[600],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Regular Confirm Booking Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : () => _bookSpot(
                                            _selectedSpotId!,
                                            _selectedAddress ?? '',
                                          ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
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
                                      : const Text(
                                          'Book without QR Scan',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
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
        ),
      ),
    );
  }
}
