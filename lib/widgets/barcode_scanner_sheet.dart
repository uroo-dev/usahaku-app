import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:usahaku/theme/app_theme.dart';
import 'package:usahaku/utils/camera_support.dart';

/// Bottom sheet scanner barcode menggunakan kamera.
/// Kembalikan [String] barcode ketika berhasil, atau null jika dibatalkan.
class BarcodeScannerSheet extends StatefulWidget {
  const BarcodeScannerSheet({super.key});

  static Future<String?> show(BuildContext context) {
    if (!CameraSupport.isScannerSupported) {
      return _showUnsupportedMessage(context);
    }
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BarcodeScannerSheet(),
    );
  }

  /// Tampilkan pesan ramah saat platform tidak mendukung scanner.
  static Future<String?> _showUnsupportedMessage(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.no_photography_outlined, color: AppColor.onSurfaceVariant, size: 36),
        title: const Text('Kamera tidak tersedia'),
        content: const Text(
          'Fitur scan barcode hanya bisa digunakan di perangkat Android atau iOS. '
          'Silakan buka aplikasi ini di HP.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('Mengerti')),
        ],
      ),
    );
  }

  @override
  State<BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<BarcodeScannerSheet> {
  late final MobileScannerController _ctrl;
  bool _detected = false;
  bool _torchOn = false;

  @override
  void initState() {
    super.initState();
    _ctrl = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_detected) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;
    _detected = true;
    Navigator.pop(context, barcode!.rawValue);
  }

  Future<void> _toggleTorch() async {
    // Hanya lakukan jika controller sudah initialized
    if (!_ctrl.value.isInitialized) return;
    try {
      await _ctrl.toggleTorch();
      if (mounted) setState(() => _torchOn = !_torchOn);
    } catch (_) {
      // Flash tidak tersedia di perangkat ini
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header — reactive terhadap state controller
          ValueListenableBuilder<MobileScannerState>(
            valueListenable: _ctrl,
            builder: (context, state, _) {
              final isReady = state.isInitialized && state.error == null;
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                child: Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white, size: 22),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Scan Barcode',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // Flash — hanya aktif setelah kamera ready
                    IconButton(
                      icon: Icon(
                        _torchOn ? Icons.flashlight_on : Icons.flashlight_off,
                        color: isReady
                            ? (_torchOn ? Colors.amber : Colors.white54)
                            : Colors.white24,
                      ),
                      onPressed: isReady ? _toggleTorch : null,
                      tooltip: 'Flash',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              );
            },
          ),
          // Kamera + overlay
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: _ctrl,
                    onDetect: _onDetect,
                    // Tampilkan placeholder hitam saat loading
                    placeholderBuilder: (ctx, _) => const ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white38,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    // Tampilkan pesan error jika kamera gagal
                    errorBuilder: (ctx, error, _) => ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              error.errorCode.name == 'permissionDenied'
                                  ? 'Izin kamera ditolak.\nBuka Pengaturan dan aktifkan izin kamera.'
                                  : 'Kamera tidak tersedia.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Viewfinder overlay
                  CustomPaint(
                    painter: _ViewfinderPainter(),
                    child: const SizedBox.expand(),
                  ),
                ],
              ),
            ),
          ),
          // Hint
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.white54),
                SizedBox(width: 6),
                Text(
                  'Arahkan kamera ke barcode produk',
                  style: TextStyle(fontSize: 13, color: Colors.white54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Painter viewfinder — overlay gelap + sudut berwarna di tengah.
class _ViewfinderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dim = size.width * 0.65;
    final left = (size.width - dim) / 2;
    final top = (size.height - dim) / 2;
    final rect = Rect.fromLTWH(left, top, dim, dim);

    final overlay = Paint()..color = Colors.black.withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), overlay);
    canvas.drawRect(Rect.fromLTWH(0, top + dim, size.width, size.height - top - dim), overlay);
    canvas.drawRect(Rect.fromLTWH(0, top, left, dim), overlay);
    canvas.drawRect(Rect.fromLTWH(left + dim, top, size.width - left - dim, dim), overlay);

    const cornerLen = 24.0;
    final corner = Paint()
      ..color = AppColor.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(cornerLen, 0), corner);
    canvas.drawLine(rect.topLeft, rect.topLeft + const Offset(0, cornerLen), corner);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(-cornerLen, 0), corner);
    canvas.drawLine(rect.topRight, rect.topRight + const Offset(0, cornerLen), corner);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(cornerLen, 0), corner);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + const Offset(0, -cornerLen), corner);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(-cornerLen, 0), corner);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + const Offset(0, -cornerLen), corner);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
