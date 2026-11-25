import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_io.dart';

class FileSaver {
  static Future<bool> saveImageFile(Uint8List bytes, String filename) =>
      saveFileImpl(bytes, filename);

  static Future<void> printHtmlDocument({
    required String reqId,
    required String patientName,
    required String bloodType,
    required String bags,
    required String hospital,
    required String requester,
    required String status,
    required String qrData,
  }) =>
      printHtmlImpl(
        reqId: reqId,
        patientName: patientName,
        bloodType: bloodType,
        bags: bags,
        hospital: hospital,
        requester: requester,
        status: status,
        qrData: qrData,
      );
}
