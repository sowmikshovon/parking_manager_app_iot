import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../services/bluetooth_service.dart';
import '../services/parking_session_service.dart';
import '../utils/snackbar_utils.dart';
import 'home_page.dart';

class QrScannerWithBluetoothPage extends StatefulWidget {
  final String bookingId;
  final String address;

  const QrScannerWithBluetoothPage({
    super.key,
    required this.bookingId,
    required this.address,
  });

  @override
  State<QrScannerWithBluetoothPage> createState() =>
      _QrScannerWithBluetoothPageState();
}

class _QrScannerWithBluetoothPageState
    extends State<QrScannerWithBluetoothPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController cameraController = MobileScannerController();
  bool _isProcessing = false;
  bool _isFlashOn = false;
  bool _scannerPaused = false;
  bool _hc05CheckCompleted = false;
  StreamSubscription<String>? _bluetoothSubscription;

  @override
  void initState() {
    super.initState();
    _checkHC05Pairing();
  }

  Future<void> _checkHC05Pairing() async {
    try {
      // Check if HC-05 devices are paired
      final hc05Devices = await BluetoothService.findHC05Devices();

      if (hc05Devices.isEmpty) {
        // No HC-05 devices found, show pairing dialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showHC05PairingDialog();
        });
      } else {
        // HC-05 devices found, allow scanning
        setState(() {
          _hc05CheckCompleted = true;
        });
      }
    } catch (e) {
      // Error checking devices, show pairing dialog as fallback
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHC05PairingDialog();
      });
    }
  }

  Future<void> _showHC05PairingDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon:
            const Icon(Icons.bluetooth_searching, color: Colors.blue, size: 48),
        title: const Text('HC-05 Device Required'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'To scan QR codes and control parking gates, you need to pair with an HC-05 Bluetooth module.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Pairing Instructions:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '1. Turn on your HC-05 device\n'
                        '2. Open Bluetooth settings on your phone\n'
                        '3. Look for "HC-05" in available devices\n'
                        '4. Pair with PIN: 1234 or 0000\n'
                        '5. Return to this app',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Go back to previous page
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _checkHC05Pairing(); // Retry check
            },
            child: const Text('Check Again'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.settings),
            label: const Text('Open Bluetooth Settings'),
            onPressed: () async {
              Navigator.of(context).pop();
              await BluetoothService.openBluetoothSettings(
                BluetoothSettingsType.bluetoothPairing,
              );
              // Check again after user returns
              _checkHC05Pairing();
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

  @override
  void dispose() {
    cameraController.dispose();
    _bluetoothSubscription?.cancel();
    BluetoothService.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          if (_hc05CheckCompleted)
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
            ),
        ],
      ),
      body: !_hc05CheckCompleted
          ? Container(
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
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Checking HC-05 device pairing...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Container(
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bluetooth,
                                      size: 16, color: Colors.blue.shade700),
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
                                const CircularProgressIndicator(
                                    color: Colors.white),
                                const SizedBox(height: 16),
                                Text(
                                  _scannerPaused
                                      ? 'Waiting for gate response...'
                                      : 'Processing QR code and connecting to gate...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            )
                          else if (_scannerPaused)
                            Column(
                              children: [
                                Icon(
                                  Icons.pause_circle_outline,
                                  color: Colors.orange.shade300,
                                  size: 32,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Scanner paused. Listening for IoT response...',
                                  style: TextStyle(
                                    color: Colors.orange.shade200,
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
      floatingActionButton: !_hc05CheckCompleted
          ? FloatingActionButton(
              onPressed: _checkHC05Pairing,
              backgroundColor: Colors.teal,
              child: const Icon(Icons.refresh, color: Colors.white),
            )
          : null,
    );
  }

  void _onQRViewCreated(BarcodeCapture capture) {
    if (_isProcessing || _scannerPaused) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final String? qrData = barcode.rawValue;
      if (qrData != null) {
        // Pause scanner after QR detection
        setState(() => _scannerPaused = true);
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
        _resumeScanner(); // Resume scanner for invalid QR
        _showErrorDialog('Invalid QR code or booking not found');
      }
    } catch (e) {
      _resumeScanner(); // Resume scanner on error
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
      final bookingUserId = bookingData[
          'userId']; // Verify QR code matches the spot and user owns the booking
      return qrData == spotId && bookingUserId == user.uid;
    } catch (e) {
      // Remove print statement for production - use proper logging instead
      return false;
    }
  }

  Future<void> _sendBluetoothCommand() async {
    // Store context before async operations
    final navigator = Navigator.of(context);

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
        navigator.pop(); // Close processing dialog

        if (result.shouldOpenSettings) {
          await _showBluetoothSetupDialog(result);
        } else {
          _showErrorDialog(result.message);
        }
        return;
      }

      if (result.shouldOpenSettings) {
        navigator.pop(); // Close processing dialog
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
        navigator.pop(); // Close processing dialog
        _showProcessingDialog(
            'Connecting to HC05 module: ${targetDevice.name}...');
      } else if (pairedDevices.isNotEmpty) {
        // Use first available paired device
        targetDevice = pairedDevices.first;
        navigator.pop(); // Close processing dialog
        _showProcessingDialog('Connecting to device: ${targetDevice.name}...');
      } else {
        navigator.pop(); // Close processing dialog
        await _showPairingGuidanceDialog();
        return;
      }

      // Connect to device
      final connected = await BluetoothService.connectToDevice(targetDevice);
      if (!connected) {
        navigator.pop(); // Close processing dialog
        _showErrorDialog(
            'Failed to connect to ${targetDevice.name}. Please ensure the device is powered on and in range.');
        return;
      }

      // Send the command
      await _sendCommandToConnectedDevice();
    } catch (e) {
      if (mounted) {
        navigator
            .popUntil((route) => route is! DialogRoute); // Close any dialogs
        _showErrorDialog('Bluetooth error: $e');
      }
    }
  }

  Future<void> _sendCommandToConnectedDevice() async {
    // Store context before async operations
    final navigator = Navigator.of(context);

    try {
      // Update dialog
      navigator.pop(); // Close any existing dialog
      _showProcessingDialog('Sending gate control command...');

      // Cancel any existing subscription before creating a new one
      await _bluetoothSubscription?.cancel();

      // Send HC05 compatible command
      final messageSent = await BluetoothService.sendMessage('OPEN_GATE\n');
      if (!messageSent) {
        navigator.pop(); // Close processing dialog
        _resumeScanner(); // Resume scanner on failure
        _showErrorDialog('Failed to send command to IoT device');
        return;
      }

      // Listen for response with timeout
      bool responseReceived = false;
      String? receivedResponse; // Create new subscription
      _bluetoothSubscription =
          BluetoothService.listenForMessages().listen((response) {
        receivedResponse = response.trim().toUpperCase();

        // Track gate command in parking session
        ParkingSessionService.trackGateCommand(
            widget.bookingId, receivedResponse!);

        // Listen for both "Gate Opened" and "Gate Closed" responses
        if (receivedResponse == 'GATE OPENED' && !responseReceived) {
          responseReceived = true;
          navigator.pop(); // Close processing dialog
          _navigateToHomeWithSuccess();
        } else if (receivedResponse == 'GATE CLOSED' && !responseReceived) {
          responseReceived = true;
          navigator.pop(); // Close processing dialog
          _navigateToHomeWithClosedMessage();
        }
      });

      // Set timeout for response
      Future.delayed(const Duration(seconds: 15), () {
        if (!responseReceived && mounted) {
          navigator.pop(); // Close processing dialog

          if (receivedResponse != null) {
            // We got some response but not the expected one
            _resumeScanner(); // Resume scanner
            _showErrorDialog(
                'Unexpected response: $receivedResponse. Please try again.');
          } else {
            // No response received, but command was sent
            _resumeScanner(); // Resume scanner
            _showPartialSuccessDialog();
          }
        }
      });
    } catch (e) {
      if (mounted) {
        navigator.popUntil((route) => route is! DialogRoute);
        _resumeScanner(); // Resume scanner on error
        _showErrorDialog('Error sending command: $e');
      }
    }
  }

  // Resume scanner after error or timeout
  void _resumeScanner() {
    if (mounted) {
      setState(() => _scannerPaused = false);
      // Cancel any active Bluetooth subscription when resuming scanner
      _bluetoothSubscription?.cancel();
      _bluetoothSubscription = null;
    }
  } // Navigate to home page with success snackbar

  void _navigateToHomeWithSuccess() {
    if (!mounted) return;

    // Store navigator and context references before async operations
    final navigator = Navigator.of(context);
    final currentContext = context;

    // Clean up subscription before navigation
    _bluetoothSubscription?.cancel();
    _bluetoothSubscription = null;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );

    // Show success snackbar on home page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SnackBarUtils.showSuccess(currentContext,
            'Gate Opened Successfully! QR code verified for: ${widget.address}');
      }
    });
  }

  // Navigate to home page with gate closed snackbar
  void _navigateToHomeWithClosedMessage() {
    if (!mounted) return;

    // Store navigator and context references before async operations
    final navigator = Navigator.of(context);
    final currentContext = context;

    // Clean up subscription before navigation
    _bluetoothSubscription?.cancel();
    _bluetoothSubscription = null;

    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false,
    );

    // Show gate closed snackbar on home page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SnackBarUtils.showInfo(
            currentContext, 'Gate Closed: ${widget.address} is now secured');
      }
    });
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
              _resumeScanner(); // Resume scanner when user dismisses error
            },
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Future<void> _showBluetoothSetupDialog(
      BluetoothPermissionResult result) async {
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
                await BluetoothService.openBluetoothSettings(
                    result.settingsType!);
              }
              if (mounted) {
                Navigator.of(context).pop(); // Return to previous screen
              }
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
        icon:
            const Icon(Icons.bluetooth_searching, color: Colors.blue, size: 48),
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
                Icon(Icons.lightbulb_outline,
                    color: Colors.amber.shade700, size: 20),
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
              await BluetoothService.openBluetoothSettings(
                  BluetoothSettingsType.bluetoothPairing);
              if (mounted) {
                Navigator.of(context).pop(); // Return to previous screen
              }
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
                  Icon(Icons.bluetooth_connected,
                      color: Colors.orange.shade700),
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
              _resumeScanner(); // Resume scanner
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue Scanning'),
          ),
        ],
      ),
    );
  }
}
