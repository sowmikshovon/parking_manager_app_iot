import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../services/bluetooth_service.dart';

class QrScannerWithBluetoothPage extends StatefulWidget {
  final String bookingId;
  final String address;
  
  const QrScannerWithBluetoothPage({
    super.key, 
    required this.bookingId,
    required this.address,
  });

  @override
  State<QrScannerWithBluetoothPage> createState() => _QrScannerWithBluetoothPageState();
}

class _QrScannerWithBluetoothPageState extends State<QrScannerWithBluetoothPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  bool _isFlashOn = false;

  @override
  void dispose() {
    cameraController.dispose();
    BluetoothService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,        actions: [
          IconButton(
            icon: Icon(
              _isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: _isFlashOn ? Colors.yellow : Colors.grey,
            ),
            onPressed: () async {
              await cameraController.toggleTorch();
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
            },
          ),          // Test button for Bluetooth HC05 communication
          IconButton(
            icon: const Icon(Icons.bluetooth_searching, color: Colors.lightBlue),
            tooltip: 'Test Bluetooth HC05 (Gate Close)',
            onPressed: _testBluetoothConnection,
          ),
        ],
      ),
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
        child: Column(
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_scanner,
                          size: 32, color: Colors.teal.shade700),
                      const SizedBox(height: 8),
                      Text(
                        'Scan QR Code for:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.address,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bluetooth, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'IoT Gate Control Enabled',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
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

            // Camera Scanner
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: MobileScanner(
                    controller: cameraController,
                    onDetect: _onQRViewCreated,
                  ),
                ),
              ),
            ),

            // Bottom section with instructions
            Expanded(
              flex: 1,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isProcessing)
                      Column(
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            'Processing QR code and connecting to gate...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      )
                    else
                      Text(
                        'Point your camera at the QR code provided by the parking spot owner',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onQRViewCreated(BarcodeCapture capture) {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? qrData = barcode.rawValue;
      if (qrData != null) {
        _processQrCode(qrData);
        break;
      }
    }
  }

  Future<void> _processQrCode(String qrData) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Step 1: Validate QR code and booking
      final isValid = await _validateBookingAndQr(qrData);
      
      if (isValid) {
        // Step 2: Send Bluetooth command to IoT device
        await _sendBluetoothCommand();
      } else {
        _showErrorDialog('Invalid QR code or booking not found');
      }
    } catch (e) {
      _showErrorDialog('Error processing QR code: $e');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<bool> _validateBookingAndQr(String qrData) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      // Get booking details
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(widget.bookingId)
          .get();

      if (!bookingDoc.exists) return false;

      final bookingData = bookingDoc.data()!;
      final spotId = bookingData['spotId'];
      final bookingUserId = bookingData['userId'];
      
      // Verify QR code matches the spot and user owns the booking
      return qrData == spotId && bookingUserId == user.uid;
    } catch (e) {
      print('Validation error: $e');
      return false;
    }
  }  Future<void> _sendBluetoothCommand() async {
    try {
      // Check if we have a connected device already
      if (BluetoothService.isConnected) {
        await _sendCommandToConnectedDevice();
        return;
      }

      // Show initial setup dialog
      _showProcessingDialog('Preparing Bluetooth connection...');

      // Use the enhanced permission system with comprehensive setup
      final result = await BluetoothService.requestPermissionsWithSetup();
      
      if (!result.hasPermissions) {
        Navigator.of(context).pop(); // Close processing dialog
        
        if (result.shouldOpenSettings) {
          await _showBluetoothSetupDialog(result);
        } else {
          _showErrorDialog(result.message);
        }
        return;
      }

      if (result.shouldOpenSettings) {
        Navigator.of(context).pop(); // Close processing dialog
        await _showPairingGuidanceDialog();
        return;
      }

      // Get paired devices and find HC05
      final pairedDevices = await BluetoothService.getPairedDevices();
      final hc05Devices = await BluetoothService.findHC05Devices();
      
      BluetoothDevice? targetDevice;
      
      if (hc05Devices.isNotEmpty) {
        // Prefer HC05 devices
        targetDevice = hc05Devices.first;
        Navigator.of(context).pop(); // Close processing dialog
        _showProcessingDialog('Connecting to HC05 module: ${targetDevice.name}...');
      } else if (pairedDevices.isNotEmpty) {
        // Use first available paired device
        targetDevice = pairedDevices.first;
        Navigator.of(context).pop(); // Close processing dialog
        _showProcessingDialog('Connecting to device: ${targetDevice.name}...');
      } else {
        Navigator.of(context).pop(); // Close processing dialog
        await _showPairingGuidanceDialog();
        return;
      }

      // Connect to device
      final connected = await BluetoothService.connectToDevice(targetDevice);
      if (!connected) {
        Navigator.of(context).pop(); // Close processing dialog
        _showErrorDialog('Failed to connect to ${targetDevice.name}. Please ensure the device is powered on and in range.');
        return;
      }

      // Send the command
      await _sendCommandToConnectedDevice();

    } catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route is! DialogRoute); // Close any dialogs
        _showErrorDialog('Bluetooth error: $e');
      }
    }
  }

  Future<void> _sendCommandToConnectedDevice() async {
    try {
      // Update dialog
      Navigator.of(context).pop(); // Close any existing dialog
      _showProcessingDialog('Sending gate control command...');

      // Send HC05 compatible command
      final messageSent = await BluetoothService.sendMessage('OPEN_GATE\n');
      if (!messageSent) {
        Navigator.of(context).pop(); // Close processing dialog
        _showErrorDialog('Failed to send command to IoT device');
        return;
      }

      // Listen for response with timeout
      bool responseReceived = false;
      String? receivedResponse;
      
      BluetoothService.listenForMessages().listen((response) {
        receivedResponse = response.trim().toUpperCase();
        if ((receivedResponse == 'GATE_OPENED' || 
             receivedResponse == 'OK' || 
             receivedResponse == 'SUCCESS') && !responseReceived) {
          responseReceived = true;
          Navigator.of(context).pop(); // Close processing dialog
          _showSuccessDialog(receivedResponse!);
        }
      });

      // Set timeout for response
      Future.delayed(const Duration(seconds: 15), () {
        if (!responseReceived && mounted) {
          Navigator.of(context).pop(); // Close processing dialog
          
          if (receivedResponse != null) {
            // We got some response but not the expected one
            _showSuccessDialog('Command sent successfully. Response: $receivedResponse');
          } else {
            // No response received, but command was sent
            _showPartialSuccessDialog();
          }
        }
      });

    } catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route is! DialogRoute);
        _showErrorDialog('Error sending command: $e');
      }
    }
  }

  void _showProcessingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
  void _showSuccessDialog([String? message]) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Gate Opened Successfully!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('QR code verified for:\n${widget.address}'),
            const SizedBox(height: 8),
            if (message != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Response: $message',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open, color: Colors.green.shade700),
                  const SizedBox(width: 8),
                  Text(
                    'Gate opened via IoT command',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close scanner
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBluetoothSetupDialog(BluetoothPermissionResult result) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          result.settingsType == BluetoothSettingsType.appSettings 
            ? Icons.settings 
            : Icons.bluetooth_disabled,
          color: Colors.orange,
          size: 48,
        ),
        title: const Text('Bluetooth Setup Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(result.message),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
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
                          'Steps to Enable IoT Features:',
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
                    result.settingsType == BluetoothSettingsType.appSettings
                      ? '1. Open app settings\n2. Enable Bluetooth permissions\n3. Return to the app'
                      : '1. Enable Bluetooth\n2. Pair with HC05 module\n3. Return to scan again',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open Settings'),
            onPressed: () async {
              Navigator.of(context).pop();
              if (result.settingsType != null) {
                await BluetoothService.openBluetoothSettings(result.settingsType!);
              }
              Navigator.of(context).pop(); // Return to previous screen
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

  Future<void> _showPairingGuidanceDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.bluetooth_searching, color: Colors.blue, size: 48),
        title: const Text('Pair with HC05 Module'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To enable automatic gate control, please pair with your HC05 Bluetooth module:',
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
                    '1. Ensure HC05 module is powered on\n'
                    '2. Open Bluetooth settings on your phone\n'
                    '3. Look for "HC-05" or similar device\n'
                    '4. Pair with PIN: 1234 or 0000\n'
                    '5. Return to this app and try again',
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
                Icon(Icons.lightbulb_outline, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The HC05 LED should be blinking slowly when ready to pair.',
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
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to previous screen
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.bluetooth),
            label: const Text('Open Bluetooth'),
            onPressed: () async {
              Navigator.of(context).pop();
              await BluetoothService.openBluetoothSettings(BluetoothSettingsType.bluetoothPairing);
              Navigator.of(context).pop(); // Return to previous screen
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

  void _showPartialSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning, color: Colors.orange, size: 48),
        title: const Text('Command Sent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('QR code verified for:\n${widget.address}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_connected, color: Colors.orange.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Gate command sent successfully, but no response received. The gate may still open.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close scanner
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],      ),
    );
  }  // Test method to quickly test Bluetooth HC05 communication (gate_close command)
  Future<void> _testBluetoothConnection() async {
    try {
      // Show processing dialog
      _showProcessingDialog('Testing Bluetooth connection...');

      // Check Bluetooth permissions
      final permissionResult = await BluetoothService.requestPermissionsWithSetup();
      if (!permissionResult.hasPermissions) {
        Navigator.of(context).pop(); // Close processing dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bluetooth permissions required: ${permissionResult.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      // Get paired devices and find HC05
      final pairedDevices = await BluetoothService.getPairedDevices();
      final hc05Devices = await BluetoothService.findHC05Devices();
      
      BluetoothDevice? targetDevice;
      
      if (hc05Devices.isNotEmpty) {
        // Prefer HC05 devices
        targetDevice = hc05Devices.first;
      } else if (pairedDevices.isNotEmpty) {
        // Use first available paired device
        targetDevice = pairedDevices.first;
      } else {
        Navigator.of(context).pop(); // Close processing dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No paired Bluetooth devices found. Please pair with HC05 first.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Connect to HC05
      final connected = await BluetoothService.connectToDevice(targetDevice);
      if (!connected) {
        Navigator.of(context).pop(); // Close processing dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${targetDevice.name}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }      // Send test command
      final messageSent = await BluetoothService.sendMessage('gate_close\n');
      if (!messageSent) {
        Navigator.of(context).pop(); // Close processing dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send test command'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Listen for response with timeout
      bool responseReceived = false;
      String? receivedResponse;
      
      BluetoothService.listenForMessages().listen((response) {
        receivedResponse = response.trim();
        if (!responseReceived) {
          responseReceived = true;
          Navigator.of(context).pop(); // Close processing dialog
          
          // Show response in snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Response received: $receivedResponse'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });

      // Set timeout for response
      Future.delayed(const Duration(seconds: 10), () {
        if (!responseReceived && mounted) {
          Navigator.of(context).pop(); // Close processing dialog
          
          if (receivedResponse != null && receivedResponse!.isNotEmpty) {
            // We got some response
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('⚠️ Unexpected response: $receivedResponse'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          } else {
            // No response received, but command was sent
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('📤 Command sent, but no response received'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 4),
              ),
            );
          }
        }
      });

    } catch (e) {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route is! DialogRoute);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
