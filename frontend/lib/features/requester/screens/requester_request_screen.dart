import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/file_picker_helper.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../routes/app_router.dart';

class RequesterRequestScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTracking;
  final VoidCallback? onNavigateToProfile;

  const RequesterRequestScreen({
    super.key,
    this.onNavigateToTracking,
    this.onNavigateToProfile,
  });

  @override
  State<RequesterRequestScreen> createState() => _RequesterRequestScreenState();
}

class _RequesterRequestScreenState extends State<RequesterRequestScreen> {
  final _requestRepo = BloodRequestRepository();
  BloodRequestModel? _activeRequest;
  bool _isLoading = true;
  int _selectedTabIndex = 0; // Aktif di tab 0: Permohonan
  int _permohonanViewMode = 0; // 0 = Form Permohonan Darah, 1 = Status Distribusi

  // Form Controllers & State
  final _formKey = GlobalKey<FormState>();
  final _patientNameController = TextEditingController();
  final _bagsNeededController = TextEditingController(text: '1');
  final _notesController = TextEditingController();

  String _selectedBloodType = 'O';
  String _selectedRhesus = '+';
  String _selectedUrgency = 'tinggi';
  bool _isSubmitting = false;
  PickedFileData? _suratDokterFile;

  String _selectedHospital = 'RSUD Dr. Soegiri Lamongan';
  final double _selectedLat = -7.1268;
  final double _selectedLng = 112.4182;

  final List<Map<String, dynamic>> _hospitals = [
    {'name': 'RSUD Dr. Soegiri Lamongan', 'lat': -7.1268, 'lng': 112.4182},
    {'name': 'RS Islam Lamongan', 'lat': -7.1254, 'lng': 112.4115},
    {'name': 'Puskesmas Lamongan Kota', 'lat': -7.1290, 'lng': 112.4200},
    {'name': 'RS Muhammadiyah Babat', 'lat': -7.0912, 'lng': 112.2054},
    {'name': 'RSU AR Bunda Lamongan', 'lat': -7.1244, 'lng': 112.4170},
  ];

  @override
  void initState() {
    super.initState();
    _loadRequestData();
  }

  @override
  void dispose() {
    _patientNameController.dispose();
    _bagsNeededController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRequestData() async {
    try {
      final requests = await _requestRepo.getRequests();
      if (requests.isNotEmpty) {
        final active = requests.firstWhere(
          (r) => r.status == 'diproses' || r.status == 'menunggu' || r.urgencyLevel == 'kritis',
          orElse: () => requests.first,
        );
        if (mounted) {
          setState(() {
            _activeRequest = active;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickSuratDokter() async {
    try {
      final file = await pickMedicalDocImage();
      if (file != null && mounted) {
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

    setState(() => _isSubmitting = true);
    try {
      final created = await _requestRepo.createRequest({
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
        setState(() {
          _activeRequest = created;
          _isSubmitting = false;
          _permohonanViewMode = 1; // Pindah ke tab status setelah berhasil submit
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Permohonan darah berhasil dikirim! Menunggu konfirmasi relawan & PMI.',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedTabIndex) {
      if (index == 0) {
        setState(() => _permohonanViewMode = 0);
      }
      return;
    }

    setState(() => _selectedTabIndex = index);

    if (index == 1) {
      if (widget.onNavigateToTracking != null) {
        widget.onNavigateToTracking!();
      } else {
        final reqId = _activeRequest?.id.toString() ?? '1';
        Navigator.pushReplacementNamed(
          context,
          AppRouter.requesterPantauRoute,
          arguments: reqId,
        );
      }
    } else if (index == 2) {
      if (widget.onNavigateToProfile != null) {
        widget.onNavigateToProfile!();
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.requesterProfileRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rawName = _patientNameController.text.trim();
    final patientName = _activeRequest?.patientName ?? (rawName.isNotEmpty ? rawName : 'Dewi Rahayu');
    final bloodType = _activeRequest?.bloodType ?? _selectedBloodType;
    final rhesus = _activeRequest?.rhesus ?? _selectedRhesus;
    final bagsNeeded = _activeRequest?.bagsNeeded ?? (int.tryParse(_bagsNeededController.text) ?? 2);
    final hospital = _activeRequest?.hospitalName ?? _selectedHospital;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFDC2626)),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1040),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── 1. HEADER APP BAR ───
                          _buildHeader(),
                          const SizedBox(height: 12),

                          // ─── 2. SEGMENTED SWITCHER (JIKA ADA PERMOHONAN AKTIF) ───
                          if (_activeRequest != null) ...[
                            _buildModeSwitcher(),
                            const SizedBox(height: 14),
                          ],

                          // ─── 3. KONTEN (FORMULIR PERMOHONAN ATAU STATUS TERKINI) ───
                          if (_permohonanViewMode == 0)
                            _buildFormView()
                          else
                            _buildStatusView(
                              patientName: patientName,
                              bloodType: bloodType,
                              rhesus: rhesus,
                              bagsNeeded: bagsNeeded,
                              hospital: hospital,
                            ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),

      // ─── BOTTOM NAVIGATION BAR (PERMOHONAN, PANTAU, PROFIL) ───
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─── Switcher: Form Permohonan vs Status Permohonan ───
  Widget _buildModeSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _permohonanViewMode = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _permohonanViewMode == 0 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _permohonanViewMode == 0
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      size: 16,
                      color: _permohonanViewMode == 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Form Permohonan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: _permohonanViewMode == 0 ? FontWeight.w800 : FontWeight.w600,
                        color: _permohonanViewMode == 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _permohonanViewMode = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: _permohonanViewMode == 1 ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _permohonanViewMode == 1
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pending_actions_rounded,
                      size: 16,
                      color: _permohonanViewMode == 1 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Status Terkini (${_activeRequest?.status ?? "Aktif"})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: _permohonanViewMode == 1 ? FontWeight.w800 : FontWeight.w600,
                        color: _permohonanViewMode == 1 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Tampilan Form Permohonan Darah ───
  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Singkat
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panggilan Darurat Permintaan Darah',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Sistem akan otomatis memicu radar relawan & faskes terdekat di Lamongan.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stepper Indikator
          _buildStepIndicator(),

          const SizedBox(height: 18),

          // ── NAMA PASIEN ──
          _buildLabel('NAMA LENGKAP PASIEN', required: true),
          const SizedBox(height: 8),
          _buildTextInput(
            controller: _patientNameController,
            hint: 'Contoh: Dewi Rahayu',
            validator: (v) => Validators.required(v, fieldName: 'Nama Pasien'),
          ),

          const SizedBox(height: 18),

          // ── RUMAH SAKIT ──
          _buildLabel('RUMAH SAKIT / FASILITAS KESEHATAN', required: true),
          const SizedBox(height: 8),
          _buildHospitalSelector(),

          const SizedBox(height: 18),

          // ── GOLONGAN DARAH & RHESUS ──
          _buildLabel('GOLONGAN DARAH & RHESUS', required: true),
          const SizedBox(height: 10),
          _buildBloodTypeChips(),
          const SizedBox(height: 10),
          _buildRhesusChips(),

          const SizedBox(height: 18),

          // ── TINGKAT URGENSI ──
          _buildLabel('TINGKAT URGENSI', required: true),
          const SizedBox(height: 10),
          _buildUrgencyChips(),

          const SizedBox(height: 18),

          // ── JUMLAH KANTONG ──
          _buildLabel('JUMLAH KANTONG DARAH', required: true),
          const SizedBox(height: 8),
          _buildBagsSelector(),

          const SizedBox(height: 18),

          // ── SURAT KETERANGAN DOKTER ──
          _buildLabel('SURAT KETERANGAN DOKTER / REKOMENDASI MEDIS', required: true),
          const SizedBox(height: 10),
          _buildSuratDokterCard(),

          const SizedBox(height: 18),

          // ── CATATAN TAMBAHAN ──
          _buildLabel('CATATAN TAMBAHAN (RUANG RAWAT / KONTAK)', required: false),
          const SizedBox(height: 8),
          _buildTextInput(
            controller: _notesController,
            hint: 'Ruang IGD / ICU Bed 03, kontak darurat keluarga...',
            maxLines: 3,
          ),

          const SizedBox(height: 18),

          // Banner Verifikasi Info
          _buildVerifikasiInfoBanner(),

          const SizedBox(height: 16),

          // Tombol Kirim Permohonan
          _buildSubmitButton(),
        ],
      ),
    );
  }

  // ─── Tampilan Status Permohonan Aktif ───
  Widget _buildStatusView({
    required String patientName,
    required String bloodType,
    required String rhesus,
    required int bagsNeeded,
    required String hospital,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── 2. HERO BANNER HIJAU: RESPON CEPAT TANGGAP ───
        _buildHeroResponseBanner(hospital: hospital),
        const SizedBox(height: 14),

        // ─── 3. PROGRES DISTRIBUSI DARURAT (TIMELINE) ───
        _buildDistributionTimelineCard(),
        const SizedBox(height: 14),

        // ─── 4. RINCIAN MEDIS PASIEN ───
        _buildPatientMedicalDetailsCard(
          patientName: patientName,
          bloodType: bloodType,
          rhesus: rhesus,
          bagsNeeded: bagsNeeded,
          hospital: hospital,
        ),
        const SizedBox(height: 14),

        // ─── 5. RELAWAN SIAGA TERHUBUNG (2) ───
        _buildConnectedVolunteersSection(),
        const SizedBox(height: 14),

        // ─── 6. CALLOUT PANDUAN KELUARGA / PEMOHON ───
        _buildFamilyGuideCallout(),
        const SizedBox(height: 16),

        // ─── 7. TOMBOL MERAH: PANTAU LOKASI RELAWAN ───
        _buildLiveTrackingButton(),
      ],
    );
  }

  // ─── Helper Form Widgets ───

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          _buildStep(number: 1, label: 'Data Pasien', isActive: true, isDone: false),
          _buildStepDivider(active: false),
          _buildStep(number: 2, label: 'Kebutuhan', isActive: false, isDone: false),
          _buildStepDivider(active: false),
          _buildStep(number: 3, label: 'Kirim Radar', isActive: false, isDone: false),
        ],
      ),
    );
  }

  Widget _buildStep({
    required int number,
    required String label,
    required bool isActive,
    required bool isDone,
  }) {
    const Color activeColor = Color(0xFFDC2626);

    return Column(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: isActive ? activeColor : const Color(0xFFF1F5F9),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? activeColor : const Color(0xFFCBD5E1),
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: GoogleFonts.plusJakartaSans(
              color: isActive ? Colors.white : const Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? activeColor : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider({required bool active}) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16, left: 6, right: 6),
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
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
            letterSpacing: 0.5,
          ),
        ),
        if (required) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFFDC2626),
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
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF94A3B8),
          fontSize: 13.5,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.8),
        ),
      ),
    );
  }

  Widget _buildHospitalSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_hospital_rounded,
            color: Color(0xFFDC2626),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _selectedHospital,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showHospitalPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Ganti Faskes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2563EB),
                ),
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
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              'Pilih Rumah Sakit / Faskes',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lokasi rujukan penyerahan & transfusi darah di Lamongan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 14),
            ...(_hospitals.map(
              (h) => InkWell(
                onTap: () {
                  setState(() => _selectedHospital = h['name'] as String);
                  Navigator.pop(ctx);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _selectedHospital == h['name']
                        ? const Color(0xFFFFF1F2)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedHospital == h['name']
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_hospital_rounded,
                        color: _selectedHospital == h['name'] ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          h['name'] as String,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selectedHospital == h['name'] ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      if (_selectedHospital == h['name'])
                        const Icon(Icons.check_circle_rounded, color: Color(0xFFDC2626), size: 18),
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
            (t) => Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildSelectChip(
                  label: t,
                  isSelected: _selectedBloodType == t,
                  onTap: () => setState(() => _selectedBloodType = t),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildRhesusChips() {
    return Row(
      children: [
        Expanded(
          child: _buildSelectChip(
            label: 'Rhesus Positif (+)',
            isSelected: _selectedRhesus == '+',
            onTap: () => setState(() => _selectedRhesus = '+'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildSelectChip(
            label: 'Rhesus Negatif (-)',
            isSelected: _selectedRhesus == '-',
            onTap: () => setState(() => _selectedRhesus = '-'),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF1F2) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.8 : 1.2,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF475569),
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
      {'value': 'kritis', 'label': 'Kritis (IGD)'},
    ];

    return Row(
      children: urgencies.map((u) {
        final val = u['value']!;
        final label = u['label']!;
        final isSelected = _selectedUrgency == val;
        final color = val == 'kritis'
            ? const Color(0xFFDC2626)
            : (val == 'tinggi' ? const Color(0xFFEA580C) : const Color(0xFF2563EB));

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedUrgency = val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.1) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.8 : 1.2,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      val == 'kritis'
                          ? Icons.warning_rounded
                          : (val == 'tinggi' ? Icons.priority_high_rounded : Icons.info_outline_rounded),
                      color: isSelected ? color : const Color(0xFF94A3B8),
                      size: 16,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? color : const Color(0xFF64748B),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
      ),
      child: Row(
        children: [
          _buildBagButton(
            icon: Icons.remove_rounded,
            onTap: () {
              final current = int.tryParse(_bagsNeededController.text) ?? 1;
              if (current > 1) {
                setState(() => _bagsNeededController.text = '${current - 1}');
              }
            },
          ),
          Expanded(
            child: Center(
              child: TextFormField(
                controller: _bagsNeededController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  suffix: Text(
                    ' Kantong',
                    style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5),
                  ),
                ),
              ),
            ),
          ),
          _buildBagButton(
            icon: Icons.add_rounded,
            onTap: () {
              final current = int.tryParse(_bagsNeededController.text) ?? 1;
              if (current < 10) {
                setState(() => _bagsNeededController.text = '${current + 1}');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBagButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF475569), size: 18),
      ),
    );
  }

  Widget _buildSuratDokterCard() {
    if (_suratDokterFile == null) {
      return InkWell(
        onTap: _pickSuratDokter,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.description_outlined, color: Color(0xFF64748B), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unggah Surat Keterangan / Resep Darah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Format JPG, PNG atau PDF (maks 5MB)',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Pilih File',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final fileSizeKb = (_suratDokterFile!.size / 1024).toStringAsFixed(1);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _suratDokterFile!.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF14532D),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$fileSizeKb KB • Siap dikirim',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF16A34A)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _suratDokterFile = null),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B), size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifikasiInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Permohonan akan langsung diteruskan ke sistem triase PMI & dokter faskes untuk validasi cepat.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF1E3A8A),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFDC2626),
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFFCA5A5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Kirim Permohonan Darah Darurat',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─── 1. Header App Bar ───
  Widget _buildHeader() {
    return Row(
      children: [
        // Badge Logo PMI Kotak Merah
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'PMI LAMONGAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFDC2626),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DARURAT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _permohonanViewMode == 0 ? 'Formulir Permohonan Darah' : 'Status Distribusi Darurat',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Tombol Switch Mode Cepat
        if (_activeRequest != null)
          IconButton(
            tooltip: _permohonanViewMode == 0 ? 'Lihat Status Terkini' : 'Buka Form Permohonan',
            onPressed: () {
              setState(() {
                _permohonanViewMode = _permohonanViewMode == 0 ? 1 : 0;
              });
            },
            icon: Icon(
              _permohonanViewMode == 0 ? Icons.analytics_outlined : Icons.edit_note_rounded,
              color: const Color(0xFFDC2626),
              size: 22,
            ),
          ),
        const SizedBox(width: 4),
        // Tombol Avatar Merah
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, AppRouter.requesterProfileRoute);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF991B1B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ─── 2. Hero Banner: Respon Cepat Tanggap / Memindai ───
  Widget _buildHeroResponseBanner({required String hospital}) {
    final hasDonor = _activeRequest?.hasAcceptedDonor == true;

    if (!hasDonor) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFDE68A)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB45309),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFDE68A),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'MEMINDAI RELAWAN DI SEKITAR',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Ref: PMI/LMG-${_activeRequest?.id ?? "9921"}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Permohonan Disiarkan • Menunggu Konfirmasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF78350F),
                height: 1.25,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Permintaan sedang disiarkan ke relawan donor siaga terdekat di Lamongan. Belum ada pendonor yang mengonfirmasi.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF92400E),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.radar_rounded, size: 18, color: Color(0xFFB45309)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Status: Menunggu Respon Relawan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF78350F),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB45309),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'MENUNGGU',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4ADE80).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris: RESPON CEPAT TANGGAP | Ref: PMI/LMG-9921
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'RESPON CEPAT TANGGAP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Ref: PMI/LMG-9921',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF064E3B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Judul Utama
          Text(
            'Permohonan Diterima & Relawan Ditemukan!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF064E3B),
              height: 1.25,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_activeRequest?.acceptedDonorsCount ?? 0} relawan terverifikasi telah mengonfirmasi dan sedang bergerak menuju $hospital.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF065F46),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Card Mini Dalam: Status Relawan Siaga Menuju RS [AKTIF]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.two_wheeler_rounded, size: 18, color: Color(0xFF065F46)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Status: Relawan Siaga Menuju RS',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF064E3B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF064E3B),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'AKTIF',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Card: Progres Distribusi Darurat (Timeline Tracker) ───
  Widget _buildDistributionTimelineCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Judul & Badge Estimasi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.show_chart_rounded, size: 16, color: Color(0xFF2563EB)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Progres Distribusi\nDarurat',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      height: 1.15,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'EST. 12 MENIT',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stepper Items
          _buildTimelineStep(
            isDone: true,
            title: 'Formulir Diajukan',
            time: '10:15 WIB',
            description: 'Data pasien & resep darah tercatat di sistem PMI Lamongan',
            showLine: true,
          ),
          _buildTimelineStep(
            isDone: true,
            title: 'Verifikasi Dokter & Admin PMI',
            time: '10:20 WIB',
            description: 'Tervalidasi dr. Andri Kusuma, Sp.PD (BDRS Soegiri)',
            showLine: true,
          ),
          _buildTimelineStep(
            isDone: true,
            title: 'Radar Dispatch Relawan',
            time: '10:25 WIB',
            description: '2 relawan cocok langsung menyetujui panggilan darurat',
            showLine: true,
          ),
          _buildTimelineStep(
            isDone: false,
            isActive: true,
            title: 'Perjalanan Relawan',
            time: 'Sedang Berlangsung',
            description: 'Jarak terdekat 1.8 km — Estimasi tiba di lobi BDRS: 8-12 menit',
            showLine: true,
          ),
          _buildTimelineStep(
            isDone: false,
            isActive: false,
            title: 'Pengambilan Sampel & Transfusi',
            time: 'Menunggu',
            description: 'Pemeriksaan crossmatch akhir di BDRS sebelum injeksi',
            showLine: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep({
    required bool isDone,
    bool isActive = false,
    required String title,
    required String time,
    required String description,
    required bool showLine,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indikator Ikon Bulat + Garis Vertikal
        Column(
          children: [
            if (isDone)
              Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 12, color: Colors.white),
              )
            else if (isActive)
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFCBD5E1), width: 2),
                ),
              ),
            if (showLine)
              Container(
                width: 2,
                height: 38,
                color: isDone ? const Color(0xFF16A34A) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),

        // Konten Teks
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isActive ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                        color: isActive ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: const Color(0xFF64748B),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── 4. Card: Rincian Medis Pasien ───
  Widget _buildPatientMedicalDetailsCard({
    required String patientName,
    required String bloodType,
    required String rhesus,
    required int bagsNeeded,
    required String hospital,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Rincian Medis Pasien
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Color(0xFFDC2626), size: 15),
              ),
              const SizedBox(width: 8),
              Text(
                'Rincian Medis Pasien',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Nama Pasien & Kebutuhan Darah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nama Pasien',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    patientName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'RM-2025-06491',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Kebutuhan Darah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '$bloodType$rhesus',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '$bagsNeeded Kantong',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'PRC (Packed Red Cells)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),

          // RSUD Soegiri Lamongan
          Row(
            children: [
              const Icon(Icons.local_hospital_outlined, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospital,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Gedung Teratai Lt. 2 / BDRS (Bank Darah RS)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dokter DPJP
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'DPJP: dr. Andri Kusuma, Sp.PD',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. Relawan Siaga Terhubung ───
  Widget _buildConnectedVolunteersSection() {
    final hasDonor = _activeRequest?.hasAcceptedDonor == true;

    if (!hasDonor) {
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: const Center(
                    child: Icon(Icons.radar_rounded, color: Color(0xFFD97706), size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Relawan Siaga Terhubung (0)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Belum ada relawan yang mengonfirmasi',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Siaga',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFB45309),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Daftar relawan beserta waktu tempuh akan muncul di sini setelah relawan menyetujui permohonan darah.',
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.group_rounded, size: 16, color: Color(0xFF065F46)),
                const SizedBox(width: 6),
                Text(
                  'Relawan Siaga\nTerhubung (1)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    height: 1.15,
                  ),
                ),
              ],
            ),
            Text(
              'Semua O+\nTerverifikasi',
              textAlign: TextAlign.end,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF16A34A),
                height: 1.15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Relawan 1: Budi Santoso (8 mnt, Honda Beat)
        Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Garis Aksen Kiri Merah
              Container(
                width: 4,
                height: 105,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          // Avatar
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Budi Santoso',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Gol. O+',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '9x Donor Rutin',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '8 mnt',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              Text(
                                'Jarak 1.8 km',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Baris Bawah: Info Kendaraan & 2 Tombol
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.two_wheeler_rounded, size: 14, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                'Honda Beat S 4821 JX',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // Tombol Telepon
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Menghubungi Relawan Budi Santoso...', style: GoogleFonts.plusJakartaSans()),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFDBEAFE)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Telepon',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Tombol WhatsApp
                          InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Membuka chat WhatsApp relawan...', style: GoogleFonts.plusJakartaSans()),
                                  backgroundColor: const Color(0xFF15803D),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF15803D),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'WhatsApp',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Relawan 2: Ahmad Fauzi (14 mnt, En Route)
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Garis Aksen Kiri Hijau
              Container(
                width: 4,
                height: 95,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              image: const DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150&auto=format&fit=crop&q=80'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Ahmad Fauzi',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF16A34A)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Gol. O+',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '14x Donor Rutin',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '14 mnt',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Jarak 3.4 km',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Baris Bawah: Rute & Badge En Route
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.near_me_outlined, size: 13, color: Color(0xFF64748B)),
                              const SizedBox(width: 4),
                              Text(
                                'Rute Jl. Panglima Sudirman → RSUD',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'En Route',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 6. Callout Panduan Keluarga / Pemohon ───
  Widget _buildFamilyGuideCallout() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFECDD3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'i',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panduan Keluarga / Pemohon:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 3),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF991B1B),
                      height: 1.35,
                    ),
                    children: const [
                      TextSpan(text: 'Harap siapkan sampel tabung darah crossmatch pasien di loket '),
                      TextSpan(
                        text: 'BDRS RSUD Dr. Soegiri',
                        style: TextStyle(fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: '. Relawan akan langsung diarahkan ke ruang skrining donor darah lantai 2.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. Tombol: Pantau Status Pemindaian / Live Tracking ───
  Widget _buildLiveTrackingButton() {
    final hasDonor = _activeRequest?.hasAcceptedDonor == true;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          final reqId = _activeRequest?.id.toString() ?? '1';
          Navigator.pushNamed(
            context,
            AppRouter.requesterPantauRoute,
            arguments: reqId,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: hasDonor ? const Color(0xFFDC2626) : const Color(0xFFD97706),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(hasDonor ? Icons.explore_rounded : Icons.radar_rounded, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              hasDonor ? 'Pantau Lokasi Relawan (Live Tracking)' : 'Pantau Status Pemindaian Relawan',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Navigation Bar (3 Tabs) ───
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                index: 0,
                icon: Icons.assignment_turned_in_rounded,
                label: 'Permohonan',
                isSelected: _selectedTabIndex == 0,
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.near_me_outlined,
                label: 'Pantau',
                isSelected: _selectedTabIndex == 1,
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.person_outline_rounded,
                label: 'Profil',
                isSelected: _selectedTabIndex == 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    final color = isSelected ? const Color(0xFFDC2626) : const Color(0xFF94A3B8);

    return InkWell(
      onTap: () => _onBottomNavTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
