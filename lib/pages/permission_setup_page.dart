import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/bluetooth_service.dart';
import '../widgets/bluetooth_permission_helper.dart';
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
      final user = FirebaseAuth.instance.currentUser;

      // Step 1: Request comprehensive permissions for the app
      setState(() {
        _statusMessage = 'Requesting Bluetooth and location permissions...';
      });

      final result = await BluetoothService.requestPermissionsWithSetup();

      if (!result.hasPermissions || result.shouldOpenSettings) {
        setState(() {
          _permissionsGranted = false;
          _statusMessage = result.message;
        });
        return;
      }

      // Step 2: Check for HC-05 pairing
      setState(() {
        _statusMessage = 'Checking for HC-05 device pairing...';
      });

      final hc05Devices = await BluetoothService.findHC05Devices();

      if (hc05Devices.isEmpty) {
        // No HC-05 devices found, but permissions are granted
        // Show pairing guidance
        setState(() {
          _permissionsGranted = false;
          _statusMessage =
              'Bluetooth permissions granted. HC-05 module pairing required for IoT features.';
        });
        return;
      }

      // Step 3: All requirements met
      setState(() {
        _permissionsGranted = true;
        _statusMessage = 'Setup complete! HC-05 device found and ready to use.';
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
      final result =
          await BluetoothPermissionHelper.requestPermissionsWithDialog(context);
      if (result) {
        _initializePermissions();
      }
    }
  }

  Future<void> _showPairingGuidance() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon:
            const Icon(Icons.bluetooth_searching, color: Colors.blue, size: 48),
        title: const Text('Pair with HC-05 Module'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To enable automatic gate control, please pair with your HC-05 Bluetooth module:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pairing Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '1. Ensure HC-05 module is powered on\n'
                        '2. Open Bluetooth settings on your phone\n'
                        '3. Look for "HC-05" or similar device\n'
                        '4. Pair with PIN: 1234 or 0000\n'
                        '5. Return to this app and retry setup',
                        style: TextStyle(
                          color: Colors.blue.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline,
                        color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The HC-05 LED should be blinking slowly when ready to pair.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber.shade700,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('I\'ll Do This Later'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open Bluetooth Settings'),
            onPressed: () async {
              Navigator.of(context).pop();
              await BluetoothService.openBluetoothSettings(
                BluetoothSettingsType.bluetoothPairing,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retrySetup() async {
    _initializePermissions();
  }

  String _getSetupTitle() {
    if (_statusMessage.contains('HC-05') ||
        _statusMessage.contains('pairing')) {
      return 'HC-05 Device Pairing Required';
    } else if (_statusMessage.contains('permission') ||
        _statusMessage.contains('Bluetooth')) {
      return 'Bluetooth Permissions Required';
    } else {
      return 'IoT Features Setup';
    }
  }

  String _getSetupDescription() {
    if (_statusMessage.contains('HC-05') ||
        _statusMessage.contains('pairing')) {
      return 'Bluetooth permissions are granted, but no HC-05 device is paired. To enable automatic gate control, please pair with your HC-05 Bluetooth module.';
    } else if (_statusMessage.contains('permission') ||
        _statusMessage.contains('Bluetooth')) {
      return 'This app needs Bluetooth and location permissions to communicate with HC-05 modules for automatic gate control.';
    } else {
      return 'This app can communicate with HC-05 Bluetooth modules to control parking gates automatically. Please complete the setup to enable this feature.';
    }
  }

  Widget _buildActionButtons() {
    if (_statusMessage.contains('HC-05') ||
        _statusMessage.contains('pairing')) {
      // HC-05 pairing required
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showPairingGuidance,
              icon: const Icon(Icons.bluetooth_searching),
              label: const Text('Pair HC-05 Module'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _retrySetup,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Check Again'),
                ),
              ),
              Expanded(
                child: TextButton(
                  onPressed: _continueWithoutPermissions,
                  child: const Text('Skip for Now'),
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      // Bluetooth permissions required
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _requestPermissionsAgain,
              icon: const Icon(Icons.bluetooth),
              label: const Text('Setup Bluetooth'),
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
  }

  IconData _getStatusIcon() {
    if (_statusMessage.contains('HC-05') ||
        _statusMessage.contains('pairing')) {
      return Icons.bluetooth_searching;
    } else if (_statusMessage.contains('permission') ||
        _statusMessage.contains('Bluetooth')) {
      return Icons.bluetooth_disabled;
    } else {
      return Icons.warning;
    }
  }

  Color _getStatusIconColor() {
    if (_statusMessage.contains('HC-05') ||
        _statusMessage.contains('pairing')) {
      return Colors.blue.shade600;
    } else if (_statusMessage.contains('permission') ||
        _statusMessage.contains('Bluetooth')) {
      return Colors.orange.shade600;
    } else {
      return Colors.red.shade600;
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
                    'Parking Manager IoT',
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
                      color: Colors.white.withOpacity(0.9),
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
                      'You can enable IoT features later in the app settings.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
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
