import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// LocationService class for handling geolocation
class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      // Debug logging disabled in production

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      // Debug logging disabled in production
      if (!serviceEnabled) {
        // Debug logging disabled in production
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      // Debug logging disabled in production

      if (permission == LocationPermission.denied) {
        // Debug logging disabled in production
        permission = await Geolocator.requestPermission();
        // Debug logging disabled in production
        if (permission == LocationPermission.denied) {
          // Debug logging disabled in production
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // Debug logging disabled in production
        // For permanently denied permissions, we could open app settings
        return null;
      }

      // Debug logging disabled in production
      // Get current position with better accuracy settings
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Increased timeout
      );

      // Debug logging disabled in production
      return position;
    } catch (e) {
      // Debug logging disabled in production
      // Check if this is a specific geolocator error
      if (e.toString().contains('No location permissions')) {
        // Debug logging disabled in production
      }
      return null;
    }
  }

  static Future<void> moveToUserLocation(GoogleMapController controller) async {
    try {
      final position = await getCurrentLocation();
      if (position != null) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16,
            ),
          ),
        );
        // Debug logging disabled in production
      } else {
        // Debug logging disabled in production
      }
    } catch (e) {
      // Debug logging disabled in production
    }
  }
}
