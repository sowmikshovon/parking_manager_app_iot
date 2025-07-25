// ...existing code from qr_pdf_util.dart...
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';

Future<void> saveQrCodeAsPdf({
  required BuildContext context,
  required String spotId,
  required String address,
  required String qrData,
}) async {
  final pdf = pw.Document();

  // Store messenger before async operations to avoid BuildContext issues
  final scaffoldMessenger = ScaffoldMessenger.of(context);

  // Generate QR code as image
  final qrValidationResult = QrValidator.validate(
    data: qrData,
    version: QrVersions.auto,
    errorCorrectionLevel: QrErrorCorrectLevel.Q,
  );
  if (qrValidationResult.status != QrValidationStatus.valid) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Failed to generate QR code for PDF.')),
    );
    return;
  }

  final painter = QrPainter.withQr(
    qr: qrValidationResult.qrCode!,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Color(0xFF000000),
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Color(0xFF000000),
    ),
    gapless: true,
  );
  final image = await painter.toImageData(400);
  if (image == null) {
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('Failed to render QR code image.')),
    );
    return;
  }

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'Parking Spot QR',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Container(
                width: 320,
                height: 320,
                alignment: pw.Alignment.center,
                child: pw.Image(
                  pw.MemoryImage(image.buffer.asUint8List()),
                  width: 300,
                  height: 300,
                ),
              ),
              pw.SizedBox(height: 32),
              pw.Text('Parking Spot QR Code',
                  style: pw.TextStyle(
                      fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Text('Address: $address', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 8),
              pw.Text('Scan this QR code to verify parking spot',
                  style: pw.TextStyle(fontSize: 12)),
            ],
          ),
        );
      },
    ),
  );
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    name:
        'parking_spot_qr_${address.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}.pdf',
  );
}
