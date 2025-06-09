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
      
      // Request comprehensive permissions for the app
      setState(() {
        _statusMessage = 'Requesting Bluetooth and location permissions...';
      });
      
      final result = await BluetoothService.requestPermissionsWithSetup();
      
      if (result.hasPermissions && !result.shouldOpenSettings) {
        setState(() {
          _permissionsGranted = true;
          _statusMessage = 'All permissions granted! Ready to use IoT features.';
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
      } else {
        setState(() {
          _permissionsGranted = false;
          _statusMessage = result.message;
        });
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
      final result = await BluetoothPermissionHelper.requestPermissionsWithDialog(context);
      if (result) {
        _initializePermissions();
      }
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
          child: Padding(
            padding: const EdgeInsets.all(24.0),
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
                            Icons.bluetooth_disabled,
                            color: Colors.orange.shade600,
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
                        
                        if (!_isCheckingPermissions && !_permissionsGranted) ...[
                          const SizedBox(height: 24),
                          
                          // Explanation text
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
                                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'IoT Features Require Permissions',
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
                                  'This app can communicate with HC05 Bluetooth modules to control parking gates automatically. To enable this feature, please grant Bluetooth and location permissions.',
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
                          Row(
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
                          ),
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
    );
  }
}
