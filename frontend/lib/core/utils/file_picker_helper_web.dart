import 'dart:async';
import 'dart:html' as html;

class PickedFileData {
  final String name;
  final int size;
  final String? base64Data;
  final String? mimeType;

  PickedFileData({
    required this.name,
    required this.size,
    this.base64Data,
    this.mimeType,
  });
}

Future<PickedFileData?> pickMedicalDocImage() {
  final completer = Completer<PickedFileData?>();
  final uploadInput = html.FileUploadInputElement()..accept = 'image/*,.pdf';
  uploadInput.click();

  uploadInput.onChange.listen((e) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }
    final file = files[0];
    final reader = html.FileReader();

    reader.onLoadEnd.listen((e) {
      final result = reader.result as String?;
      completer.complete(PickedFileData(
        name: file.name,
        size: file.size,
        base64Data: result,
        mimeType: file.type,
      ));
    });

    reader.onError.listen((e) {
      completer.complete(null);
    });

    reader.readAsDataUrl(file);
  });

  return completer.future;
}
