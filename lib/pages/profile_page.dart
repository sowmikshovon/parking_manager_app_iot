import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../utils/snackbar_utils.dart';
import '../utils/date_time_utils.dart';
import '../utils/app_constants.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _dateController = TextEditingController();

  String _selectedGender = AppStrings.preferNotToSay;
  final List<String> _genderOptions = [
    AppStrings.male,
    AppStrings.female,
    AppStrings.other,
    AppStrings.preferNotToSay,
  ];

  DateTime? _selectedDate;
  File? _imageFile;
  String? _profileImageUrl;
  bool _isLoading = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _testFirebaseStorageConnection();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Get user data from Firestore
        final userData = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userData.exists) {
          final data = userData.data()!;

          // Parse the name into first and last name
          final name = data['name'] as String? ?? '';
          final nameParts = name.split(' ');
          if (nameParts.isNotEmpty) {
            _firstNameController.text = nameParts.first;

            if (nameParts.length > 1) {
              _lastNameController.text = nameParts.sublist(1).join(' ');
            }
          }

          // Set gender if available
          if (data['gender'] != null) {
            setState(() {
              _selectedGender = data['gender'];
            });
          }

          // Set date of birth if available
          if (data['dateOfBirth'] != null) {
            final dob = (data['dateOfBirth'] as Timestamp).toDate();
            setState(() {
              _selectedDate = dob;
              _dateController.text = DateTimeUtils.formatDate(dob);
            });
          }

          // Set profile image URL if available
          if (data['profileImageUrl'] != null) {
            setState(() {
              _profileImageUrl = data['profileImageUrl'];
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load profile: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFirebaseStorageConnection() async {
    try {
      // Test Firebase Storage connection by attempting to list files
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final storageRef =
            FirebaseStorage.instance.ref().child('profile_images');
        await storageRef.listAll();
        print('Firebase Storage connection successful');
      }
    } catch (e) {
      print('Firebase Storage connection test failed: $e');
      // Don't show error to user for this test, just log it
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();

      // Show options for camera or gallery
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(AppStrings.selectImageSource),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text(AppStrings.camera),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text(AppStrings.gallery),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source != null) {
        final pickedImage = await picker.pickImage(
          source: source,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85, // Good balance between quality and file size
        );

        if (pickedImage != null) {
          final file = File(pickedImage.path);

          // Check file size (limit to 5MB)
          final fileSize = await file.length();
          if (fileSize > 5 * 1024 * 1024) {
            if (mounted) {
              setState(() {
                _error = AppStrings.imageTooLarge;
              });
            }
            return;
          }

          setState(() {
            _imageFile = file;
            _error = null; // Clear any previous errors
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = AppStrings.failedToPickImage + ': $e';
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateTimeUtils.formatDate(picked);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_imageFile == null) {
      return _profileImageUrl; // Return existing URL if no new image
    }

    // Clear previous image-specific errors before attempting upload
    setState(() {
      _error = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = AppStrings.userNotLoggedInCannotUploadImage;
        });
        return null;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${user.uid}.jpg');

      // Optional: Add metadata
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      if (!await _imageFile!.exists()) {
        setState(() {
          _error = AppStrings.imageFileDoesNotExist + ': ${_imageFile!.path}';
        });
        return null;
      }
      if (await _imageFile!.length() == 0) {
        setState(() {
          _error = AppStrings.imageFileEmpty;
        });
        return null;
      }

      print('Attempting to upload image to: ${storageRef.fullPath}');
      UploadTask uploadTask = storageRef.putFile(_imageFile!, metadata);

      // Await the completion of the upload task
      TaskSnapshot snapshot = await uploadTask
          .whenComplete(() => {}); // Ensures the task is fully processed

      if (snapshot.state == TaskState.success) {
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        print('Image uploaded successfully. Download URL: $downloadUrl');
        return downloadUrl;
      } else {
        // This case might not be hit if errors throw exceptions instead
        print(
            'Image upload failed. State: ${snapshot.state}, Bytes Transferred: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
        setState(() {
          _error = AppStrings.imageUploadFailedState + ': ${snapshot.state}';
        });
        return null;
      }
    } on FirebaseException catch (e) {
      print(
          'Firebase Storage Exception during image upload. Code: ${e.code}. Message: ${e.message}. StackTrace: ${e.stackTrace}');
      String displayError = AppStrings.imageUploadFailed + ': ${e.message ?? "Unknown Firebase error"}';
      if (e.code == 'object-not-found') {
        displayError = AppStrings.imageUploadFailed + ': The file was not found after attempting upload. Check permissions or network.';
      } else if (e.code == 'unauthorized' || e.code == 'permission-denied') {
        displayError = AppStrings.imageUploadFailed + ': Permission denied. Check Firebase Storage rules.';
      }
      setState(() {
        _error = displayError;
      });
      return null;
    } catch (e, stackTrace) {
      print(
          'Generic Exception during image upload: $e. StackTrace: $stackTrace');
      setState(() {
        _error = AppStrings.imageUploadFailed + ': An unexpected error occurred. $e';
      });
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null; // Clear general errors before saving
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = AppStrings.noUserLoggedIn;
          _isLoading = false; // Ensure loading is stopped
        });
        return;
      }

      String? imageUrl =
          _profileImageUrl; // Default to existing or previously fetched URL

      if (_imageFile != null) {
        // If a new image was picked
        imageUrl = await _uploadImage(); // Attempt to upload it
        if (imageUrl == null) {
          // _uploadImage already set an error and printed to console.
          // Stop the save process if upload failed.
          setState(() {
            _isLoading = false;
          });
          if (mounted) {
            // Check if the widget is still in the tree
            SnackBarUtils.showError(
                context, _error ?? AppStrings.imageUploadFailed + '. Profile not saved.');
          }
          return;
        }
      }

      // Create user profile data
      final userData = <String, dynamic>{
        // Explicitly type the map
        'name':
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'email': user.email,
        'gender': _selectedGender,
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (_selectedDate != null) {
        userData['dateOfBirth'] = Timestamp.fromDate(_selectedDate!);
      }

      if (imageUrl != null) {
        userData['profileImageUrl'] = imageUrl;
      } else {
        // If no image is set (either initially or after attempting an upload that might have cleared it),
        // you might want to explicitly remove it from Firestore.
        // userData['profileImageUrl'] = FieldValue.delete(); // Uncomment if you want to remove the field
      }

      // Update the user data in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData, SetOptions(merge: true)); // Use set with merge:true

      if (mounted) {
        SnackBarUtils.showSuccess(context, AppStrings.profileUpdatedSuccessfully);
      }
    } on FirebaseException catch (e) {
      // Catch Firestore specific errors
      print(
          'Firestore Exception during profile save: ${e.code} - ${e.message}');
      setState(() {
        _error = AppStrings.failedToSaveProfile + ': ${e.message ?? "Unknown Firebase error"} (Code: ${e.code})';
      });
    } catch (e) {
      // Catch any other errors
      print('Generic Exception during profile save: $e');
      setState(() {
        _error = AppStrings.failedToSaveProfile + ': $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.editProfile)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Profile Image Section
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : _profileImageUrl != null
                                    ? NetworkImage(_profileImageUrl!)
                                        as ImageProvider
                                    : null,
                            child:
                                (_imageFile == null && _profileImageUrl == null)
                                    ? const Icon(
                                        Icons.person,
                                        size: 80,
                                        color: Colors.grey,
                                      )
                                    : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error Message if any
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // First & Last Name (side by side on larger screens)
                    if (screenWidth > 500)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: AppStrings.firstName,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppStrings.firstNameRequired;
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: AppStrings.lastName,
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppStrings.lastNameRequired;
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          TextFormField(
                            controller: _firstNameController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.firstName,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppStrings.firstNameRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _lastNameController,
                            decoration: const InputDecoration(
                              labelText: AppStrings.lastName,
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return AppStrings.lastNameRequired;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                    const SizedBox(height: 16),

                    // Date of Birth
                    GestureDetector(
                      onTap: _selectDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _dateController,
                          decoration: const InputDecoration(
                            labelText: AppStrings.dateOfBirth,
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.calendar_today),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Gender selection
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: AppStrings.gender,
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedGender,
                      items: _genderOptions
                          .map(
                            (gender) => DropdownMenuItem<String>(
                              value: gender,
                              child: Text(gender),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedGender = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveProfile,
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                AppStrings.saveProfile,
                                style: TextStyle(fontSize: 16),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
