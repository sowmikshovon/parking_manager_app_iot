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
  static const String appTitle = 'IoT Parking';

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
  static const String downloadQrAsPdf = 'Download QR as PDF';
  static const String scanQrCode = 'Scan QR Code';
  static const String retry = 'Retry';
  static const String ok = 'OK';
  static const String confirm = 'Confirm';

  // Messages
  static const String qrCodeVerified = 'QR Code Verified!';
  static const String wrongQrCode = 'Wrong QR Code';
  static const String qrCodeMismatch =
      'The QR code you scanned does not match this parking spot at:';
  static const String scanCorrectQrCode =
      'Please scan the correct QR code for this location.';
  static const String tryAgain = 'Try Again';
  static const String scanQrCodeFor = 'Scan QR Code for:';
  static const String pointCameraAtQrCode = 'Point your camera at the QR code';

  static const String parkingSpotVerified = 'Parking spot verified at:';
  static const String scanQrCodeToVerify =
      'Scan this QR code to verify parking spot';
  static const String parkingSpotQrCode = 'Parking Spot QR Code';

  // Default user names
  static const String defaultUserName = 'User';
  static const String home = 'Home';
  // Time-related
  static const String bookedAt = 'Booked at';
  static const String availableUntil = 'Available Until:';
  static const String selectDateTime = 'Select Date & Time';
  static const String ends = 'Ends:'; // Status messages
  static const String checking = 'Checking...';
  static const String booked = 'Booked';
  static const String expired = 'Expired';
  static const String available = 'Available';
  static const String unavailable = 'Unavailable';
  static const String active = 'active';
  static const String activeStatus = 'active';
  static const String completedStatus = 'completed';
  static const String spotDeletedStatus = 'spot_deleted';

  // Validation messages
  static const String selectDateTimeMessage =
      'Please select the date and time the spot will be available until.';
  static const String availabilityMinimumMessage =
      'Availability must be at least 5 minutes in the future.';
  static const String emailRequired = 'Email is required';
  static const String firstNameMinLength =
      'First name must be at least 2 characters';
  static const String lastNameMinLength =
      'Last name must be at least 2 characters';
  static const String validEmailRequired = 'Please enter a valid email address';
  static const String requiredField = 'This field is required';
  static const String invalidPassword =
      'Password must be at least 6 characters';

  // Common messages
  static const String unknown = 'Unknown';
  static const String ongoing = 'Ongoing';
  static const String noAddress = 'No address';
  static const String noBookingHistory = 'No booking history found.';
  static const String noListedSpots = 'No listed spots.';
  static const String bookingSuccessful = 'Parking spot booked successfully!';
  static const String bookingFailed =
      'Failed to book parking spot. Please try again.';
  static const String parkingSpotListed = 'Parking spot listed successfully!';
  static const String workInProgress = 'Work in progress';
  static const String qrCodeVerifiedSuccessfully =
      'QR Code verified successfully!';
  static const String qrScanningSkipped = 'QR scanning skipped';
  static const String signUpSuccessful = 'Sign up successful! Please log in.';
  static const String signUpFailed =
      'Sign up failed. Please check your information and try again.';
  static const String loginFailed =
      'Login failed. Please check your credentials and try again.';
  static const String signInOperation = 'Sign in';
  static const String pleaseEnterEmail = 'Please enter your email address.';
  static const String pleaseEnterPassword = 'Please enter your password.';
  static const String dontHaveAccount = "Don't have an account? Sign up";

  // Page titles
  static const String welcomeBack = 'Welcome Back!';
  static const String createAccount = 'Create Account';
  static const String confirmSpotDetails = 'Confirm Spot Details';
  static const String myBookingHistory = 'My Booking History';
  static const String myListedSpots = 'My Listed Spots';
  static const String bookASpot = 'Book a Spot';
  static const String bookAParkingSpot = 'Book a Parking Spot';
  static const String listANewSpot = 'List a New Spot';
  static const String editAvailability = 'Edit Availability';

  // Navigation menu items
  static const String scanQrCodeMenuItem = 'Scan';
  static const String unbookMenuItem = 'Unbook';
  static const String mapMenuItem = 'Map';
  static const String navigateMenuItem = 'Navigate';

  // Authentication prompts
  static const String pleaseLogInBookingHistory =
      'Please log in to see your booking history.';
  static const String pleaseLogInListedSpots =
      'Please log in to see your listed spots.';
  static const String pleaseLogInToAccess = 'Please log in to access the app.';

  // Form labels
  static const String location = 'Location:';
  static const String addressOrDescription = 'Address or Description';
  static const String addressHint = 'e.g., Near the park entrance';
  static const String pleaseEnterAddress =
      'Please enter an address or description.';
  static const String confirmAndListSpot = 'CONFIRM AND LIST SPOT';
  static const String listing = 'LISTING...';
  static const String confirmBooking = 'Confirm Booking';
  static const String booking = 'BOOKING...';

  // Error messages for UI
  static const String errorLoading = 'Error: ';
  static const String noSpotsFound = 'No parking spots found at the moment.';
  static const String spotNoLongerAvailableMessage =
      'This parking spot is no longer available.';

  // Welcome messages
  static const String welcomeUser = 'Welcome, ';
  static const String manageParkingMessage =
      'Manage your parking spots and bookings';
  static const String currentBooking = 'Current Booking';
  static const String quickActions = 'Quick Actions';

  // Tooltips
  static const String profileTooltip = 'Profile';
  static const String logoutTooltip = 'Logout';
  static const String myLocationTooltip = 'My Location';

  // Operation names
  static const String checkExpiredSpotsOperation = 'Check expired spots';
  static const String unbookParkingSpotOperation = 'Unbook parking spot';
  static const String endBookingSpotUnavailableOperation =
      'End booking (spot unavailable)';
  static const String getUserNameOperation = 'Get user name';
  // Time and status messages
  static const String bookedAtPrefix = 'Booked at ';
  static const String noTimeLimit = 'No time limit';
  static const String spotUnavailable = 'Spot unavailable';
  static const String loading = 'Loading...';
  static const String hoursMinutesRemaining =
      'h '; // for "Xh Ym remaining" format
  static const String minutesRemaining = 'm remaining';

  // Booking status messages
  static const String parkingSpotSuccessfullyUnbooked =
      'Parking spot successfully unbooked!';
  static const String bookingEndedSpotUnavailable =
      'Booking ended (spot no longer available)';
  static const String parkingSpotNoLongerAvailable =
      'Parking spot no longer available';
  static const String mustBeLoggedInToBook =
      'You must be logged in to book a parking spot.';
  // Drawer and navigation labels
  static const String parkingManagerTitle = 'IoT Parking';
  // Authentication and booking messages
  static const String parkingSpotNoLongerAvailable2 =
      'This parking spot is no longer available.';
  static const String parkingSpotAlreadyBooked =
      'This parking spot has already been booked.';
  static const String parkingSpotExpired = 'This parking spot has expired.';
  static const String failedToBookSpot =
      'Failed to book parking spot. Please try again.';
  static const String bookParkingSpotOperation = 'Book parking spot';
  static const String getUserLocationOperation = 'Get user location';
  static const String mapNotReady = 'Map is not ready yet. Please try again.';
  static const String parkingEndedSuccessfully = 'Parking ended successfully!';
  static const String endParkingOperation = 'End parking';

  // Status and time messages
  static const String startedPrefix = 'Started: ';
  static const String endedPrefix = 'Ended: ';
  static const String noBookingHistoryFound = 'No booking history found.';
  static const String scanLabel = 'Scan';
  static const String mapLabel = 'Map';
  // Listing page messages
  static const String spotIdPrefix = 'Spot ID: ';
  static const String statusPrefix = 'Status: ';
  static const String availableUntilPrefix = 'Available until: ';
  static const String timeFinished = 'Time Finished';
  static const String reEnable = 'Re-enable';
  static const String editAvailabilityLabel = 'Edit';
  static const String deleteLabel = 'Delete';
  static const String showQrLabel = 'Show QR';

  // Listing operations
  static const String updateParkingSpotOperation = 'Update parking spot';
  static const String deleteParkingSpotOperation = 'Delete parking spot';
  static const String enableParkingSpotOperation = 'Enable parking spot';

  // Success/Error messages for listing
  static const String spotReenabledSuccessfully =
      'Spot re-enabled successfully!';
  static const String availabilityUpdatedSuccessfully =
      'Availability updated successfully!';
  static const String spotDeletedSuccessfully = 'Spot deleted successfully!';
  static const String errorUpdatingSpot = 'Error updating spot: ';
  static const String errorDeletingSpot = 'Error deleting spot: ';
  // Dialog messages
  static const String editAvailabilityTitle = 'Edit Availability';
  static const String selectAvailabilityUntil =
      'Select when this spot will be available until:';
  static const String update = 'Update';
  static const String deleteSpotTitle = 'Delete Spot';
  static const String deleteSpotConfirmation =
      'Are you sure you want to delete this parking spot? This action cannot be undone.';
  static const String selectFutureDateTime =
      'Please select a future date and time.';

  // Profile page constants
  static const String saveProfile = 'Save Profile';
  static const String selectImageSource = 'Select Image Source';
  static const String camera = 'Camera';
  static const String gallery = 'Gallery';

  // Profile validation messages
  static const String firstNameRequired = 'First name is required';
  static const String lastNameRequired = 'Last name is required';

  // Profile success messages
  static const String profileUpdatedSuccessfully =
      'Profile updated successfully!';

  // Profile error messages
  static const String failedToSaveProfile =
      'Failed to save profile. Please try again.';
  static const String userNotLoggedInCannotUploadImage =
      'User not logged in. Cannot upload image.';
  static const String imageFileDoesNotExist =
      'Image file does not exist at path: ';
  static const String imageFileEmpty = 'Image file is empty.';
  static const String imageUploadFailed = 'Image upload failed';
  static const String imageUploadFailedState = 'Image upload failed. State: ';
  static const String noUserLoggedIn = 'No user logged in';
  static const String imageTooLarge =
      'Image file is too large. Please select an image smaller than 5MB.';
  static const String failedToPickImage = 'Failed to pick image.';
  static const String failedToUpdateProfile = 'Failed to update profile.';
  // Gender options
  static const String male = 'Male';
  static const String female = 'Female';
  static const String other = 'Other';
  static const String preferNotToSay = 'Prefer not to say';
  static const String nextButtonLabel = 'Next';

  //Return to Home button
  static const String returnToHome = 'Return to Home';
}

/// Error handling string constants
class ErrorStrings {
  // Dialog titles
  static const String authenticationError = 'Authentication Error';
  static const String databaseError = 'Database Error';
  static const String locationError = 'Location Error';
  static const String networkError = 'Network Error';
  static const String error = 'Error';

  // Default operations
  static const String authenticationOperation = 'Authentication';
  static const String databaseOperation = 'Database operation';
  static const String locationAccessOperation = 'Location access';
  static const String networkRequestOperation = 'Network request';
  static const String operation = 'Operation';
  static const String bookingOperation = 'Booking operation';
  static const String spotListingOperation = 'Spot listing';
  static const String getUserNameOperation = 'Get user name';

  // Booking error messages
  static const String spotNoLongerAvailable =
      'The parking spot is no longer available.';
  static const String noPermissionAction =
      'You don\'t have permission to perform this action.';
  static const String serviceUnavailable =
      'Service is currently unavailable. Please try again later.';

  // Spot listing error messages
  static const String mustBeLoggedIn = 'You must be logged in to list a spot.';
  static const String noPermissionListSpots =
      'You don\'t have permission to list spots.';

  // Location error messages
  static const String locationPermissionRequired =
      'Location permission required. Please enable location access in Settings.';
  static const String locationServicesDisabled =
      'Location services are disabled. Please enable them in Settings.';
  static const String locationRequestTimeout =
      'Location request timed out. Please try again.';
  static const String couldNotGetLocation =
      'Could not get your location. Please try again.';

  // Error detection strings (used in contains() checks)
  static const String documentNotExist = 'document does not exist';
  static const String notFound = 'not found';
  static const String permissionDenied = 'permission-denied';
  static const String unavailable = 'unavailable';
  static const String unauthenticated = 'unauthenticated';
  static const String noLocationPermissions = 'No location permissions';
  static const String permissions = 'permissions';
  static const String locationServices = 'Location services';
  static const String disabled = 'disabled';
  static const String timeout = 'timeout';
  static const String timeoutException = 'TimeoutException';
  static const String location = 'location';
  static const String locationCapitalized = 'Location';
  static const String permission = 'permission';
  static const String network = 'network';
  static const String connection = 'connection';
  // Validation error messages
  static const String addressRequired = 'Address is required';
  static const String futureDateTimeRequired =
      'Selected date and time must be in the future';
  // Exception messages
  static const String userNameNotFound = 'User name not found';
  static const String userNotAuthenticated = 'User not authenticated';
  // Default operation name for retry operations
  static const String defaultRetryOperation = 'Operation'; // Operation names
  static const String spotListingOperationName = 'Spot listing';
  static const String getUserNameOperationName = 'Get user name';
  static const String deleteParkingSpotOperation = 'Delete parking spot';
  static const String updateParkingSpotOperation = 'Update parking spot';

  // Profile operation names
  static const String loadUserProfileOperation = 'Load user profile';
  static const String pickImageOperation = 'Pick image';
  static const String uploadProfileImageOperation = 'Upload profile image';
  static const String saveProfileOperation = 'Save profile';

  static const String createAccountOperation = 'Create account';
  static const String signupSuccessMessage =
      'Sign up successful! Please log in.';
  static const String signupFailedMessage =
      'Sign up failed. Please check your information and try again.';
}

/// Authentication error messages
class AuthErrorMessages {
  static const String userNotFound = 'No user found with this email address.';
  static const String wrongPassword = 'Incorrect password. Please try again.';
  static const String emailAlreadyInUse =
      'An account already exists with this email address.';
  static const String weakPassword =
      'Password is too weak. Please choose a stronger password.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String userDisabled =
      'This account has been disabled. Please contact support.';
  static const String tooManyRequests =
      'Too many failed attempts. Please try again later.';
  static const String operationNotAllowed =
      'This sign-in method is not enabled. Please contact support.';
  static const String invalidCredential =
      'Invalid credentials. Please check your email and password.';
  static const String networkRequestFailed =
      'Network error. Please check your internet connection.';
  static const String requiresRecentLogin = 'Please sign in again to continue.';
  static const String defaultAuthError =
      'Authentication failed. Please try again.';
}

/// Database error messages
class DatabaseErrorMessages {
  static const String permissionDenied =
      'You don\'t have permission to perform this action.';
  static const String unavailable =
      'Service is currently unavailable. Please try again later.';
  static const String notFound = 'The requested data was not found.';
  static const String alreadyExists = 'This data already exists.';
  static const String resourceExhausted =
      'Service quota exceeded. Please try again later.';
  static const String failedPrecondition =
      'Operation failed due to invalid state.';
  static const String aborted = 'Operation was aborted. Please try again.';
  static const String outOfRange = 'Invalid data range provided.';
  static const String unimplemented = 'This feature is not yet implemented.';
  static const String internal =
      'Internal server error. Please try again later.';
  static const String deadlineExceeded = 'Request timed out. Please try again.';
  static const String unauthenticated =
      'You must be signed in to perform this action.';
  static const String defaultDatabaseError =
      'Database error occurred. Please try again.';
}

/// General error messages
class GeneralErrorMessages {
  static const String noInternetConnection =
      'No internet connection. Please check your network settings.';
  static const String serverError = 'Server error. Please try again later.';
  static const String notFound = 'The requested item was not found.';
  static const String unauthorized =
      'You are not authorized to perform this action.';
  static const String validationFailed =
      'Please check your input and try again.';
  static const String unknownError =
      'An unexpected error occurred. Please try again.';
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
  static const EdgeInsets buttonPadding =
      EdgeInsets.symmetric(horizontal: 24, vertical: 12);
  static const EdgeInsets cardMargin =
      EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0);
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
  static const BorderSide primaryBorder =
      BorderSide(color: AppColors.primary, width: 2);
  static final BorderSide lightBorder =
      BorderSide(color: AppColors.primaryShade200);
  static final BorderSide greyBorder = BorderSide(color: AppColors.grey400);
  static const BorderSide whiteBorder =
      BorderSide(color: AppColors.white, width: 2);
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
  static const String storageBucket =
      'parking-manager-app-iot.firebasestorage.app';

  // Collection names
  static const String usersCollection = 'users';
  static const String spotsCollection = 'spots';
  static const String bookingsCollection = 'bookings';

  // Storage paths
  static const String profileImagesPath = 'profile_images';

  // File extensions
  static const List<String> allowedImageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif'
  ];

  // Limits
  static const int maxImageSizeMB = 5;
  static const int maxFileNameLength = 100;
  static const String signInOperation = 'Sign in';
}
