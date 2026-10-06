import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/file_picker_helper.dart';
import '../../../data/repositories/blood_request_repository.dart';

class RequestFormScreen extends StatefulWidget {
  const RequestFormScreen({super.key});

  @override
  State<RequestFormScreen> createState() => _RequestFormScreenState();
}

class _RequestFormScreenState extends State<RequestFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _bagsNeededController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _selectedBloodType = 'O';
  String _selectedRhesus = '+';
  String _selectedUrgency = 'tinggi';
  bool _isLoading = false;
  PickedFileData? _suratDokterFile;

  // Lokasi faskes terpilih (preset RSUD Lamongan sebagai default)
  String _selectedHospital = 'RSUD Dr. Soegiri Lamongan';
  final double _selectedLat = -7.1268;
  final double _selectedLng = 112.4182;

  final _requestRepo = BloodRequestRepository();

  // Daftar rumah sakit (bisa diperluas sesuai data faskes)
  final List<Map<String, dynamic>> _hospitals = [
    {'name': 'RSUD Dr. Soegiri Lamongan', 'lat': -7.1268, 'lng': 112.4182},
    {'name': 'RS Islam Lamongan', 'lat': -7.1254, 'lng': 112.4115},
    {'name': 'Puskesmas Lamongan Kota', 'lat': -7.1290, 'lng': 112.4200},
    {'name': 'RS Muhammadiyah Babat', 'lat': -7.0912, 'lng': 112.2054},
    {'name': 'RSU AR Bunda Lamongan', 'lat': -7.1244, 'lng': 112.4170},
  ];

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
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_suratDokterFile == null) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Surat Dokter Belum Terlampir',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          content: Text(
            'Apakah Anda ingin mengirim permohonan tanpa surat dokter?\n\n'
            'Verifikasi admin PMI mungkin memerlukan konfirmasi tambahan.',
            style: GoogleFonts.plusJakartaSans(fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Batal',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF64748B),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Tetap Kirim',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
      if (proceed != true) return;
    }

    setState(() => _isLoading = true);
    try {
      await _requestRepo.createRequest({
        'patient_name': _patientNameController.text.trim(),
        'hospital_name': _selectedHospital,
        'latitude_faskes': _selectedLat,
        'longitude_faskes': _selectedLng,
        'blood_type': _selectedBloodType,
        'rhesus': _selectedRhesus,
        'bags_needed': int.tryParse(_bagsNeededController.text) ?? 1,
        'urgency_level': _selectedUrgency,
        'notes': _notesController.text.trim(),
        'surat_dokter': _suratDokterFile?.base64Data ?? _suratDokterFile?.name,
        'radius_km': 10.0,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  'Permohonan berhasil dikirim! Menunggu verifikasi PMI.',
                  style: GoogleFonts.plusJakartaSans(),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
    _bagsNeededController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Warna urgency ─────────────────────────────────
  Color _urgencyColor(String v) {
    switch (v) {
      case 'kritis':
        return const Color(0xFFDC2626);
      case 'tinggi':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF2563EB);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PERMINTAAN DARAH',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'Form Kebutuhan Darurat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        toolbarHeight: 68,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // ── STEPPER INDIKATOR ──
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: _buildStepIndicator(),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // ── BODY SCROLL AREA ──
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── NAMA PASIEN ──
                    _buildLabel('NAMA PASIEN', required: true),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      controller: _patientNameController,
                      hint: 'Dewi Rahayu',
                      validator: (v) =>
                          Validators.required(v, fieldName: 'Nama Pasien'),
                    ),

                    const SizedBox(height: 22),

                    // ── RUMAH SAKIT ──
                    _buildLabel('RUMAH SAKIT', required: true),
                    const SizedBox(height: 8),
                    _buildHospitalSelector(),

                    const SizedBox(height: 22),

                    // ── GOLONGAN DARAH / RHESUS ──
                    _buildLabel('GOLONGAN DARAH / RHESUS', required: true),
                    const SizedBox(height: 10),
                    _buildBloodTypeChips(),
                    const SizedBox(height: 10),
                    _buildRhesusChips(),

                    const SizedBox(height: 22),

                    // ── TINGKAT URGENSI ──
                    _buildLabel('TINGKAT URGENSI', required: true),
                    const SizedBox(height: 10),
                    _buildUrgencyChips(),

                    const SizedBox(height: 22),

                    // ── JUMLAH KANTONG ──
                    _buildLabel('JUMLAH KANTONG DARAH', required: true),
                    const SizedBox(height: 8),
                    _buildBagsSelector(),

                    const SizedBox(height: 22),

                    // ── SURAT KETERANGAN DOKTER ──
                    _buildLabel('SURAT KETERANGAN DOKTER', required: true),
                    const SizedBox(height: 10),
                    _buildSuratDokterCard(),

                    const SizedBox(height: 22),

                    // ── CATATAN TAMBAHAN ──
                    _buildLabel('CATATAN TAMBAHAN', required: false),
                    const SizedBox(height: 8),
                    _buildTextInput(
                      controller: _notesController,
                      hint: 'Kontak keluarga, ruangan rawat inap, dll...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 24),

                    // ── INFO BANNER: MENUNGGU VERIFIKASI PMI ──
                    _buildVerifikasiInfoBanner(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // ── BOTTOM SUBMIT BUTTON ──
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitRequest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFFFCA5A5),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.send_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Kirim Permohonan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // WIDGETS HELPER
  // ─────────────────────────────────────────────────────────────

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _buildStep(number: 1, label: 'Data Pasien', isActive: true, isDone: false),
        _buildStepDivider(active: false),
        _buildStep(number: 2, label: 'Verifikasi', isActive: false, isDone: false),
        _buildStepDivider(active: false),
        _buildStep(number: 3, label: 'Konfirmasi', isActive: false, isDone: false),
      ],
    );
  }

  Widget _buildStep({
    required int number,
    required String label,
    required bool isActive,
    required bool isDone,
  }) {
    const Color activeColor = Color(0xFFDC2626);
    const Color inactiveColor = Color(0xFFCBD5E1);

    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
              : Text(
                  '$number',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? activeColor : inactiveColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool active}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18, left: 6, right: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {required bool required}) {
    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
            letterSpacing: 0.6,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          Text(
            '*',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFDC2626),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF94A3B8),
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
      ),
    );
  }

  Widget _buildHospitalSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedHospital,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showHospitalPicker,
            child: Text(
              'Ganti',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2563EB),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showHospitalPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Pilih Rumah Sakit / Faskes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pilih lokasi fasilitas kesehatan terdekat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            ...(_hospitals.map(
              (h) => InkWell(
                onTap: () {
                  setState(() => _selectedHospital = h['name'] as String);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _selectedHospital == h['name']
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _selectedHospital == h['name']
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFF1F5F9),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_hospital_rounded,
                        color: _selectedHospital == h['name']
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF94A3B8),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          h['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _selectedHospital == h['name']
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (_selectedHospital == h['name'])
                        const Icon(
                          Icons.check_rounded,
                          color: Color(0xFFDC2626),
                          size: 18,
                        ),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodTypeChips() {
    final types = ['A', 'B', 'AB', 'O'];
    return Row(
      children: types
          .map(
            (t) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _buildSelectChip(
                label: t,
                isSelected: _selectedBloodType == t,
                onTap: () => setState(() => _selectedBloodType = t),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRhesusChips() {
    return Row(
      children: [
        _buildSelectChip(
          label: 'Rhesus +',
          isSelected: _selectedRhesus == '+',
          onTap: () => setState(() => _selectedRhesus = '+'),
          fullWidth: false,
          minWidth: 120,
        ),
        const SizedBox(width: 10),
        _buildSelectChip(
          label: 'Rhesus -',
          isSelected: _selectedRhesus == '-',
          onTap: () => setState(() => _selectedRhesus = '-'),
          fullWidth: false,
          minWidth: 120,
        ),
      ],
    );
  }

  Widget _buildSelectChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool fullWidth = false,
    double? minWidth,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        constraints: minWidth != null
            ? BoxConstraints(minWidth: minWidth)
            : null,
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFDC2626)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? const Color(0xFFDC2626)
                  : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUrgencyChips() {
    final urgencies = [
      {'value': 'sedang', 'label': 'Normal'},
      {'value': 'tinggi', 'label': 'Mendesak'},
      {'value': 'kritis', 'label': 'Kritis'},
    ];

    return Row(
      children: urgencies.map((u) {
        final val = u['value']!;
        final label = u['label']!;
        final isSelected = _selectedUrgency == val;
        final color = _urgencyColor(val);

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedUrgency = val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.1)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE2E8F0),
                    width: isSelected ? 2 : 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      val == 'kritis'
                          ? Icons.warning_rounded
                          : val == 'tinggi'
                              ? Icons.priority_high_rounded
                              : Icons.info_outline_rounded,
                      color: isSelected ? color : const Color(0xFF94A3B8),
                      size: 18,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBagsSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Row(
        children: [
          // Tombol kurang
          _buildBagButton(
            icon: Icons.remove_rounded,
            onTap: () {
              final current = int.tryParse(_bagsNeededController.text) ?? 1;
              if (current > 1) {
                setState(() {
                  _bagsNeededController.text = '${current - 1}';
                });
              }
            },
          ),
          // Angka
          Expanded(
            child: Center(
              child: TextFormField(
                controller: _bagsNeededController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  suffix: Text(
                    ' Kantong',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Tombol tambah
          _buildBagButton(
            icon: Icons.add_rounded,
            onTap: () {
              final current = int.tryParse(_bagsNeededController.text) ?? 1;
              if (current < 10) {
                setState(() {
                  _bagsNeededController.text = '${current + 1}';
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBagButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF475569), size: 20),
      ),
    );
  }

  Widget _buildSuratDokterCard() {
    if (_suratDokterFile == null) {
      return InkWell(
        onTap: _pickSuratDokter,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE2E8F0),
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF64748B),
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Unggah Surat Dokter',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'PDF / JPG • maks 5MB',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Pilih File',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // File sudah dipilih
    final fileSizeKb = (_suratDokterFile!.size / 1024).toStringAsFixed(1);
    final isImage = (_suratDokterFile!.mimeType?.startsWith('image') ?? true);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
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
                Text(
                  _suratDokterFile!.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF14532D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$fileSizeKb KB • Siap dikirim',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Color(0xFFDC2626)),
            onPressed: () => setState(() => _suratDokterFile = null),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifikasiInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: Color(0xFFD97706),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menunggu Verifikasi PMI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF92400E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Admin PMI akan memverifikasi permohonan Anda.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFFB45309),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
