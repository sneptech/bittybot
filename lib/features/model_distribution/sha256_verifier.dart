import 'dart:io';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

import 'model_constants.dart';

/// Verifies the integrity of the downloaded model file by computing its SHA-256
/// hash and comparing it against [ModelConstants.sha256Hash].
///
/// The computation runs inside a [compute] isolate so it never blocks the UI
/// thread. The 2.14 GB file is processed in 64 KB chunks so the peak memory
/// footprint stays well under 1 MB regardless of file size.
///
/// Returns `true` if the file exists and its SHA-256 matches the known-good
/// hash. Returns `false` if the file is missing or the hash does not match.
Future<bool> verifyModelFile(String filePath) {
  return compute(_computeSha256Match, filePath);
}

/// Synchronous SHA-256 computation intended to run inside a [compute] isolate.
///
/// Uses [RandomAccessFile] with [RandomAccessFile.readSync] to avoid async
/// overhead inside the isolate. The file is never fully loaded into memory —
/// only one 64 KB chunk is held at a time.
///
/// IMPORTANT: Do NOT use [File.readAsBytes] or [File.readAsBytesSync] for this
/// purpose — the 2.14 GB file would immediately OOM on mobile devices.
bool _computeSha256Match(String filePath) {
  final file = File(filePath);
  if (!file.existsSync()) return false;

  final output = AccumulatorSink<Digest>();
  final input = sha256.startChunkedConversion(output);

  final raf = file.openSync(mode: FileMode.read);
  const chunkSize = 65536; // 64 KB per read
  try {
    while (true) {
      final chunk = raf.readSync(chunkSize);
      if (chunk.isEmpty) break;
      input.add(chunk);
    }
  } finally {
    raf.closeSync();
  }

  input.close();
  final digest = output.events.single;
  return digest.toString() == ModelConstants.sha256Hash;
}
