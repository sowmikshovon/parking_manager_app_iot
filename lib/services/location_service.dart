import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// LocationService class for handling geolocation
class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      print('LocationService: Starting location request...');

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      print('LocationService: Location services enabled: $serviceEnabled');
      if (!serviceEnabled) {
        print('Location services are disabled.');
        return null;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      print('LocationService: Current permission status: $permission');

      if (permission == LocationPermission.denied) {
        print('LocationService: Requesting location permission...');
        permission = await Geolocator.requestPermission();
        print('LocationService: Permission after request: $permission');
        if (permission == LocationPermission.denied) {
          print('Location permissions are denied');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        print(
            'Location permissions are permanently denied, we cannot request permissions.');
        // For permanently denied permissions, we could open app settings
        return null;
      }

      print('LocationService: Getting current position...');
      // Get current position with better accuracy settings
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Increased timeout
      );

      print('Location obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      print('Error getting location: $e');
      // Check if this is a specific geolocator error
      if (e.toString().contains('No location permissions')) {
        print('LocationService: Permissions issue detected');
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
        print('Camera moved to user location');
      } else {
        print('Could not get user location to move camera');
      }
    } catch (e) {
      print('Error moving camera to user location: $e');
    }
  }
}
