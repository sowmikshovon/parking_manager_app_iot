import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../qr_pdf_util.dart';

class QrCodePage extends StatelessWidget {
  final String spotId;
  final String address;

  const QrCodePage({super.key, required this.spotId, required this.address});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Spot QR Code')),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Parking Spot QR Code',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                QrImageView(
                  data: spotId,
                  version: QrVersions.auto,
                  size: 200.0,
                ),
                const SizedBox(height: 16),
                Text(
                  'Spot ID: $spotId',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  address,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download QR as PDF'),
                  onPressed: () async {
                    await saveQrCodeAsPdf(
                      context: context,
                      spotId: spotId,
                      address: address,
                      qrData: spotId,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
