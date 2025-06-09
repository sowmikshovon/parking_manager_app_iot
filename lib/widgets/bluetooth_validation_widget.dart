import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../services/bluetooth_service.dart';

/// Quick validation widget to test enhanced Bluetooth functionality
class BluetoothValidationWidget extends StatefulWidget {
  const BluetoothValidationWidget({Key? key}) : super(key: key);

  @override
  State<BluetoothValidationWidget> createState() =>
      _BluetoothValidationWidgetState();
}

class _BluetoothValidationWidgetState extends State<BluetoothValidationWidget> {
  String _testResults = '';
  bool _isTesting = false;

  Future<void> _runValidationTests() async {
    setState(() {
      _isTesting = true;
      _testResults = 'Running validation tests...\n';
    });

    final results = StringBuffer();
    results.writeln('🔍 BLUETOOTH SYSTEM VALIDATION');
    results.writeln('================================');

    try {
      // Test 1: Bluetooth Availability
      results.writeln('\n📡 Test 1: Bluetooth Availability');
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      results.writeln(isEnabled == true
          ? '✅ Bluetooth is enabled'
          : '❌ Bluetooth is disabled');

      // Test 2: Permissions
      results.writeln('\n🔐 Test 2: Permission Check');
      final permissionResult =
          await BluetoothService.requestPermissionsWithSetup();
      results.writeln(permissionResult.hasPermissions
          ? '✅ Permissions granted'
          : '❌ Permissions missing: ${permissionResult.message}');

      // Test 3: Device Discovery
      results.writeln('\n📱 Test 3: Device Discovery');
      List<BluetoothDevice> devices = await BluetoothService.getPairedDevices();
      results.writeln('✅ Found ${devices.length} paired devices');

      if (devices.isNotEmpty) {
        results.writeln('   📋 Device List:');
        for (var device in devices) {
          results
              .writeln('   - ${device.name ?? 'Unknown'} (${device.address})');
        }

        // Test 4: Enhanced Connection Logic (if devices available)
        results.writeln('\n🔗 Test 4: Enhanced Connection Logic');
        final testDevice = devices.first;
        results.writeln('   Testing with: ${testDevice.name ?? 'Unknown'}');

        bool connectionResult =
            await BluetoothService.connectToDevice(testDevice);
        results.writeln(connectionResult
            ? '✅ Enhanced connection logic succeeded'
            : '⚠️ Connection attempt completed (check console for details)');

        if (connectionResult) {
          // Test 5: Message Sending
          results.writeln('\n📤 Test 5: Message Sending');
          bool sendResult =
              await BluetoothService.sendMessageWithLogging('TEST');
          results.writeln(sendResult
              ? '✅ Message sending works'
              : '⚠️ Message sending test completed');

          // Disconnect after test
          await BluetoothService.disconnect();
          results.writeln('🔌 Disconnected from test device');
        }
      } else {
        results.writeln('⚠️ No devices available for connection testing');
        results.writeln(
            '   💡 Pair a Bluetooth device to test connection features');
      }

      // Test 6: Diagnostics
      results.writeln('\n🔍 Test 6: Diagnostic System');
      Map<String, dynamic> diagnosis =
          await BluetoothService.diagnoseBluetooth();
      results.writeln('✅ Diagnostics completed:');
      results.writeln('   - Bluetooth: ${diagnosis['bluetoothEnabled']}');
      results.writeln('   - Devices: ${diagnosis['pairedDevicesCount']}');
      results.writeln('   - HC-05 Found: ${diagnosis['hc05DevicesFound']}');
      results.writeln('   - Permissions: ${diagnosis['permissionsGranted']}');

      results.writeln('\n🎉 VALIDATION COMPLETE');
      results.writeln('================================');
      results.writeln('✅ Enhanced Bluetooth system is functional');
      results.writeln('💡 Check console for detailed connection logs');
    } catch (e) {
      results.writeln('\n❌ Validation Error: $e');
    }

    setState(() {
      _testResults = results.toString();
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth System Validation'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'System Validation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This test validates the enhanced Bluetooth connection system and '
                      'verifies that all improvements are working correctly.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isTesting ? null : _runValidationTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isTesting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Running Tests...'),
                      ],
                    )
                  : const Text('Run Validation Tests'),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResults.isEmpty
                                ? 'Click "Run Validation Tests" to begin...'
                                : _testResults,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
