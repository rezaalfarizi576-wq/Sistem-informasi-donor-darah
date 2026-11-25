import 'dart:io';
import 'dart:typed_data';

Future<bool> saveFileImpl(Uint8List bytes, String filename) async {
  try {
    final dir = Directory.systemTemp;
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> printHtmlImpl({
  required String reqId,
  required String patientName,
  required String bloodType,
  required String bags,
  required String hospital,
  required String requester,
  required String status,
  required String qrData,
}) async {}
