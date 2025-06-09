import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/location_service.dart';
import '../services/error_service.dart';
import '../utils/snackbar_utils.dart';
import 'address_entry_page.dart';
import '../utils/app_constants.dart';

class ListSpotPage extends StatefulWidget {
  const ListSpotPage({super.key});

  @override
  State<ListSpotPage> createState() => _ListSpotPageState();
}

class _ListSpotPageState extends State<ListSpotPage> {
  LatLng? _selectedLatLng;
  GoogleMapController? _mapController; // Add map controller

  Future<CameraPosition> _getInitialCameraPosition() async {
    final position = await LocationService.getCurrentLocation();
    if (position != null) {
      return CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 14,
      );
    } // Fallback to default coordinates if location is not available
    return const CameraPosition(
      target: LatLng(23.7624, 90.3785),
      zoom: 14,
    );
  } // Method to move camera to user location

  Future<void> _moveToUserLocation() async {
    await ErrorService.executeWithErrorHandling(
      context,
      () async {
        if (_mapController != null) {
          await LocationService.moveToUserLocation(_mapController!);
        } else {
          // print('Map controller is not initialized');
          if (mounted) {
            SnackBarUtils.showWarning(context, AppStrings.mapNotReady);
          }
        }
      },
      operationName: AppStrings.getUserLocationOperation,
      onRetry: _moveToUserLocation,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.selectLocation)),
      body: FutureBuilder<CameraPosition>(
        future: _getInitialCameraPosition(),
        builder: (context, cameraSnapshot) {
          if (cameraSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final initialPosition = cameraSnapshot.data ??
              const CameraPosition(
                target: LatLng(23.7624, 90.3785),
                zoom: 14,
              );
          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: initialPosition,
                markers: _selectedLatLng == null
                    ? {}
                    : {
                        Marker(
                          markerId: const MarkerId('selected'),
                          position: _selectedLatLng!,
                        ),
                      },
                onTap: (latLng) {
                  setState(() {
                    _selectedLatLng = latLng;
                  });
                },
                myLocationEnabled: true,
                myLocationButtonEnabled:
                    false, // Disable default to use custom button
                onMapCreated: (GoogleMapController controller) async {
                  _mapController = controller; // Store controller reference
                },
              ),
              // Custom My Location button
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.teal,
                  onPressed: _moveToUserLocation,
                  tooltip: AppStrings.myLocationTooltip,
                  child: const Icon(Icons.my_location),
                ),
              ),
              if (_selectedLatLng != null)
                Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 16,
                        ),
                        backgroundColor: Colors.teal,
                      ),
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => AddressEntryPage(
                                selectedLatLng: _selectedLatLng!),
                          ),
                        );
                      },
                      child: Text(AppStrings.nextButtonLabel),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
