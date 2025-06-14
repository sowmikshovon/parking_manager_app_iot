import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/bluetooth_service.dart';
import 'login_page.dart';
import 'home_page.dart';

/// Page for setting up permissions at app startup
class PermissionSetupPage extends StatefulWidget {
  const PermissionSetupPage({super.key});

  @override
  State<PermissionSetupPage> createState() => _PermissionSetupPageState();
}

class _PermissionSetupPageState extends State<PermissionSetupPage> {
  bool _isCheckingPermissions = true;
  bool _permissionsGranted = false;
  String _statusMessage = 'Checking required permissions...';

  @override
  void initState() {
    super.initState();
    _initializePermissions();
  }

  Future<void> _initializePermissions() async {
    setState(() {
      _isCheckingPermissions = true;
      _statusMessage = 'Initializing app permissions...';
    });

    try {
      // Check if user is already authenticated
      final user = FirebaseAuth.instance
          .currentUser; // Step 1: Request basic permissions for the app (not HC-05 specific)
      setState(() {
        _statusMessage = 'Requesting camera and location permissions...';
      });

      final hasBasicPermissions = await BluetoothService.requestPermissions();

      if (!hasBasicPermissions) {
        setState(() {
          _permissionsGranted = false;
          _statusMessage =
              'Camera and location permissions are required for the app to function properly.';
        });
        return;
      } // Step 2: Basic permissions granted - setup complete
      setState(() {
        _permissionsGranted = true;
        _statusMessage =
            'Basic permissions granted! App is ready to use. HC-05 pairing will be checked when using QR scanner.';
      });

      // Small delay to show success message
      await Future.delayed(const Duration(seconds: 1));

      // Navigate to appropriate page
      if (mounted) {
        if (user != null) {
          // User is logged in, go to home
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          // User not logged in, go to login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
    } catch (e) {
      setState(() {
        _permissionsGranted = false;
        _statusMessage = 'Error setting up permissions: $e';
      });
    } finally {
      setState(() {
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestPermissionsAgain() async {
    if (mounted) {
      _initializePermissions(); // Just retry initialization
    }
  }

  String _getSetupTitle() {
    if (_statusMessage.contains('permission')) {
      return 'App Permissions Required';
    } else {
      return 'App Setup';
    }
  }

  String _getSetupDescription() {
    if (_statusMessage.contains('permission')) {
      return 'This app needs camera and location permissions to function properly. Bluetooth features will be checked when using IoT controls.';
    } else {
      return 'This app can communicate with IoT devices to control parking gates automatically. Basic permissions are required to continue.';
    }
  }

  Widget _buildActionButtons() {
    // Only basic permissions required
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _requestPermissionsAgain,
            icon: const Icon(Icons.check_circle),
            label: const Text('Grant Permissions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextButton(
            onPressed: _continueWithoutPermissions,
            child: const Text('Skip for Now'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStatusIcon() {
    if (_statusMessage.contains('permission')) {
      return Icons.security;
    } else {
      return Icons.check_circle;
    }
  }

  Color _getStatusIconColor() {
    if (_statusMessage.contains('permission')) {
      return Colors.orange.shade600;
    } else {
      return Colors.green.shade600;
    }
  }

  void _continueWithoutPermissions() {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade600,
              Colors.teal.shade400,
              Colors.teal.shade200,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom -
                    48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.directions_car,
                      size: 80,
                      color: Colors.teal.shade700,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // App Title
                  const Text(
                    'IoT Parking',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Subtitle
                  Text(
                    'Smart parking with IoT gate control',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Main content card
                  Card(
                    elevation: 8,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          if (_isCheckingPermissions) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                          ] else if (_permissionsGranted) ...[
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            Icon(
                              _getStatusIcon(),
                              color: _getStatusIconColor(),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                          ],
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (!_isCheckingPermissions &&
                              !_permissionsGranted) ...[
                            const SizedBox(height: 24),

                            // Explanation text with HC-05 guidance
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline,
                                          color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _getSetupTitle(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _getSetupDescription(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Action buttons
                            _buildActionButtons(),
                          ],
                        ],
                      ),
                    ),
                  ),

                  if (!_isCheckingPermissions && !_permissionsGranted) ...[
                    const SizedBox(height: 16),
                    Text(
                      'You can enable specific IoT features (like HC-05 pairing) when needed.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
