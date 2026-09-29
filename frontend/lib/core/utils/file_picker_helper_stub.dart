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

Future<PickedFileData?> pickMedicalDocImage() async {
  return PickedFileData(
    name: 'surat_keterangan_dokter.jpg',
    size: 154200,
    base64Data: null,
    mimeType: 'image/jpeg',
  );
}
