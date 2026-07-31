import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Helper dukungan kamera lintas platform.
///
/// `mobile_scanner` hanya tersedia di Android, iOS, macOS, dan web.
/// `image_picker` dengan `ImageSource.camera` hanya didukung di Android/iOS.
class CameraSupport {
  CameraSupport._();

  /// Platform yang didukung plugin `mobile_scanner`.
  static bool get isScannerSupported {
    if (kIsWeb) return true;
    return Platform.isAndroid || Platform.isIOS || Platform.isMacOS;
  }

  /// Platform yang mendukung ambil foto langsung dari kamera (image_picker).
  static bool get isCameraPickerSupported {
    if (kIsWeb) return false;
    return Platform.isAndroid || Platform.isIOS;
  }
}
