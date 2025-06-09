import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_time_utils.dart';
import '../utils/snackbar_utils.dart';
import '../utils/error_handler.dart';
import '../utils/app_constants.dart';
import '../services/error_service.dart';
import '../services/booking_service.dart';
import 'qr_code_page.dart';

class AddressEntryPage extends StatefulWidget {
  final LatLng selectedLatLng;
  const AddressEntryPage({super.key, required this.selectedLatLng});

  @override
  State<AddressEntryPage> createState() => _AddressEntryPageState();
}

class _AddressEntryPageState extends State<AddressEntryPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  DateTime? _selectedDateTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      helpText: 'SELECT AVAILABILITY END DATE',
    );

    if (date != null && context.mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
            _selectedDateTime ?? date.add(const Duration(hours: 1))),
        helpText: 'SELECT AVAILABILITY END TIME',
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitSpot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check for existing active bookings before allowing new spot creation
    final hasActiveBooking = await BookingService.hasActiveBookings();
    if (hasActiveBooking) {
      if (mounted) {
        SnackBarUtils.showWarning(context,
            'You already have an active booking. Please complete your current booking before listing a new spot.\n\nNote: Multiple simultaneous bookings are not supported in this version. This feature may be added in future updates.');
      }
      return;
    }

    // Validate input using ErrorService
    try {
      ErrorService.validateUserInput(
        address: _addressController.text,
        selectedDateTime: _selectedDateTime,
      );
    } on ValidationException catch (e) {
      ErrorService.handleValidationError(context, e);
      return;
    }
    if (_selectedDateTime == null) {
      SnackBarUtils.showWarning(context, AppStrings.selectDateTimeMessage);
      return;
    }
    // Ensure the selected date and time is in the future
    if (_selectedDateTime!
        .isBefore(DateTime.now().add(const Duration(minutes: 5)))) {
      SnackBarUtils.showWarning(context, AppStrings.availabilityMinimumMessage);
      return;
    }

    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ErrorService.handleAuthError(
          context,
          Exception(ErrorStrings.userNotAuthenticated),
          operation: ErrorStrings.spotListingOperationName,
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Execute spot listing with error handling
    final result = await ErrorService.executeWithErrorHandling(
      context,
      () async {
        final docRef =
            await FirebaseFirestore.instance.collection('parking_spots').add({
          'ownerId': user.uid,
          'ownerEmail': user.email,
          'address': _addressController.text,
          'latitude': widget.selectedLatLng.latitude,
          'longitude': widget.selectedLatLng.longitude,
          'availableUntil': Timestamp.fromDate(_selectedDateTime!),
          'isAvailable': true,
          'createdAt': Timestamp.now(),
        });

        return docRef.id;
      },
      operationName: ErrorStrings.spotListingOperationName,
      showSnackBar: true,
    );

    setState(() => _isLoading = false);

    if (result != null && mounted) {
      // Navigate to QR code page on successful listing
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => QrCodePage(
            spotId: result,
            address: _addressController.text,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Spot Details'),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Location:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Lat: ${widget.selectedLatLng.latitude.toStringAsFixed(6)}, Lng: ${widget.selectedLatLng.longitude.toStringAsFixed(6)}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Address or Description',
                  hintText: 'e.g., Near the park entrance',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an address or description.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Available Until:',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _selectDateTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _selectedDateTime == null
                              ? 'Select Date & Time'
                              : 'Ends: ${DateTimeUtils.formatDateTime(context, _selectedDateTime!)}',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: _selectedDateTime == null
                                        ? Theme.of(context).hintColor
                                        : null,
                                  ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              if (_selectedDateTime == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Please select when your spot will be available until.',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12),
                  ),
                ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline),
                label:
                    Text(_isLoading ? 'LISTING...' : 'CONFIRM AND LIST SPOT'),
                onPressed: _isLoading ? null : _submitSpot,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
