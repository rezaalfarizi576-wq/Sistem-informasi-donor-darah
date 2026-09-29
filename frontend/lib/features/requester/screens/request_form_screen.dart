import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/file_picker_helper.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/custom_text_field.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _bagsNeededController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _selectedBloodType = 'A';
  String _selectedRhesus = '+';
  String _selectedUrgency = 'normal';
  bool _isLoading = false;
  PickedFileData? _suratDokterFile;

  final _requestRepo = BloodRequestRepository();

  Future<void> _pickSuratDokter() async {
    try {
      final file = await pickMedicalDocImage();
      if (file != null) {
        setState(() {
          _suratDokterFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_suratDokterFile == null) {
      final proceedWithoutDoc = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Surat Dokter Belum Terlampir'),
          content: const Text(
            'Apakah Anda yakin ingin mengirim permohonan tanpa melampirkan foto surat dokter?\n\n'
            'Verifikasi oleh admin PMI mungkin memerlukan konfirmasi tambahan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal & Lampirkan'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              child: const Text('Tetap Kirim'),
            ),
          ],
        ),
      );

      if (proceedWithoutDoc != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await _requestRepo.createRequest({
        'patient_name': _patientNameController.text.trim(),
        'hospital_name': _hospitalController.text.trim(),
        'blood_type': _selectedBloodType,
        'rhesus': _selectedRhesus,
        'bags_needed': int.tryParse(_bagsNeededController.text) ?? 1,
        'urgency_level': _selectedUrgency,
        'notes': _notesController.text.trim(),
        'surat_dokter': _suratDokterFile?.base64Data ?? _suratDokterFile?.name,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permohonan darah dan surat dokter berhasil dikirim!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _hospitalController.dispose();
    _bagsNeededController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Permohonan Darah'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _patientNameController,
                  label: 'Nama Pasien',
                  hint: 'Nama lengkap pasien',
                  validator: (v) => Validators.required(v, fieldName: 'Nama Pasien'),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _hospitalController,
                  label: 'Rumah Sakit / Lokasi',
                  hint: 'Contoh: RSUD dr. Soegiri Lamongan',
                  validator: (v) => Validators.required(v, fieldName: 'Rumah Sakit'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gol. Darah', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedBloodType,
                            decoration: const InputDecoration(),
                            items: ['A', 'B', 'AB', 'O'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => setState(() => _selectedBloodType = v!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Rhesus', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedRhesus,
                            decoration: const InputDecoration(),
                            items: ['+', '-'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                            onChanged: (v) => setState(() => _selectedRhesus = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _bagsNeededController,
                        label: 'Jumlah Kantong',
                        keyboardType: TextInputType.number,
                        validator: (v) => Validators.required(v, fieldName: 'Jumlah Kantong'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Tingkat Urgensi', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedUrgency,
                            decoration: const InputDecoration(),
                            items: [
                              DropdownMenuItem(value: 'normal', child: Text('Normal')),
                              DropdownMenuItem(value: 'urgent', child: Text('Mendesak')),
                              DropdownMenuItem(value: 'critical', child: Text('Kritis')),
                            ],
                            onChanged: (v) => setState(() => _selectedUrgency = v!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _notesController,
                  label: 'Catatan Tambahan',
                  hint: 'Kontak keluarga, ruangan rawat inap, dsb.',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // ─── UPLOAD SURAT KETERANGAN DOKTER ─────────────────
                Row(
                  children: [
                    const Text(
                      'Surat Keterangan Dokter / Rujukan RS',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        'Wajib Verifikasi',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Lampirkan foto surat dokter atau formulir permintaan darah resmi dari rumah sakit untuk diverifikasi PMI.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 10),
                _buildSuratDokterUploadCard(),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Kirim Permohonan',
                  isLoading: _isLoading,
                  onPressed: _submitRequest,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuratDokterUploadCard() {
    if (_suratDokterFile == null) {
      return InkWell(
        onTap: _pickSuratDokter,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Klik untuk unggah Foto / Scan Surat Dokter',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mendukung format JPG, PNG, atau PDF (maksimal 5 MB)',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fileSizeKb = (_suratDokterFile!.size / 1024).toStringAsFixed(1);
    final isImage = _suratDokterFile!.mimeType?.startsWith('image') ?? true;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF86EFAC),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isImage ? Icons.image_rounded : Icons.description_rounded,
              color: const Color(0xFF16A34A),
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _suratDokterFile!.name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF14532D),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Terlampir',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$fileSizeKb KB • Siap dikirim bersama permohonan',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade800,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF16A34A)),
            tooltip: 'Ganti Foto',
            onPressed: _pickSuratDokter,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus',
            onPressed: () => setState(() => _suratDokterFile = null),
          ),
        ],
      ),
    );
  }
}
