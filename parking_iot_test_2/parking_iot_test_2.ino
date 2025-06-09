#include <SoftwareSerial.h>
#include <Servo.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>

// --- Configuration ---
// Bluetooth HC-05
SoftwareSerial bluetooth(2,3); // RX, TX for SoftwareSerial

// Servo G90
Servo gateServo;
const int servoPin = 9;
const int gateOpenAngle = 90;   // Angle for "open" position (adjust as needed)
const int gateClosedAngle = 0;  // Angle for "closed" position (adjust as needed)

// LCD 16x2 I2C
LiquidCrystal_I2C lcd(0x27, 16, 2); // Address, columns, rows

String receivedString = ""; // To store incoming data from Bluetooth

// --- Auto-close functionality ---
String lastCommand = "";           // Store the last received command
unsigned long gateOpenTime = 0;   // Time when gate was opened
const unsigned long autoCloseDelay = 120000; // 2 minutes in milliseconds
bool gateIsOpen = false;          // Track gate state
bool autoCloseScheduled = false;  // Track if auto-close is scheduled

void setup() {
  Serial.begin(9600);        // For debugging via Serial Monitor
  bluetooth.begin(9600);     // HC-05 default baud rate is often 9600
  
  gateServo.attach(servoPin);
  gateServo.write(gateClosedAngle); // Start with the gate closed

  lcd.init();      // Initialize the LCD
  lcd.backlight(); // Turn on the backlight
  lcd.setCursor(0, 0);
  lcd.print("System Ready");
  lcd.setCursor(0, 1);
  lcd.print("Gate: Closed");

  Serial.println("Arduino is ready. Send commands via Bluetooth.");
  bluetooth.println("Bluetooth Connected! System Ready.");
}

void loop() {
  // Check for incoming data from Bluetooth
  if (bluetooth.available()) {
    char receivedChar = bluetooth.read();
    receivedString += receivedChar;

    // If a newline character is received, the command is complete
    if (receivedChar == '\n') {
      Serial.print("Received via Bluetooth: ");
      Serial.println(receivedString);

      // Trim whitespace (like \r or \n from some serial apps)
      receivedString.trim();

      if (receivedString.equalsIgnoreCase("open_gate")) {
        // Check if gate is already open and this is the same command again
        if (gateIsOpen && lastCommand.equalsIgnoreCase("open_gate")) {
          // Same command received while gate is open - close immediately
          Serial.println("Same command received - closing gate manually");
          closeGate();
          autoCloseScheduled = false; // Cancel auto-close
        } else if (!gateIsOpen) {
          // Gate is closed, open it
          openGate();
          lastCommand = receivedString;
          gateOpenTime = millis();
          autoCloseScheduled = true;
        }
      } else if (receivedString.equalsIgnoreCase("gate_close")) {
        if (gateIsOpen) {
          closeGate();
          autoCloseScheduled = false; // Cancel auto-close
        }
      } else {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Unknown Command:");
        lcd.setCursor(0, 1);
        lcd.print(receivedString);
        bluetooth.println("Unknown command: " + receivedString);
      }
      
      receivedString = ""; // Clear the string for the next command
    }
  }

  // Check for auto-close timeout (2 minutes after opening)
  if (autoCloseScheduled && gateIsOpen && (millis() - gateOpenTime >= autoCloseDelay)) {
    Serial.println("Auto-closing gate after 2 minutes");
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print("Auto-Close");
    lcd.setCursor(0, 1);
    lcd.print("Timeout: 2min");
    delay(1000); // Show message for 1 second
    closeGate();
    autoCloseScheduled = false;
  }

  // Update LCD with countdown if gate is open
  if (gateIsOpen && autoCloseScheduled) {
    updateCountdownDisplay();
  }
}

void openGate() {
  Serial.println("Opening Gate...");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Command: Open");
  gateServo.write(gateOpenAngle);
  lcd.setCursor(0, 1);
  lcd.print("Gate: Opening...");
  delay(1200); // Give servo time to move
  
  gateIsOpen = true;
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Gate: Open");
  lcd.setCursor(0, 1);
  lcd.print("Auto-close: 2min");
  
  bluetooth.println("Gate Opened");
  Serial.println("Gate opened - auto-close scheduled in 2 minutes");
}

void closeGate() {
  Serial.println("Closing Gate...");
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Command: Close");
  gateServo.write(gateClosedAngle);
  lcd.setCursor(0, 1);
  lcd.print("Gate: Closing...");
  delay(1200); // Give servo time to move
  
  gateIsOpen = false;
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Gate: Closed");
  lcd.setCursor(0, 1);
  lcd.print("System Ready");
  
  bluetooth.println("Gate Closed");
  lastCommand = ""; // Clear last command when gate closes
}

void updateCountdownDisplay() {
  static unsigned long lastUpdate = 0;
  unsigned long currentTime = millis();
  
  // Update display every second
  if (currentTime - lastUpdate >= 1000) {
    unsigned long timeElapsed = currentTime - gateOpenTime;
    unsigned long timeRemaining = autoCloseDelay - timeElapsed;
    
    if (timeRemaining > 0) {
      int minutesLeft = timeRemaining / 60000;
      int secondsLeft = (timeRemaining % 60000) / 1000;
      
      lcd.setCursor(0, 1);
      lcd.print("Close in: ");
      if (minutesLeft > 0) {
        lcd.print(minutesLeft);
        lcd.print("m ");
      }
      lcd.print(secondsLeft);
      lcd.print("s   "); // Extra spaces to clear previous text
    }
    
    lastUpdate = currentTime;
  }
}