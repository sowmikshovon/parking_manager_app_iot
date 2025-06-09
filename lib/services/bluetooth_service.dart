import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import '../utils/error_handler.dart';

/// Enum for different types of Bluetooth settings
enum BluetoothSettingsType {
  bluetooth, // Open general Bluetooth settings
  bluetoothPairing, // Open Bluetooth pairing/devices page
  appSettings, // Open app-specific permissions
}

/// Result class for Bluetooth permission requests
class BluetoothPermissionResult {
  final bool hasPermissions;
  final bool shouldOpenSettings;
  final String message;
  final BluetoothSettingsType? settingsType;

  BluetoothPermissionResult({
    required this.hasPermissions,
    required this.shouldOpenSettings,
    required this.message,
    this.settingsType,
  });
}

/// Service for managing Bluetooth communication with IoT devices
class BluetoothService {
  static BluetoothConnection? _connection;
  static bool _isConnected = false;
  static String? _connectedDeviceAddress;
  static StreamController<String>? _messageController;
  static StreamSubscription<Uint8List>? _inputSubscription;

  /// Request necessary Bluetooth permissions with user-friendly prompts
  static Future<bool> requestPermissions() async {
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      return statuses.values
          .every((status) => status == PermissionStatus.granted);
    } catch (e) {
      ErrorHandler.logError('BluetoothService.requestPermissions', e);
      return false;
    }
  }

  /// Enhanced permission request with settings redirect for first-time setup
  static Future<BluetoothPermissionResult> requestPermissionsWithSetup() async {
    try {
      // Check if Bluetooth is enabled on the device with error handling
      bool? isBluetoothEnabled;
      try {
        isBluetoothEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      } catch (e) {
        ErrorHandler.logError(
            'BluetoothService.requestPermissionsWithSetup - isEnabled check',
            e);
        return BluetoothPermissionResult(
          hasPermissions: false,
          shouldOpenSettings: true,
          message:
              'Bluetooth not available on this device or plugin not properly configured. Error: $e',
          settingsType: BluetoothSettingsType.bluetooth,
        );
      }

      if (isBluetoothEnabled != true) {
        return BluetoothPermissionResult(
          hasPermissions: false,
          shouldOpenSettings: true,
          message:
              'Bluetooth is disabled. Please enable Bluetooth to connect to IoT devices.',
          settingsType: BluetoothSettingsType.bluetooth,
        );
      }

      // Request permissions
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      // Check if all permissions are granted
      bool allGranted =
          statuses.values.every((status) => status == PermissionStatus.granted);

      if (allGranted) {
        // Check if any devices are already paired
        List<BluetoothDevice> pairedDevices = await getPairedDevices();

        if (pairedDevices.isEmpty) {
          return BluetoothPermissionResult(
            hasPermissions: true,
            shouldOpenSettings: true,
            message:
                'No Bluetooth devices paired. Please pair with your IoT device first.',
            settingsType: BluetoothSettingsType.bluetoothPairing,
          );
        }

        return BluetoothPermissionResult(
          hasPermissions: true,
          shouldOpenSettings: false,
          message: 'Bluetooth permissions granted and devices available.',
        );
      }

      // Check for permanently denied permissions
      bool hasPermanentlyDenied = statuses.values
          .any((status) => status == PermissionStatus.permanentlyDenied);

      if (hasPermanentlyDenied) {
        return BluetoothPermissionResult(
          hasPermissions: false,
          shouldOpenSettings: true,
          message:
              'Bluetooth permissions are required. Please enable them in app settings.',
          settingsType: BluetoothSettingsType.appSettings,
        );
      }

      return BluetoothPermissionResult(
        hasPermissions: false,
        shouldOpenSettings: false,
        message: 'Bluetooth permissions denied. Please try again.',
      );
    } catch (e) {
      ErrorHandler.logError('BluetoothService.requestPermissionsWithSetup', e);
      return BluetoothPermissionResult(
        hasPermissions: false,
        shouldOpenSettings: false,
        message: 'Error checking Bluetooth permissions: $e',
      );
    }
  }

  /// Open appropriate settings based on the scenario
  static Future<void> openBluetoothSettings(
      BluetoothSettingsType settingsType) async {
    try {
      switch (settingsType) {
        case BluetoothSettingsType.bluetooth:
          await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
          break;
        case BluetoothSettingsType.bluetoothPairing:
          await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
          break;
        case BluetoothSettingsType.appSettings:
          await AppSettings.openAppSettings();
          break;
      }
    } catch (e) {
      ErrorHandler.logError('BluetoothService.openBluetoothSettings', e);
    }
  }

  /// Get list of paired Bluetooth devices
  static Future<List<BluetoothDevice>> getPairedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      ErrorHandler.logError('BluetoothService.getPairedDevices', e);
      return [];
    }
  }

  /// Connect to a specific Bluetooth device with enhanced error handling
  static Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      print(
          '🔵 Bluetooth: Attempting to connect to ${device.name} (${device.address})');

      // Disconnect from any existing connection
      if (_isConnected) {
        print('🔵 Bluetooth: Disconnecting from previous device');
        await disconnect();
        await Future.delayed(
            Duration(milliseconds: 500)); // Give time for cleanup
      }

      // Validate device is still paired
      List<BluetoothDevice> pairedDevices = await getPairedDevices();
      bool isDevicePaired =
          pairedDevices.any((d) => d.address == device.address);

      if (!isDevicePaired) {
        print('🔴 Bluetooth: Device ${device.name} is not paired');
        return false;
      }

      // Check if Bluetooth is enabled
      bool? isBluetoothEnabled =
          await FlutterBluetoothSerial.instance.isEnabled;
      if (isBluetoothEnabled != true) {
        print('🔴 Bluetooth: Bluetooth is not enabled');
        return false;
      }

      print('🔵 Bluetooth: Creating connection to ${device.address}');

      // Create connection with timeout and retry logic
      BluetoothConnection? connection;
      int maxRetries = 3;
      int retryCount = 0;

      while (retryCount < maxRetries && connection == null) {
        try {
          print(
              '🔵 Bluetooth: Connection attempt ${retryCount + 1}/$maxRetries');

          // Add timeout to prevent hanging
          connection = await BluetoothConnection.toAddress(device.address)
              .timeout(Duration(seconds: 10));

          print('🔵 Bluetooth: Connection established successfully');
          break;
        } catch (e) {
          retryCount++;
          print('🔴 Bluetooth: Connection attempt $retryCount failed: $e');

          if (retryCount < maxRetries) {
            print('🔵 Bluetooth: Waiting before retry...');
            await Future.delayed(Duration(seconds: 2));
          }
        }
      }

      if (connection == null) {
        print('🔴 Bluetooth: Failed to connect after $maxRetries attempts');
        return false;
      }
      _connection = connection;
      _isConnected = true;
      _connectedDeviceAddress = device.address;

      // Initialize broadcast stream for messages
      _initializeMessageStream();

      print(
          '🟢 Bluetooth: Successfully connected to ${device.name} (${device.address})');

      // Test the connection by trying to send a ping
      bool pingSuccess = await _testConnection();
      if (!pingSuccess) {
        print('🔴 Bluetooth: Connection test failed, disconnecting');
        await disconnect();
        return false;
      }

      return true;
    } catch (e) {
      print('🔴 Bluetooth: Connection error: $e');
      ErrorHandler.logError('BluetoothService.connectToDevice', e);
      _isConnected = false;
      _connectedDeviceAddress = null;
      return false;
    }
  }

  /// Connect to device with terminal-friendly approach (for testing with serial apps)
  static Future<bool> connectToDeviceForTerminal(BluetoothDevice device) async {
    try {
      print(
          '🔵 Bluetooth: Attempting TERMINAL connection to ${device.name} (${device.address})');

      // Disconnect from any existing connection
      if (_isConnected) {
        print('🔵 Bluetooth: Disconnecting from previous device');
        await disconnect();
        await Future.delayed(
            Duration(milliseconds: 1000)); // Longer delay for terminal apps
      }

      // Validate device is still paired
      List<BluetoothDevice> pairedDevices = await getPairedDevices();
      bool isDevicePaired =
          pairedDevices.any((d) => d.address == device.address);

      if (!isDevicePaired) {
        print('🔴 Bluetooth: Device ${device.name} is not paired');
        return false;
      }

      // Check if Bluetooth is enabled
      bool? isBluetoothEnabled =
          await FlutterBluetoothSerial.instance.isEnabled;
      if (isBluetoothEnabled != true) {
        print('🔴 Bluetooth: Bluetooth is not enabled');
        return false;
      }

      print('🔵 Bluetooth: Creating TERMINAL connection to ${device.address}');

      // Create connection with single attempt and longer timeout for terminal apps
      BluetoothConnection? connection;

      try {
        print('🔵 Bluetooth: Attempting connection with 15-second timeout...');

        // Longer timeout for terminal apps which might take time to accept connection
        connection = await BluetoothConnection.toAddress(device.address)
            .timeout(Duration(seconds: 15));

        print('🔵 Bluetooth: Connection established successfully');
      } catch (e) {
        print('🔴 Bluetooth: Connection failed: $e');
        return false;
      }
      _connection = connection;
      _isConnected = true;
      _connectedDeviceAddress = device.address;

      // Initialize broadcast stream for messages
      _initializeMessageStream();

      print(
          '🟢 Bluetooth: Successfully connected to ${device.name} (${device.address})');

      // For terminal testing, skip the AT command test and just verify the connection is stable
      await Future.delayed(Duration(milliseconds: 1000));

      if (_connection != null && _isConnected) {
        print(
            '🟢 Bluetooth: Connection verified stable for terminal communication');
        return true;
      } else {
        print('🔴 Bluetooth: Connection became unstable');
        await disconnect();
        return false;
      }
    } catch (e) {
      print('🔴 Bluetooth: Terminal connection error: $e');
      ErrorHandler.logError('BluetoothService.connectToDeviceForTerminal', e);
      _isConnected = false;
      _connectedDeviceAddress = null;
      return false;
    }
  }

  /// Test connection by sending a simple ping
  static Future<bool> _testConnection() async {
    if (!_isConnected || _connection == null) {
      return false;
    }

    try {
      print('🔵 Bluetooth: Testing connection...');

      // For serial terminal apps, we'll just test if we can write to the stream
      // without expecting a specific response
      final testMessage = "Hello from Flutter\n";
      final messageBytes = Uint8List.fromList(utf8.encode(testMessage));
      _connection!.output.add(messageBytes);
      await _connection!.output.allSent;

      // Add a small delay to see if the connection stays stable
      await Future.delayed(Duration(milliseconds: 500));

      print('🔵 Bluetooth: Test message sent successfully');
      return true;
    } catch (e) {
      print('🔴 Bluetooth: Connection test failed: $e');
      return false;
    }
  }

  /// Send a message to the connected device
  static Future<bool> sendMessage(String message) async {
    if (!_isConnected || _connection == null) {
      ErrorHandler.logError(
        'BluetoothService.sendMessage',
        'No active connection',
      );
      return false;
    }

    try {
      final messageBytes = Uint8List.fromList(utf8.encode(message));
      _connection!.output.add(messageBytes);
      await _connection!.output.allSent;

      ErrorHandler.logError(
        'BluetoothService.sendMessage',
        'Message sent: "$message"',
      );

      return true;
    } catch (e) {
      ErrorHandler.logError('BluetoothService.sendMessage', e);
      return false;
    }
  }

  /// Enhanced send message with logging for testing
  static Future<bool> sendMessageWithLogging(String message) async {
    if (!_isConnected || _connection == null) {
      print('🔵 Bluetooth: Not connected to device');
      return false;
    }

    try {
      print('🔵 Bluetooth: Sending message: "$message"');
      final messageBytes = Uint8List.fromList(utf8.encode(message));
      _connection!.output.add(messageBytes);
      await _connection!.output.allSent;
      print('🔵 Bluetooth: Message sent successfully');
      return true;
    } catch (e) {
      print('🔴 Bluetooth: Error sending message: $e');
      return false;
    }
  }

  /// Send a terminal-friendly message (with proper line endings for serial apps)
  static Future<bool> sendTerminalMessage(String message) async {
    if (!_isConnected || _connection == null) {
      print('🔴 Bluetooth: Not connected to device');
      return false;
    }

    try {
      // Add proper line ending for terminal apps
      String terminalMessage =
          message.endsWith('\n') ? message : message + '\n';
      print('🔵 Bluetooth: Sending terminal message: "$terminalMessage"');

      final messageBytes = Uint8List.fromList(utf8.encode(terminalMessage));
      _connection!.output.add(messageBytes);
      await _connection!.output.allSent;

      print('🟢 Bluetooth: Terminal message sent successfully');
      return true;
    } catch (e) {
      print('🔴 Bluetooth: Error sending terminal message: $e');
      return false;
    }
  }

  /// Send multiple test messages to verify terminal communication
  static Future<void> sendTestSequence() async {
    if (!_isConnected || _connection == null) {
      print('🔴 Bluetooth: Not connected - cannot send test sequence');
      return;
    }

    List<String> testMessages = [
      "Hello from Flutter App!",
      "Testing Bluetooth connection...",
      "Message 1: Basic text",
      "Message 2: With numbers 12345",
      "Message 3: Special chars !@#\$%",
      "Test sequence complete."
    ];

    print('🔵 Bluetooth: Starting test message sequence...');

    for (int i = 0; i < testMessages.length; i++) {
      await sendTerminalMessage("[$i] ${testMessages[i]}");
      await Future.delayed(
          Duration(milliseconds: 500)); // Delay between messages
    }

    print('🟢 Bluetooth: Test sequence completed');
  }

  /// Initialize message stream for broadcast listening
  static void _initializeMessageStream() {
    // Clean up any existing stream
    _inputSubscription?.cancel();
    _messageController?.close();

    // Create new broadcast stream controller
    _messageController = StreamController<String>.broadcast();

    // Listen to the single-subscription input stream and broadcast messages
    if (_connection?.input != null) {
      _inputSubscription = _connection!.input!.listen(
        (data) {
          final message = utf8.decode(data);
          print('🔵 Bluetooth: Received message: "$message"');
          _messageController?.add(message);
        },
        onError: (error) {
          print('🔴 Bluetooth: Input stream error: $error');
          _messageController?.addError(error);
        },
        onDone: () {
          print('🔵 Bluetooth: Input stream closed');
          _messageController?.close();
        },
      );
    }
  }

  /// Listen for incoming messages from the connected device
  static Stream<String> listenForMessages() {
    if (!_isConnected || _messageController == null) {
      return Stream.empty();
    }

    return _messageController!.stream;
  }

  /// Enhanced listener with logging for testing
  static Stream<String> listenForMessagesWithLogging() {
    if (!_isConnected || _messageController == null) {
      print('🔴 Bluetooth: Not connected - cannot listen for messages');
      return Stream.empty();
    }

    return _messageController!.stream;
  }

  /// Disconnect from the current device with enhanced cleanup
  static Future<void> disconnect() async {
    try {
      print(
          '🔵 Bluetooth: Disconnecting from device: $_connectedDeviceAddress');

      // Clean up message stream first
      _inputSubscription?.cancel();
      _messageController?.close();
      _inputSubscription = null;
      _messageController = null;

      if (_connection != null) {
        // Close output stream first
        try {
          await _connection!.output.close();
        } catch (e) {
          print('🔴 Bluetooth: Error closing output stream: $e');
        }

        // Dispose connection
        try {
          _connection!.dispose();
        } catch (e) {
          print('🔴 Bluetooth: Error disposing connection: $e');
        }

        print(
            '🟢 Bluetooth: Successfully disconnected from: $_connectedDeviceAddress');
      }
    } catch (e) {
      print('🔴 Bluetooth: Error during disconnect: $e');
      ErrorHandler.logError('BluetoothService.disconnect', e);
    } finally {
      _connection = null;
      _isConnected = false;
      _connectedDeviceAddress = null;
    }
  }

  /// Check if currently connected to a device
  static bool get isConnected => _isConnected;

  /// Get the address of the currently connected device
  static String? get connectedDeviceAddress => _connectedDeviceAddress;

  /// Send IoT command to open gate
  static Future<Result<String>> sendOpenGateCommand() async {
    try {
      if (!_isConnected) {
        return const Result.error('No Bluetooth device connected');
      }

      final sent = await sendMessage('open_gate\n');
      if (!sent) {
        return const Result.error('Failed to send command to IoT device');
      }

      return const Result.success('Command sent successfully');
    } catch (e) {
      return Result.error(ErrorHandler.getGenericErrorMessage(e));
    }
  }

  /// Test Bluetooth connection by getting paired devices
  static Future<void> testBluetoothConnection() async {
    try {
      final pairedDevices = await getPairedDevices();
      print('🔵 Bluetooth Test: Found ${pairedDevices.length} paired devices:');

      for (var device in pairedDevices) {
        print('🔵 Device: ${device.name ?? 'Unknown'} - ${device.address}');
      }
    } catch (e) {
      print('🔴 Bluetooth Test: Error getting paired devices: $e');
    }
  }

  /// Find HC-05 devices specifically
  static Future<List<BluetoothDevice>> findHC05Devices() async {
    try {
      final pairedDevices = await getPairedDevices();
      return pairedDevices.where((device) {
        final name = device.name?.toLowerCase() ?? '';
        return name.contains('hc-05') || name.contains('hc05');
      }).toList();
    } catch (e) {
      ErrorHandler.logError('BluetoothService.findHC05Devices', e);
      return [];
    }
  }

  /// Comprehensive device connection diagnostics
  static Future<Map<String, dynamic>> diagnoseBluetooth() async {
    Map<String, dynamic> diagnosis = {
      'bluetoothEnabled': false,
      'pairedDevicesCount': 0,
      'hc05DevicesFound': 0,
      'permissionsGranted': false,
      'connectionStatus': 'Not connected',
      'errors': <String>[],
      'recommendations': <String>[],
    };

    try {
      // Check Bluetooth status
      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      diagnosis['bluetoothEnabled'] = isEnabled == true;

      if (!diagnosis['bluetoothEnabled']) {
        diagnosis['errors'].add('Bluetooth is disabled');
        diagnosis['recommendations'].add('Enable Bluetooth in device settings');
      }

      // Check paired devices
      List<BluetoothDevice> pairedDevices = await getPairedDevices();
      diagnosis['pairedDevicesCount'] = pairedDevices.length;

      if (pairedDevices.isEmpty) {
        diagnosis['errors'].add('No paired devices found');
        diagnosis['recommendations']
            .add('Pair with your IoT device (HC-05, ESP32, etc.)');
      }

      // Check for HC-05 devices
      List<BluetoothDevice> hc05Devices = await findHC05Devices();
      diagnosis['hc05DevicesFound'] = hc05Devices.length;

      // Check permissions
      Map<Permission, PermissionStatus> permissionStatuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();

      bool allPermissionsGranted = permissionStatuses.values
          .every((status) => status == PermissionStatus.granted);
      diagnosis['permissionsGranted'] = allPermissionsGranted;

      if (!allPermissionsGranted) {
        diagnosis['errors'].add('Some Bluetooth permissions not granted');
        diagnosis['recommendations']
            .add('Grant all Bluetooth permissions in app settings');
      }

      // Check current connection
      if (_isConnected && _connectedDeviceAddress != null) {
        diagnosis['connectionStatus'] = 'Connected to $_connectedDeviceAddress';
      } else {
        diagnosis['connectionStatus'] = 'Not connected';
        if (pairedDevices.isNotEmpty) {
          diagnosis['recommendations'].add('Try connecting to a paired device');
        }
      }

      // Add device-specific recommendations
      if (hc05Devices.isEmpty && pairedDevices.isNotEmpty) {
        diagnosis['recommendations'].add(
            'No HC-05 devices found. Ensure your IoT device is properly paired');
      }
    } catch (e) {
      diagnosis['errors'].add('Error during diagnosis: $e');
    }

    return diagnosis;
  }

  /// Print formatted diagnosis report
  static Future<void> printDiagnosisReport() async {
    print('\n🔵 ===== BLUETOOTH DIAGNOSIS REPORT =====');

    Map<String, dynamic> diagnosis = await diagnoseBluetooth();

    print('🔵 Bluetooth Enabled: ${diagnosis['bluetoothEnabled']}');
    print('🔵 Paired Devices: ${diagnosis['pairedDevicesCount']}');
    print('🔵 HC-05 Devices Found: ${diagnosis['hc05DevicesFound']}');
    print('🔵 Permissions Granted: ${diagnosis['permissionsGranted']}');
    print('🔵 Connection Status: ${diagnosis['connectionStatus']}');

    if (diagnosis['errors'].isNotEmpty) {
      print('\n🔴 ERRORS:');
      for (String error in diagnosis['errors']) {
        print('🔴 - $error');
      }
    }

    if (diagnosis['recommendations'].isNotEmpty) {
      print('\n💡 RECOMMENDATIONS:');
      for (String recommendation in diagnosis['recommendations']) {
        print('💡 - $recommendation');
      }
    }

    print('🔵 =====================================\n');
  }
}
