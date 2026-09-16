import 'package:flutter/material.dart';
import '../../../core/utils/validators.dart';
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

  final _requestRepo = BloodRequestRepository();

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

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
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permohonan darah berhasil dikirim!'),
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
                const SizedBox(height: 24),
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
}
