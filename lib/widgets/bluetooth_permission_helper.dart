import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

/// Widget for displaying Bluetooth permission dialogs and handling settings navigation
class BluetoothPermissionHelper {
  /// Show a dialog for requesting Bluetooth permissions with option to open settings
  static Future<bool> showPermissionDialog({
    required BuildContext context,
    required BluetoothPermissionResult permissionResult,
  }) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    _getIconForSettingsType(permissionResult.settingsType),
                    color: permissionResult.hasPermissions
                        ? Colors.green
                        : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      permissionResult.hasPermissions
                          ? 'Setup Required'
                          : 'Bluetooth Permission Required',
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    permissionResult.message,
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (permissionResult.shouldOpenSettings) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getInstructionText(
                                  permissionResult.settingsType),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!permissionResult.shouldOpenSettings)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                if (permissionResult.shouldOpenSettings) ...[
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Later'),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.settings),
                    label: Text(_getButtonText(permissionResult.settingsType)),
                    onPressed: () async {
                      Navigator.of(context).pop(true);
                      if (permissionResult.settingsType != null) {
                        await BluetoothService.openBluetoothSettings(
                            permissionResult.settingsType!);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Continue'),
                  ),
                ],
              ],
            );
          },
        ) ??
        false;
  }

  /// Show a simple permission request dialog
  static Future<bool> showSimplePermissionDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.bluetooth, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Bluetooth Access Required'),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This app needs Bluetooth access to communicate with IoT devices like gate controllers.',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Please grant Bluetooth permissions when prompted.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Grant Permissions'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Request permissions with user-friendly dialogs
  static Future<bool> requestPermissionsWithDialog(BuildContext context) async {
    // First, show a simple explanation dialog
    bool userAccepted = await showSimplePermissionDialog(context);
    if (!userAccepted) return false;

    // Request permissions with enhanced setup
    BluetoothPermissionResult result =
        await BluetoothService.requestPermissionsWithSetup();

    if (result.hasPermissions && !result.shouldOpenSettings) {
      // All good, permissions granted and devices available
      return true;
    }

    if (result.shouldOpenSettings) {
      // Show dialog with option to open settings
      bool openSettings = await showPermissionDialog(
        context: context,
        permissionResult: result,
      );
      if (openSettings && result.settingsType != null) {
        // User chose to open settings, show guidance dialog
        if (context.mounted) {
          _showPostSettingsDialog(context, result.settingsType!);
        }
      }

      return false; // User needs to complete setup in settings
    }

    // Permissions denied
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => requestPermissionsWithDialog(context),
          ),
        ),
      );
    }

    return false;
  }

  /// Show guidance dialog after opening settings
  static void _showPostSettingsDialog(
      BuildContext context, BluetoothSettingsType? settingsType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Text('Next Steps'),
            ],
          ),
          content: Text(_getPostSettingsInstructions(settingsType)),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  static IconData _getIconForSettingsType(BluetoothSettingsType? settingsType) {
    switch (settingsType) {
      case BluetoothSettingsType.bluetooth:
        return Icons.bluetooth_disabled;
      case BluetoothSettingsType.bluetoothPairing:
        return Icons.bluetooth_searching;
      case BluetoothSettingsType.appSettings:
        return Icons.security;
      default:
        return Icons.bluetooth;
    }
  }

  static String _getInstructionText(BluetoothSettingsType? settingsType) {
    switch (settingsType) {
      case BluetoothSettingsType.bluetooth:
        return 'Turn on Bluetooth to connect to IoT devices.';
      case BluetoothSettingsType.bluetoothPairing:
        return 'Pair with your IoT device (like HC-05) in Bluetooth settings.';
      case BluetoothSettingsType.appSettings:
        return 'Enable Bluetooth permissions for this app.';
      default:
        return 'Bluetooth setup required.';
    }
  }

  static String _getButtonText(BluetoothSettingsType? settingsType) {
    switch (settingsType) {
      case BluetoothSettingsType.bluetooth:
        return 'Open Bluetooth';
      case BluetoothSettingsType.bluetoothPairing:
        return 'Pair Device';
      case BluetoothSettingsType.appSettings:
        return 'App Settings';
      default:
        return 'Open Settings';
    }
  }

  static String _getPostSettingsInstructions(
      BluetoothSettingsType? settingsType) {
    switch (settingsType) {
      case BluetoothSettingsType.bluetooth:
        return 'Please turn on Bluetooth in the settings, then return to the app and try again.';
      case BluetoothSettingsType.bluetoothPairing:
        return 'Please pair with your IoT device (look for "HC-05" or similar) in Bluetooth settings, then return to the app.';
      case BluetoothSettingsType.appSettings:
        return 'Please enable all Bluetooth permissions for this app, then return and try again.';
      default:
        return 'Please complete the Bluetooth setup, then return to the app.';
    }
  }
}
