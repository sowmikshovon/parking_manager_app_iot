/// Utility class for form validation across the app
class ValidationUtils {
  /// Validates email format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validates password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  /// Validates confirm password field matches original password
  static String? validateConfirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  /// Validates required text field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates name field (first name, last name)
  static String? validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    
    // Check for valid name characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value.trim())) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  /// Validates phone number format
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional in most cases
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number cannot exceed 15 digits';
    }
    
    return null;
  }

  /// Validates address field
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an address or description';
    }
    
    if (value.trim().length < 5) {
      return 'Address must be at least 5 characters';
    }
    
    return null;
  }

  /// Validates DateTime is in the future by specified minutes
  static String? validateFutureDateTime(DateTime? dateTime, {int minimumMinutes = 5}) {
    if (dateTime == null) {
      return 'Please select date and time';
    }
    
    final minimumTime = DateTime.now().add(Duration(minutes: minimumMinutes));
    if (dateTime.isBefore(minimumTime)) {
      return 'Time must be at least $minimumMinutes minutes in the future';
    }
    
    return null;
  }

  /// Validates file size is within limits (in bytes)
  static String? validateFileSize(int fileSizeBytes, {int maxSizeMB = 5}) {
    final maxSizeBytes = maxSizeMB * 1024 * 1024;
    
    if (fileSizeBytes > maxSizeBytes) {
      return 'File size must be less than ${maxSizeMB}MB';
    }
    
    return null;
  }

  /// Validates image file extension
  static String? validateImageFile(String fileName) {
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'];
    final extension = fileName.toLowerCase().substring(fileName.lastIndexOf('.'));
    
    if (!allowedExtensions.contains(extension)) {
      return 'Please select a valid image file (JPG, PNG, GIF, BMP, WebP)';
    }
    
    return null;
  }

  /// Validates age is within reasonable range
  static String? validateAge(DateTime? birthDate) {
    if (birthDate == null) {
      return null; // Birth date is optional in most cases
    }
    
    final today = DateTime.now();
    final age = today.year - birthDate.year;
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Please enter a valid birth date';
    }
    
    return null;
  }

  /// Validates text length is within specified range
  static String? validateLength(String? value, String fieldName, {int? minLength, int? maxLength}) {
    if (value == null || value.trim().isEmpty) {
      return null; // Use validateRequired for required fields
    }
    
    final length = value.trim().length;
    
    if (minLength != null && length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    if (maxLength != null && length > maxLength) {
      return '$fieldName cannot exceed $maxLength characters';
    }
    
    return null;
  }

  /// Validates URL format
  static String? validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // URL is typically optional
    }
    
    try {
      final uri = Uri.parse(value.trim());
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return 'Please enter a valid URL (starting with http:// or https://)';
      }
      return null;
    } catch (e) {
      return 'Please enter a valid URL';
    }
  }
}
