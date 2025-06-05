/// User utilities for Firebase user operations and profile management
/// Provides standardized user authentication, profile management, and user data operations
library;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/data_models.dart';
import '../utils/app_constants.dart';
import '../utils/error_handler.dart';
import '../utils/validation_utils.dart';

/// Service class for user operations and profile management
class UserService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Collection references
  static CollectionReference get _usersCollection =>
      _firestore.collection(AppConfig.usersCollection);

  /// Get current authenticated user
  static User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentUser != null;

  /// Get current user's email
  static String? get userEmail => currentUser?.email;

  /// Get current user's ID
  static String? get userId => currentUser?.uid;

  /// Sign in with email and password
  static Future<Result<UserCredential>> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return Result.execute(() async {
      ErrorHandler.validateEmail(email);
      ErrorHandler.validatePassword(password);

      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      return credential;
    });
  }

  /// Create account with email and password
  static Future<Result<UserCredential>> createAccountWithEmailPassword(
    String email,
    String password,
    String confirmPassword,
  ) async {
    return Result.execute(() async {
      ErrorHandler.validateEmail(email);
      ErrorHandler.validatePassword(password);
      
      if (password != confirmPassword) {
        throw const ValidationException('Passwords do not match');
      }

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Create user profile document
      if (credential.user != null) {
        await createUserProfile(credential.user!);
      }

      return credential;
    });
  }

  /// Sign out current user
  static Future<Result<void>> signOut() async {
    return Result.execute(() async {
      await _auth.signOut();
    });
  }

  /// Send password reset email
  static Future<Result<void>> sendPasswordResetEmail(String email) async {
    return Result.execute(() async {
      ErrorHandler.validateEmail(email);
      await _auth.sendPasswordResetEmail(email: email.trim());
    });
  }

  /// Update user password
  static Future<Result<void>> updatePassword(
    String currentPassword,
    String newPassword,
  ) async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      ErrorHandler.validatePassword(newPassword);

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);
    });
  }

  /// Update user email
  static Future<Result<void>> updateEmail(String newEmail) async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      ErrorHandler.validateEmail(newEmail);
      await user.updateEmail(newEmail.trim());

      // Update email in user profile document
      await updateUserProfile({'email': newEmail.trim()});
    });
  }

  /// Create user profile document in Firestore
  static Future<void> createUserProfile(User user) async {
    final userProfile = UserProfile(
      id: user.uid,
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );

    await _usersCollection.doc(user.uid).set(userProfile.toMap());
  }

  /// Get user profile from Firestore
  static Future<Result<UserProfile?>> getUserProfile([String? uid]) async {
    return Result.execute(() async {
      final targetUid = uid ?? userId;
      if (targetUid == null) {
        throw const AuthenticationException('User not authenticated');
      }

      final doc = await _usersCollection.doc(targetUid).get();
      if (doc.exists) {
        return UserProfile.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Update user profile in Firestore
  static Future<Result<void>> updateUserProfile(
    Map<String, dynamic> data,
  ) async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      // Add update timestamp
      data['updatedAt'] = Timestamp.fromDate(DateTime.now());

      await _usersCollection.doc(user.uid).update(data);
    });
  }

  /// Update complete user profile with validation
  static Future<Result<void>> updateCompleteUserProfile({
    String? firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? profileImageUrl,
  }) async {
    return Result.execute(() async {
      // Validate input
      if (firstName != null && firstName.trim().isNotEmpty) {
        final nameError = ValidationUtils.validateName(firstName, 'First Name');
        if (nameError != null) {
          throw ValidationException(nameError);
        }
      }

      if (lastName != null && lastName.trim().isNotEmpty) {
        final nameError = ValidationUtils.validateName(lastName, 'Last Name');
        if (nameError != null) {
          throw ValidationException(nameError);
        }
      }

      if (dateOfBirth != null) {
        final ageError = ValidationUtils.validateAge(dateOfBirth);
        if (ageError != null) {
          throw ValidationException(ageError);
        }
      }

      // Prepare update data
      final Map<String, dynamic> updateData = {};

      if (firstName != null) updateData['firstName'] = firstName.trim();
      if (lastName != null) updateData['lastName'] = lastName.trim();
      if (dateOfBirth != null) updateData['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      if (gender != null) updateData['gender'] = gender;
      if (profileImageUrl != null) updateData['profileImageUrl'] = profileImageUrl;

      // Update profile
      await updateUserProfile(updateData);
    });
  }

  /// Upload profile image and update profile
  static Future<Result<String>> uploadProfileImage(File imageFile) async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      // Validate file
      final imageFileName = imageFile.path.split('/').last;
      final imageError = ValidationUtils.validateImageFile(imageFileName);
      if (imageError != null) {
        throw ValidationException(imageError);
      }

      final fileSizeError = ValidationUtils.validateFileSize(imageFile.lengthSync(), maxSizeMB: AppConfig.maxImageSizeMB);
      if (fileSizeError != null) {
        throw ValidationException(fileSizeError);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final filename = '${user.uid}_$timestamp.$extension';

      // Upload to Firebase Storage
      final storageRef = _storage
          .ref()
          .child(AppConfig.profileImagesPath)
          .child(filename);

      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update user profile with new image URL
      await updateUserProfile({'profileImageUrl': downloadUrl});

      return downloadUrl;
    });
  }

  /// Delete profile image
  static Future<Result<void>> deleteProfileImage() async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      // Get current profile to find image URL
      final profileResult = await getUserProfile();
      if (profileResult.isSuccess && profileResult.data?.profileImageUrl != null) {
        try {
          // Delete from Firebase Storage
          final ref = _storage.refFromURL(profileResult.data!.profileImageUrl!);
          await ref.delete();
        } catch (e) {
          // Log error but don't fail the operation
          ErrorHandler.logError('Delete profile image from storage', e);
        }
      }

      // Remove image URL from profile
      await updateUserProfile({'profileImageUrl': null});
    });
  }

  /// Delete user account and all associated data
  static Future<Result<void>> deleteUserAccount(String password) async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete profile image if exists
      await deleteProfileImage();

      // Delete user profile document
      await _usersCollection.doc(user.uid).delete();

      // Delete user account
      await user.delete();
    });
  }

  /// Check if email is already registered
  static Future<Result<bool>> isEmailRegistered(String email) async {
    return Result.execute(() async {
      ErrorHandler.validateEmail(email);
      
      try {
        final methods = await _auth.fetchSignInMethodsForEmail(email.trim());
        return methods.isNotEmpty;
      } catch (e) {
        if (e is FirebaseAuthException && e.code == 'user-not-found') {
          return false;
        }
        rethrow;
      }
    });
  }

  /// Send email verification
  static Future<Result<void>> sendEmailVerification() async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      if (user.emailVerified) {
        throw const ValidationException('Email is already verified');
      }

      await user.sendEmailVerification();
    });
  }

  /// Reload user to check email verification status
  static Future<Result<bool>> reloadAndCheckEmailVerification() async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    });
  }

  /// Update user display name
  static Future<Result<void>> updateDisplayName(String displayName) async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      if (displayName.trim().isEmpty) {
        throw const ValidationException('Display name cannot be empty');
      }

      await user.updateDisplayName(displayName.trim());
    });
  }

  /// Get user's authentication method
  static List<String> getUserAuthMethods() {
    final user = currentUser;
    if (user == null) return [];
    
    return user.providerData.map((info) => info.providerId).toList();
  }

  /// Check if user is anonymous
  static bool get isAnonymous => currentUser?.isAnonymous ?? false;

  /// Check if email is verified
  static bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Get user creation time
  static DateTime? get userCreationTime => currentUser?.metadata.creationTime;

  /// Get last sign-in time
  static DateTime? get lastSignInTime => currentUser?.metadata.lastSignInTime;

  /// Stream of authentication state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Stream of user changes (including profile updates)
  static Stream<User?> get userChanges => _auth.userChanges();

  /// Listen to user profile changes
  static Stream<UserProfile?> streamUserProfile([String? uid]) {
    final targetUid = uid ?? userId;
    if (targetUid == null) {
      return Stream.error('User not authenticated');
    }

    return _usersCollection.doc(targetUid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserProfile.fromFirestore(snapshot);
      }
      return null;
    });
  }

  /// Re-authenticate user (required for sensitive operations)
  static Future<Result<void>> reauthenticateWithPassword(String password) async {
    return Result.execute(() async {
      final user = currentUser;
      if (user == null) {
        throw const AuthenticationException('User not authenticated');
      }

      if (user.email == null) {
        throw const AuthenticationException('User email not available');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      
      await user.reauthenticateWithCredential(credential);
    });
  }

  /// Get formatted user display name
  static String getDisplayName([UserProfile? profile]) {
    final user = currentUser;
    if (user == null) return 'Guest';

    // Try profile data first
    if (profile != null) {
      if (profile.fullName.isNotEmpty) {
        return profile.fullName;
      }
    }

    // Fall back to Firebase user data
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    // Fall back to email
    return user.email ?? 'User';
  }

  /// Check if user has completed profile setup
  static Future<Result<bool>> hasCompletedProfileSetup() async {
    return Result.execute(() async {
      final profileResult = await getUserProfile();
      if (!profileResult.isSuccess || profileResult.data == null) {
        return false;
      }

      final profile = profileResult.data!;
      return profile.firstName != null && 
             profile.lastName != null && 
             profile.dateOfBirth != null;
    });
  }
}

/// User authentication state notifier
class AuthNotifier extends ChangeNotifier {
  User? _user;
  UserProfile? _profile;
  bool _isLoading = false;

  User? get user => _user;
  UserProfile? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  AuthNotifier() {
    _initAuthListener();
  }

  void _initAuthListener() {
    UserService.authStateChanges.listen((user) async {
      _user = user;
      
      if (user != null) {
        await _loadUserProfile();
      } else {
        _profile = null;
      }
      
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    _isLoading = true;
    notifyListeners();

    final result = await UserService.getUserProfile();
    if (result.isSuccess) {
      _profile = result.data;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadUserProfile();
    }
  }
}
