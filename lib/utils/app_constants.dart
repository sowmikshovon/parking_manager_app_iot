/// App-wide constants for colors, strings, dimensions, and configuration
/// This centralizes all hardcoded values for better maintainability and consistency
library;

import 'package:flutter/material.dart';

/// Application color constants
class AppColors {
  // Primary colors
  static const Color primary = Colors.teal;
  static const Color primaryAccent = Colors.tealAccent;
  static final Color primaryShade200 = Colors.teal.shade200;
  static final Color primaryShade400 = Colors.teal.shade400;
  static final Color primaryShade600 = Colors.teal.shade600;
  static final Color primaryShade700 = Colors.teal.shade700;
  static final Color primaryShade800 = Colors.teal.shade800;
  static final Color primaryShade50 = Colors.teal.shade50;

  // Secondary colors
  static const Color orange = Colors.orange;
  static final Color orangeAccent = Colors.orangeAccent;
  static final Color orangeShade50 = Colors.orange.shade50;
  static final Color orangeShade100 = Colors.orange.shade100;
  static final Color orangeShade200 = Colors.orange.shade200;
  static final Color orangeShade300 = Colors.orange.shade300;
  static final Color orangeShade400 = Colors.orange.shade400;
  static final Color orangeShade600 = Colors.orange.shade600;
  static final Color orangeShade700 = Colors.orange.shade700;
  static final Color orangeShade800 = Colors.orange.shade800;

  // Status colors
  static final Color success = Colors.green.shade600;
  static final Color successLight = Colors.green.shade100;
  static const Color error = Colors.red;
  static final Color errorShade600 = Colors.red.shade600;
  static final Color errorLight = Colors.red.shade100;
  static final Color warning = Colors.orange.shade600;
  static final Color info = Colors.blue.shade600;

  // Neutral colors
  static const Color white = Colors.white;
  static final Color white70 = Colors.white70;
  static const Color black = Colors.black;
  static final Color black87 = Colors.black87;
  static final Color grey100 = Colors.grey.shade100;
  static final Color grey200 = Colors.grey.shade200;
  static final Color grey400 = Colors.grey.shade400;
  static final Color grey600 = Colors.grey.shade600;
  static final Color grey700 = Colors.grey.shade700;
  static final Color grey800 = Colors.grey.shade800;

  // Special colors
  static final Color purple400 = Colors.purple.shade400;
  static final Color blue400 = Colors.blue.shade400;
  static const Color yellow = Colors.yellow;
  static const Color transparent = Colors.transparent;

  // Gradient colors
  static final List<Color> primaryGradient = [
    primaryShade600,
    primaryShade400,
    primaryShade200,
  ];

  static final List<Color> orangeGradient = [
    orangeShade100,
    orangeShade50,
  ];
}

/// Application text strings
class AppStrings {
  // App info
  static const String appTitle = 'Parking Manager';
  
  // Authentication
  static const String login = 'Login';
  static const String signUp = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String firstName = 'First Name';
  static const String lastName = 'Last Name';
  static const String dateOfBirth = 'Date of Birth';
  static const String gender = 'Gender';
  
  // Navigation
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String bookingHistory = 'My Booking History';
  static const String listingHistory = 'My Listed Spots';
  static const String selectLocation = 'Select Location';
  static const String spotQrCode = 'Spot QR Code';
  
  // Actions
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String refresh = 'Refresh';
  static const String continueBooking = 'Continue Booking';
  static const String generateQrCode = 'Generate QR Code';
  static const String scanQrCode = 'Scan QR Code';
  
  // Messages
  static const String qrCodeVerified = 'QR Code Verified!';
  static const String parkingSpotVerified = 'Parking spot verified at:';
  static const String scanQrCodeToVerify = 'Scan this QR code to verify parking spot';
  static const String parkingSpotQrCode = 'Parking Spot QR Code';
  
  // Validation messages
  static const String requiredField = 'This field is required';
  static const String firstNameRequired = 'First name is required';
  static const String lastNameRequired = 'Last name is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String invalidPassword = 'Password must be at least 6 characters';
  static const String passwordMismatch = 'Passwords do not match';
  
  // Gender options
  static const List<String> genderOptions = ['Male', 'Female', 'Other', 'Prefer not to say'];
}

/// Application dimension constants
class AppDimensions {
  // Padding and margins
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  static const double iconXLarge = 48.0;
  
  // Button dimensions
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets cardMargin = EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0);
  static const EdgeInsets screenPadding = EdgeInsets.all(16.0);
  static const EdgeInsets snackBarMargin = EdgeInsets.all(16.0);
  
  // Elevation
  static const double elevationLow = 3.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // QR Code dimensions
  static const double qrCodeSize = 300.0;
  static const double qrCodeContainerSize = 320.0;
  
  // Responsive breakpoints
  static const double mobileBreakpoint = 500.0;
}

/// Application duration constants
class AppDurations {
  static const Duration snackBarShort = Duration(seconds: 2);
  static const Duration snackBarMedium = Duration(seconds: 4);
  static const Duration snackBarLong = Duration(seconds: 6);
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
}

/// Map and location constants
class MapConstants {
  static const double defaultZoom = 15.0;
  static const double detailZoom = 18.0;
  static const double markerSize = 40.0;
  
  // Default location (can be updated based on app requirements)
  static const double defaultLatitude = 37.7749;
  static const double defaultLongitude = -122.4194;
}

/// Theme configuration constants
class ThemeConstants {
  // Text styles
  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
  );
  
  static const TextStyle headlineStyle = TextStyle(
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle titleStyle = TextStyle(
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle errorTextStyle = TextStyle(
    color: AppColors.error,
    fontSize: 14,
  );
  
  // Border styles
  static const BorderSide primaryBorder = BorderSide(color: AppColors.primary, width: 2);
  static final BorderSide lightBorder = BorderSide(color: AppColors.primaryShade200);
  static final BorderSide greyBorder = BorderSide(color: AppColors.grey400);
  static const BorderSide whiteBorder = BorderSide(color: AppColors.white, width: 2);
}

/// Animation and transition constants
class AnimationConstants {
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.bounceOut;
  static const Curve elasticCurve = Curves.elasticOut;
}

/// Asset path constants (for future use)
class AssetPaths {
  static const String iconsPath = 'assets/icons/';
  static const String imagesPath = 'assets/images/';
  static const String animationsPath = 'assets/animations/';
}

/// API and configuration constants
class AppConfig {
  // Firebase project info (from firebase_options.dart)
  static const String projectId = 'parking-manager-app-iot';
  static const String storageBucket = 'parking-manager-app-iot.firebasestorage.app';
  
  // Collection names
  static const String usersCollection = 'users';
  static const String spotsCollection = 'spots';
  static const String bookingsCollection = 'bookings';
  
  // Storage paths
  static const String profileImagesPath = 'profile_images';
  
  // File extensions
  static const List<String> allowedImageExtensions = ['jpg', 'jpeg', 'png', 'gif'];
  
  // Limits
  static const int maxImageSizeMB = 5;
  static const int maxFileNameLength = 100;
}
