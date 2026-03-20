import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// Full-screen QR code scanner that returns the scanned deep-link or
/// session ID as a [String] via [Navigator.pop].
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  bool _hasPopped = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasPopped) return;
    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue;
      if (raw == null || raw.isEmpty) continue;

      // Accept beerer:// links or any alphanumeric string
      final sessionId = _extractSessionId(raw);
      if (sessionId != null) {
        _hasPopped = true;
        Navigator.of(context).pop(sessionId);
        return;
      }
    }
  }

  /// Extracts a session ID from either:
  ///   - a raw session ID string (e.g. "abc123")
  ///   - a beerer:// URI         (e.g. "beerer://join/abc123")
  ///   - an https web link       (e.g. "https://beerer.app/join/abc123")
  String? _extractSessionId(String input) {
    if (input.isEmpty) return null;

    final uri = Uri.tryParse(input);
    if (uri != null) {
      // beerer://join/<id>
      if (uri.scheme == 'beerer' && uri.host == 'join') {
        final id =
            uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        return (id != null && id.isNotEmpty) ? id : null;
      }
      // https://…/join/<id>
      if ((uri.scheme == 'https' || uri.scheme == 'http') &&
          uri.pathSegments.length >= 2 &&
          uri.pathSegments[uri.pathSegments.length - 2] == 'join') {
        final id = uri.pathSegments.last;
        return id.isNotEmpty ? id : null;
      }
    }

    // Fallback: raw session ID (no whitespace/slashes)
    final clean = input.replaceAll(RegExp(r'\s'), '');
    if (clean.isNotEmpty && !clean.contains('/')) return clean;

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR code'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.switch_camera),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Overlay with instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'Point at a Beerer QR code',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
