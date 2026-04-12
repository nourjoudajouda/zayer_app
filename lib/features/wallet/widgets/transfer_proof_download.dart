import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Downloads transfer proof to app documents, then opens it with the system viewer.
///
/// Storage: `ApplicationDocumentsDirectory/transfer_proofs/`
/// Supported: PDF, JPG, JPEG, PNG, WEBP, GIF (by URL extension or Content-Type / magic bytes).
Future<void> downloadAndOpenTransferProof(
  BuildContext context,
  String url, {
  String? withdrawalId,
}) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    throw StateError('Empty URL');
  }

  final path = await downloadTransferProofFile(trimmed, withdrawalId: withdrawalId);

  if (!context.mounted) return;

  final result = await OpenFilex.open(path);
  if (!context.mounted) return;

  final opened = result.type == ResultType.done;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        opened
            ? 'Transfer proof downloaded and opened'
            : 'Transfer proof saved. ${result.message.isNotEmpty ? result.message : "Open it from your files app."}',
      ),
    ),
  );
}

/// Returns absolute path of saved file.
Future<String> downloadTransferProofFile(
  String url, {
  String? withdrawalId,
}) async {
  final uri = Uri.parse(url);
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw UnsupportedError('Only http(s) URLs are supported');
  }

  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      responseType: ResponseType.bytes,
      validateStatus: (s) => s != null && s >= 200 && s < 400,
    ),
  );

  final response = await dio.get<List<int>>(url);
  final bytes = response.data;
  if (bytes == null || bytes.isEmpty) {
    throw StateError('Empty download');
  }

  final headerType =
      response.headers.value('content-type')?.toLowerCase() ?? '';
  var ext = _extensionFromUrl(url);
  if (ext.isEmpty) {
    ext = _extensionFromContentType(headerType);
  }
  if (ext.isEmpty) {
    ext = _extensionFromMagicBytes(
      bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
    );
  }
  if (ext.isEmpty) {
    ext = '.bin';
  }

  final baseDir = await getApplicationDocumentsDirectory();
  final folder = Directory(p.join(baseDir.path, 'transfer_proofs'));
  if (!await folder.exists()) {
    await folder.create(recursive: true);
  }

  final safeId = (withdrawalId ?? 'proof').replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '');
  final name =
      '${safeId}_${DateTime.now().millisecondsSinceEpoch}$ext';
  final file = File(p.join(folder.path, name));
  await file.writeAsBytes(bytes, flush: true);

  return file.path;
}

String _extensionFromUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? '';
  if (path.endsWith('.pdf')) return '.pdf';
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';
  if (path.endsWith('.png')) return '.png';
  if (path.endsWith('.webp')) return '.webp';
  if (path.endsWith('.gif')) return '.gif';
  return '';
}

String _extensionFromContentType(String ct) {
  if (ct.contains('pdf')) return '.pdf';
  if (ct.contains('jpeg')) return '.jpg';
  if (ct.contains('jpg')) return '.jpg';
  if (ct.contains('png')) return '.png';
  if (ct.contains('webp')) return '.webp';
  if (ct.contains('gif')) return '.gif';
  return '';
}

String _extensionFromMagicBytes(Uint8List b) {
  if (b.length >= 4 && b[0] == 0x25 && b[1] == 0x50 && b[2] == 0x44 && b[3] == 0x46) {
    return '.pdf';
  }
  if (b.length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) {
    return '.jpg';
  }
  if (b.length >= 8 &&
      b[0] == 0x89 &&
      b[1] == 0x50 &&
      b[2] == 0x4E &&
      b[3] == 0x47) {
    return '.png';
  }
  if (b.length >= 12 &&
      b[0] == 0x52 &&
      b[1] == 0x49 &&
      b[2] == 0x46 &&
      b[3] == 0x46) {
    // RIFF — WEBP or GIF; check further
    if (b.length > 12 &&
        b[8] == 0x57 &&
        b[9] == 0x45 &&
        b[10] == 0x42 &&
        b[11] == 0x50) {
      return '.webp';
    }
    return '.gif';
  }
  return '';
}
