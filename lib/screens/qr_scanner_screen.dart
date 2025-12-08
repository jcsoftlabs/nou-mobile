import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  final ImagePicker _imagePicker = ImagePicker();
  final MobileScannerController _mobileScannerController = MobileScannerController();
  bool hasScanned = false;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      controller!.pauseCamera();
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    _mobileScannerController.dispose();
    super.dispose();
  }

  Future<void> _pickImageAndScan() async {
    try {
      // Sélectionner une image depuis la galerie
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null) return;

      // Analyser l'image pour détecter le QR code
      final BarcodeCapture? barcodeCapture = await _mobileScannerController.analyzeImage(image.path);

      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final String? code = barcodeCapture.barcodes.first.rawValue;
        if (code != null && !hasScanned) {
          hasScanned = true;
          controller?.pauseCamera();
          if (mounted) {
            Navigator.of(context).pop(code);
          }
        }
      } else {
        // Aucun QR code détecté
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucun QR code détecté dans l\'image'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du scan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!hasScanned && scanData.code != null) {
        hasScanned = true;
        controller.pauseCamera();
        Navigator.of(context).pop(scanData.code);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner le QR Code'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library),
            tooltip: 'Choisir depuis la galerie',
            onPressed: _pickImageAndScan,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Positionnez le QR code dans le cadre',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickImageAndScan,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choisir depuis la galerie'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
