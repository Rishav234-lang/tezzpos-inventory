import 'dart:io';

import 'package:dio/dio.dart' as dio_pkg;
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'invoice_pdf_browser_stub.dart'
    if (dart.library.html) 'invoice_pdf_browser_web.dart' as browser_pdf;

enum InvoiceShareResult {
  shared,
  downloadedFallback,
}

class InvoicePdfHelper {
  static Future<Uint8List> fetchPdfBytes({
    required dio_pkg.Dio dio,
    required String endpoint,
  }) async {
    final response = await dio.get(
      endpoint,
      options: dio_pkg.Options(responseType: dio_pkg.ResponseType.bytes),
    );

    final data = response.data;
    if (data is Uint8List) return data;
    if (data is List<int>) return Uint8List.fromList(data);

    throw Exception('Invalid PDF response received');
  }

  static Future<void> downloadPdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (kIsWeb) {
      await browser_pdf.downloadPdfBytes(bytes, filename);
      return;
    }

    final file = await _saveTempFile(bytes, filename);
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  static Future<void> previewPdf({
    required Uint8List bytes,
    required String filename,
  }) async {
    if (kIsWeb) {
      await browser_pdf.openPdfBytes(bytes, filename);
      return;
    }

    final file = await _saveTempFile(bytes, filename);
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception(result.message);
    }
  }

  static Future<InvoiceShareResult> sharePdf({
    required Uint8List bytes,
    required String filename,
    String? subject,
    String? text,
  }) async {
    if (kIsWeb) {
      try {
        await Share.shareXFiles(
          [
            XFile.fromData(
              bytes,
              mimeType: 'application/pdf',
              name: filename,
            ),
          ],
          subject: subject,
          text: text,
        );
        return InvoiceShareResult.shared;
      } catch (_) {
        await browser_pdf.downloadPdfBytes(bytes, filename);
        return InvoiceShareResult.downloadedFallback;
      }
    }

    final file = await _saveTempFile(bytes, filename);
    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      text: text,
    );
    return InvoiceShareResult.shared;
  }

  static Future<File> _saveTempFile(Uint8List bytes, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
