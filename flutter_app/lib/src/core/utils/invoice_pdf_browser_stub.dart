import 'dart:typed_data';

Future<void> downloadPdfBytes(Uint8List bytes, String filename) {
  throw UnsupportedError('Browser download is only available on web');
}

Future<void> openPdfBytes(Uint8List bytes, String filename) {
  throw UnsupportedError('Browser preview is only available on web');
}
