# IoT Parking App

A comprehensive Flutter application for parking spot management with IoT device integration via Bluetooth communication.

## 🚗 Features

### Core Functionality

- **User Authentication** - Firebase Auth with email/password
- **Spot Listing** - Property owners can list available parking spots
- **Spot Booking** - Users can find and book available parking spots
- **Real-time Updates** - Live status updates for spot availability
- **QR Code Integration** - Generate and scan QR codes for spot access
- **Location Services** - GPS-based spot discovery with Google Maps
- **Booking History** - Track past bookings and listings

### IoT Integration

- **Bluetooth Communication** - HC-05/ESP32 device integration
- **Gate Control** - Send commands to IoT devices (open_gate, status checks)
- **Real-time Response** - Listen for device responses and status updates
- **Enhanced QR Scanner** - Scan QR codes and automatically communicate with IoT devices

## 🛠️ Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Maps**: Google Maps Flutter Plugin
- **Bluetooth**: flutter_bluetooth_serial
- **QR Codes**: mobile_scanner
- **State Management**: Provider pattern
- **Permissions**: permission_handler

## 📱 Setup Instructions

### Prerequisites

- Flutter SDK (3.0+)
- Android Studio / VS Code
- Firebase project setup
- Google Maps API key
- Physical Android device (for Bluetooth testing)

### Installation

1. **Clone the repository**

```bash
git clone <repository-url>
cd parking_manager_app_iot
```

2. **Install dependencies**

```bash
flutter pub get
```

3. **Firebase Configuration**

- Add your `google-services.json` to `android/app/`
- Configure Firebase Auth and Firestore
- Update `lib/firebase_options.dart` with your config

4. **Google Maps Setup**

- Get Google Maps API key
- Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data android:name="com.google.android.geo.API_KEY"
           android:value="YOUR_API_KEY"/>
```

5. **Build and Run**

```bash
flutter run
```

## 🔧 IoT Device Setup

### Supported Devices

- HC-05 Bluetooth modules
- ESP32 with Bluetooth Serial
- Arduino with Bluetooth capability

### Arduino Code Example

Reference `arduino_code_example.ino` for complete IoT device setup including:

- Bluetooth serial communication
- Command processing ("open_gate" → "gate_opened")
- LED feedback and status reporting

### Device Pairing

1. Enable Bluetooth on your Android device
2. Power on IoT device (HC-05/ESP32)
3. Pair device (default PIN: 1234 or 0000)
4. Test connection using the built-in test button in the QR scanner

## 📖 Usage Guide

### For Property Owners

1. **List a Spot**: Select location on map → Enter details → Set availability time
2. **Manage Listings**: View your spots in "My Listings" with real-time status
3. **QR Code Generation**: Get QR code for your spot for easy sharing
4. **IoT Integration**: Connect IoT devices to automatically control access

### For Parking Users

1. **Find Spots**: Browse available spots on map or list view
2. **Book a Spot**: Select spot → Confirm booking → Get confirmation
3. **Access Spot**: Scan QR code to automatically open gates/barriers
4. **Booking History**: Track your past and current bookings

## 🔐 Permissions

The app requires the following permissions:

- **Location** - Find nearby parking spots
- **Camera** - QR code scanning
- **Bluetooth** - IoT device communication
- **Internet** - Firebase connectivity

## 🚀 Key Features Detail

### Smart QR Scanner with Bluetooth

- Scan QR codes to identify parking spots
- Automatically connect to paired IoT devices
- Send "open_gate" commands to control access
- Listen for device responses with timeout handling
- Visual feedback for successful/failed operations

### Enhanced Location Services

- "My Location" button for quick map navigation
- GPS-based spot distance calculation
- Location permission handling with user-friendly error messages

### Real-time Status Management

- Live updates for spot availability
- Expired spot detection and re-activation
- Booking conflict prevention
- Visual status indicators (Available/Booked/Expired)

## 🐛 Troubleshooting

### Common Issues

1. **Bluetooth Connection Failed**

   - Ensure device is paired in Android settings
   - Check if device is in connectable mode
   - Try the built-in connection test in the app

2. **Location Not Working**

   - Enable location services in device settings
   - Grant location permissions to the app
   - Test outdoors for better GPS signal

3. **QR Scanner Issues**
   - Ensure camera permission is granted
   - Clean camera lens
   - Ensure good lighting conditions

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase configuration
├── models/                   # Data models
├── pages/                    # UI screens
│   ├── home_page.dart
│   ├── login_page.dart
│   ├── book_spot_page.dart
│   ├── list_spot_page.dart
│   ├── qr_scanner_with_bluetooth_page.dart
│   └── ...
├── services/                 # Business logic
│   ├── bluetooth_service.dart
│   ├── booking_service.dart
│   ├── location_service.dart
│   └── ...
├── utils/                    # Utility functions
└── widgets/                  # Reusable UI components
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly (especially IoT functionality)
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

For technical support or questions about IoT integration, please create an issue on the repository.
