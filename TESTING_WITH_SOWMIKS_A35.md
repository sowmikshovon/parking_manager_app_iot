# Testing Bluetooth IoT with Sowmik's A35

## 🎯 Testing Setup Overview

You mentioned testing with "Sowmik's A35" - this appears to be your Android phone name. For the Bluetooth IoT functionality to work properly, you'll need:

1. **Your Android phone** (Sowmik's A35) - Running the Flutter app
2. **An IoT device** - HC-05, ESP32, Arduino with Bluetooth, etc.

## 📱 Step 1: Prepare Your Android Device (Sowmik's A35)

### Install and Run the App

```bash
# Build and install the app on your device
flutter run --release
```

### Check Device Bluetooth Settings

1. Go to **Settings > Bluetooth** on Sowmik's A35
2. Ensure Bluetooth is enabled
3. Note any already paired devices

## 🔧 Step 2: Prepare an IoT Device for Testing

### Option A: HC-05 Bluetooth Module (Recommended for Testing)

If you have an HC-05 module:

```
Connections:
- VCC to 3.3V or 5V
- GND to Ground
- TX to Digital Pin (for receiving)
- RX to Digital Pin (for sending)

Default Settings:
- Name: "HC-05" or similar
- PIN: 1234 or 0000
- Baud Rate: 9600
```

### Option B: ESP32 with Bluetooth

Use this Arduino code for ESP32:

```cpp
#include "BluetoothSerial.h"

BluetoothSerial SerialBT;
String device_name = "ESP32_Parking_IoT";

void setup() {
  Serial.begin(115200);
  SerialBT.begin(device_name); // Bluetooth device name
  Serial.println("The device started, now you can pair it with bluetooth!");
  Serial.println("Device name: " + device_name);
}

void loop() {
  // Handle incoming Bluetooth messages
  if (SerialBT.available()) {
    String message = SerialBT.readString();
    message.trim();

    Serial.println("Received: " + message);

    // Respond to test commands
    if (message == "AT") {
      SerialBT.println("OK");
      Serial.println("Sent: OK");
    }
    else if (message == "open_gate") {
      SerialBT.println("Gate opened successfully");
      Serial.println("Sent: Gate opened successfully");
    }
    else {
      SerialBT.println("Command received: " + message);
    }
  }

  delay(20);
}
```

### Option C: Computer Bluetooth (For Basic Testing)

If you don't have IoT hardware, you can test with another computer:

1. Enable Bluetooth on a Windows PC or Mac
2. Make it discoverable
3. Use a Bluetooth serial terminal app

## 🔗 Step 3: Pair the IoT Device with Sowmik's A35

1. **Power on your IoT device** (HC-05, ESP32, etc.)
2. **On Sowmik's A35:**
   - Go to Settings > Bluetooth
   - Tap "Scan" or "Search for devices"
   - Look for your device (e.g., "HC-05", "ESP32_Parking_IoT")
   - Tap to pair (use PIN 1234 or 0000 if prompted)
3. **Verify pairing** - device should appear under "Paired devices"

## 🧪 Step 4: Test with the Flutter App

### Run the App on Sowmik's A35

```bash
flutter run --release
```

### Use the Testing Interface

1. Open the app on Sowmik's A35
2. Navigate to the address entry page
3. You'll see these new testing buttons:

#### A. Test Bluetooth Permissions

- Tap **"Test Bluetooth Permissions"**
- Grant all requested permissions
- Check the status message

#### B. Run Bluetooth Diagnostics

- Tap **"Test Bluetooth Permissions"** then **"Run Bluetooth Diagnostics"**
- This will show:
  - Bluetooth enabled status
  - Number of paired devices
  - Permission status
  - Detailed recommendations

#### C. Connection Troubleshooting

- Tap **"Connection Troubleshooting"**
- Select your IoT device from the dropdown
- Tap **"Connect"**
- Watch for connection status updates

## 📊 Step 5: Monitor Debug Output

### Expected Success Messages:

```
🔵 ===== BLUETOOTH DIAGNOSIS REPORT =====
🔵 Bluetooth Enabled: true
🔵 Paired Devices: 1
🔵 HC-05 Devices Found: 1 (or ESP32 devices)
🔵 Permissions Granted: true
🔵 Connection Status: Connected to XX:XX:XX:XX:XX:XX
🔵 =====================================

🔵 Bluetooth: Attempting to connect to YourDevice (XX:XX:XX:XX:XX:XX)
🔵 Bluetooth: Connection attempt 1/3
🔵 Bluetooth: Connection established successfully
🔵 Bluetooth: Testing connection...
🔵 Bluetooth: Test message sent successfully
🟢 Bluetooth: Successfully connected to YourDevice
```

### If Connection Fails:

```
🔴 Bluetooth: Connection attempt 1 failed: [error details]
🔴 Bluetooth: Connection attempt 2 failed: [error details]
🔴 Bluetooth: Failed to connect after 3 attempts
```

## 🎯 Quick Test Scenario

### Minimal Hardware Setup (Recommended):

1. **Get an HC-05 module** ($5-10 on Amazon/eBay)
2. **Connect to Arduino Uno/Nano:**
   - HC-05 VCC → Arduino 5V
   - HC-05 GND → Arduino GND
   - HC-05 TX → Arduino Pin 2
   - HC-05 RX → Arduino Pin 3
3. **Upload simple echo code:**

```cpp
#include <SoftwareSerial.h>
SoftwareSerial bluetooth(2, 3); // RX, TX

void setup() {
  Serial.begin(9600);
  bluetooth.begin(9600);
  Serial.println("HC-05 Ready for pairing");
}

void loop() {
  if (bluetooth.available()) {
    String message = bluetooth.readString();
    message.trim();
    Serial.println("Received: " + message);
    bluetooth.println("Echo: " + message);
  }
}
```

## 🚨 Common Issues & Solutions

### Issue: "No paired devices found"

**Solution:**

- Ensure IoT device is powered and discoverable
- Re-pair the device in Android Bluetooth settings
- Check if device name appears in Settings > Bluetooth

### Issue: "Connection failed"

**Solution:**

- Move devices closer (within 2 meters)
- Restart both devices
- Use the diagnostics tool to check detailed status

### Issue: "Permission denied"

**Solution:**

- Use "Test Bluetooth Permissions" button
- Grant all permissions when prompted
- For Android 12+, ensure BLUETOOTH_CONNECT is granted

## 📱 Testing Commands

Once connected, try these test messages:

1. `AT` - Should respond with `OK`
2. `open_gate` - Custom parking gate command
3. `status` - Check device status
4. `ping` - Connection test

## 🎉 Success Criteria

You'll know it's working when:

- ✅ Diagnostics show all green checkmarks
- ✅ Device connects without errors
- ✅ Test messages send and receive responses
- ✅ Debug console shows successful connection logs

## 📞 Need Help?

If you encounter issues:

1. Run the Bluetooth Diagnostics
2. Copy the console output
3. Note your IoT device type
4. Share the specific error messages

Would you like me to help you set up any specific IoT device, or do you need help with the pairing process?
