// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

String _createObjectUrl(Uint8List bytes) {
  final blob = html.Blob([bytes], 'application/pdf');
  return html.Url.createObjectUrlFromBlob(blob);
}

Future<void> downloadPdfBytes(Uint8List bytes, String filename) async {
  final objectUrl = _createObjectUrl(bytes);
  final anchor = html.AnchorElement(href: objectUrl)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.append(anchor);
  anchor.click();
  anchor.remove();
  html.Url.revokeObjectUrl(objectUrl);
}

Future<void> openPdfBytes(Uint8List bytes, String filename) async {
  final objectUrl = _createObjectUrl(bytes);
  html.window.open(objectUrl, '_blank');
  unawaited(
    Future<void>.delayed(
      const Duration(minutes: 5),
      () => html.Url.revokeObjectUrl(objectUrl),
    ),
  );
}
