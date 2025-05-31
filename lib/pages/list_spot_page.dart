import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'address_entry_page.dart';

class ListSpotPage extends StatefulWidget {
  const ListSpotPage({super.key});

  @override
  State<ListSpotPage> createState() => _ListSpotPageState();
}

class _ListSpotPageState extends State<ListSpotPage> {
  LatLng? _selectedLatLng;
  static const LatLng _initialLatLng = LatLng(23.7624, 90.3785);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Location')),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialLatLng,
              zoom: 14,
            ),
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
            myLocationButtonEnabled: true,
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            AddressEntryPage(selectedLatLng: _selectedLatLng!),
                      ),
                    );
                  },
                  child: const Text('Next'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
