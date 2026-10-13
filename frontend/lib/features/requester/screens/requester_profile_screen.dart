import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../routes/app_router.dart';

class RequesterProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateToForm;
  final VoidCallback? onNavigateToStatus;

  const RequesterProfileScreen({
    super.key,
    this.onNavigateToForm,
    this.onNavigateToStatus,
  });

  @override
  State<RequesterProfileScreen> createState() => _RequesterProfileScreenState();
}

class _RequesterProfileScreenState extends State<RequesterProfileScreen> {
  final _authRepo = AuthRepository();
  final _requestRepo = BloodRequestRepository();

  UserModel? _currentUser;
  BloodRequestModel? _activeRequest;
  bool _isLoading = true;
  bool _isRadarWaActive = true;
  int _selectedTabIndex = 2; // Default aktif di Tab 'Profil'

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = await _authRepo.getCurrentUser();
      final requests = await _requestRepo.getRequests();

      BloodRequestModel? activeReq;
      if (requests.isNotEmpty) {
        // Cari permintaan yang sedang aktif atau yang paling baru
        activeReq = requests.firstWhere(
          (r) => r.status == 'diproses' || r.status == 'menunggu' || r.urgencyLevel == 'kritis',
          orElse: () => requests.first,
        );
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _activeRequest = activeReq;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedTabIndex) return;

    setState(() => _selectedTabIndex = index);

    if (index == 0) {
      if (widget.onNavigateToForm != null) {
        widget.onNavigateToForm!();
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.requesterRequestRoute);
      }
    } else if (index == 1) {
      if (widget.onNavigateToStatus != null) {
        widget.onNavigateToStatus!();
      } else {
        final reqId = _activeRequest?.id.toString() ?? '1';
        Navigator.pushReplacementNamed(context, AppRouter.requesterPantauRoute, arguments: reqId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patientName = _activeRequest?.patientName ?? _currentUser?.name ?? 'Dewi Rahayu';
    final bloodType = _activeRequest?.bloodType ?? 'O';
    final rhesus = _activeRequest?.rhesus ?? '+';
    final hospital = _activeRequest?.hospitalName ?? 'RSUD Dr. Soegiri Lamongan';
    final bagsNeeded = _activeRequest?.bagsNeeded ?? 2;
    final phone = _currentUser?.phone ?? '+62 812-3456-7890';
    final nik = _currentUser?.nik ?? '3524**********8901';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFDC2626)),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ─── 1. HEADER APP BAR (PMI LAMONGAN DARURAT & PROFIL) ───
                      _buildHeader(),
                      const SizedBox(height: 12),

                      // ─── 2. BANNER VERIFIKASI IDENTITAS (HIJAU) ───
                      _buildVerificationBanner(),
                      const SizedBox(height: 14),

                      // ─── 3. CARD PROFIL PEMOHON (DEWI RAHAYU) ───
                      _buildRequesterCard(
                        name: patientName,
                        nik: nik,
                        phone: phone,
                      ),
                      const SizedBox(height: 14),

                      // ─── 4. CARD STATUS MERAH: TANGGAP DARURAT SIAGA ───
                      _buildEmergencyStatusCard(
                        bagsNeeded: bagsNeeded,
                        bloodType: bloodType,
                        rhesus: rhesus,
                      ),
                      const SizedBox(height: 14),

                      // ─── 5. CARD DATA PASIEN UTAMA ───
                      _buildPatientDataCard(
                        patientName: patientName,
                        hospital: hospital,
                        bloodType: bloodType,
                        rhesus: rhesus,
                      ),
                      const SizedBox(height: 14),

                      // ─── 6. CARD KELUARGA PENDAMPING ───
                      _buildCompanionCard(),
                      const SizedBox(height: 14),

                      // ─── 7. CARD DOKUMEN MEDIS TERUNGGAH ───
                      _buildUploadedDocumentsCard(),
                      const SizedBox(height: 14),

                      // ─── 8. STATISTIK PERMOHONAN (2 KOTAK) ───
                      _buildHistoryStatsRow(),
                      const SizedBox(height: 18),

                      // ─── 9. PENGATURAN SIAGA & DUKUNGAN ───
                      _buildSettingsGroup(),
                      const SizedBox(height: 16),

                      // ─── 10. TOMBOL KELUAR SESI SIAGA ───
                      _buildLogoutButton(),
                      const SizedBox(height: 14),

                      // ─── 11. FOOTER PROTOKOL RESMI PMI ───
                      _buildFooterNote(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),

      // ─── BOTTOM NAVIGATION BAR (PERMOHONAN, PANTAU, PROFIL) ───
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─── Widget: Header PMI Lamongan ───
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
              'Profil',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Tombol Lonceng
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.notifications_none_rounded,
            color: Color(0xFF475569),
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        // Tombol Avatar Merah
        Container(
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
      ],
    );
  }

  // ─── Widget: Banner Verifikasi Identitas Hijau ───
  Widget _buildVerificationBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF16A34A),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'IDENTITAS TERVERIFIKASI DUKCAPIL & KIS#',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF15803D),
                letterSpacing: 0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
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
    );
  }

  // ─── Widget: Card Profil Pemohon ───
  Widget _buildRequesterCard({
    required String name,
    required String nik,
    required String phone,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar dengan Badge Centang Hijau
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(14),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150&auto=format&fit=crop&q=80'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              // Nama & Identitas NIK
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID/NIK: $nik',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF16A34A)),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // 2 Tombol Aksi: Ubah Data Profil & Hotline PMI
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Membuka form pembaruan profil pemohon...', style: GoogleFonts.plusJakartaSans()),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded, size: 16),
                  label: Text(
                    'Ubah Data Profil',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF334155),
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menghubungi Hotline Darurat PMI Lamongan: (0322) 321118', style: GoogleFonts.plusJakartaSans()),
                        backgroundColor: const Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.support_agent_rounded, size: 16),
                  label: Text(
                    'Hotline PMI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    backgroundColor: const Color(0xFFFEF2F2),
                    side: const BorderSide(color: Color(0xFFFECDD3)),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Widget: Card Merah Tanggap Darurat Siaga ───
  Widget _buildEmergencyStatusCard({
    required int bagsNeeded,
    required String bloodType,
    required String rhesus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Baris: TANGGAP DARURAT SIAGA | 1 Berjalan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'TANGGAP DARURAT SIAGA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '1 Berjalan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Detail Kebutuhan & Badge Golongan Darah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dibutuhkan: $bagsNeeded Kantong\nDarah',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kode Tiket: KMB-LMG-202510-158',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$bloodType$rhesus',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    rhesus == '+' ? 'RHESUS\nPOSITIF' : 'RHESUS\nNEGATIF',
                    textAlign: TextAlign.end,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.5,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),

          const SizedBox(height: 10),

          // Keterangan Status Bawah
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1 Donor Terkonfirmasi Menuju Faskes',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                '1 Lagi Diperlukan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Widget: Card Data Pasien Utama ───
  Widget _buildPatientDataCard({
    required String patientName,
    required String hospital,
    required String bloodType,
    required String rhesus,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul Bagian
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.bloodtype_rounded, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Text(
                  'Data Pasien Utama',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'RAWAT INAP',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Usia: 28 Tahun • Perempuan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.local_hospital_outlined, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'FASILITAS KESEHATAN SAAT INI:',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hospital,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Ruang Dahlia 3 - Bed 08',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.assignment_outlined, size: 13, color: Color(0xFF64748B)),
                        const SizedBox(width: 4),
                        Text(
                          'NOMOR REKAM MEDIS (RM):',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RM-2025-03491',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),

              // Kotak Merah Tua Golongan Darah
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF991B1B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.water_drop_rounded, color: Colors.white, size: 14),
                    const SizedBox(height: 1),
                    Text(
                      '$bloodType$rhesus',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Widget: Card Keluarga Pendamping ───
  Widget _buildCompanionCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.badge_outlined, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 6),
                Text(
                  'Keluarga Pendamping',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'SIAGA 24 JAM',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agus Prasetyo',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Hubungan: Suami Pasien',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+62 813-9876-5432',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ),
              // Tombol Call Telepon
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Menghubungi Pendamping Agus Prasetyo (+62 813-9876-5432)...', style: GoogleFonts.plusJakartaSans()),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Icon(
                    Icons.phone_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Widget: Card Dokumen Medis Terunggah ───
  Widget _buildUploadedDocumentsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.folder_shared_outlined, size: 16, color: Color(0xFFDC2626)),
                const SizedBox(width: 6),
                Text(
                  'Dokumen Medis Terunggah',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            Text(
              '3/3 LENGKAP',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              _buildDocItem(
                icon: Icons.badge_outlined,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEF2F2),
                title: 'e-KTP Pemohon & Pasien',
                subtitle: 'ID Terverifikasi Otomatis',
                isSuccess: true,
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildDocItem(
                icon: Icons.health_and_safety_outlined,
                iconColor: const Color(0xFF16A34A),
                iconBg: const Color(0xFFDCFCE7),
                title: 'Kartu BPJS Kesehatan',
                subtitle: 'Status Peserta Aktif',
                isSuccess: true,
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _buildDocItem(
                icon: Icons.description_outlined,
                iconColor: const Color(0xFFDC2626),
                iconBg: const Color(0xFFFEF2F2),
                title: 'Formulir Permintaan DRUP',
                subtitle: 'ID Valid: RS-Sgr-No-4921',
                isSuccess: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isSuccess,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    fontWeight: isSuccess ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Melihat pratinjau dokumen: $title', style: GoogleFonts.plusJakartaSans()),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF94A3B8)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ─── Widget: Statistik Permohonan (2 Kotak Berdampingan) ───
  Widget _buildHistoryStatsRow() {
    return Row(
      children: [
        // Kotak 1: SIAGA BERJALAN
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'SIAGA BERJALAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Icon(Icons.confirmation_number_outlined, size: 14, color: Color(0xFFDC2626)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '1',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFDC2626),
                  ),
                ),
                Text(
                  'Tiket Darurat',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Kotak 2: DONOR SUKSES
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DONOR SUKSES',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF16A34A)),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '0',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Siklus Sebelumnya',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Widget: Pengaturan Siaga & Dukungan ───
  Widget _buildSettingsGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pengaturan Siaga & Dukungan',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),

        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: [
              // Switch: Radar Siaga WhatsApp & SMS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.cell_tower_rounded, color: Color(0xFF16A34A), size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Radar Siaga WhatsApp & SMS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Notifikasi donor terdekat di radius 15km',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isRadarWaActive,
                      activeThumbColor: const Color(0xFF16A34A),
                      onChanged: (val) {
                        setState(() => _isRadarWaActive = val);
                      },
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Menu: Posko Donor Darah 24 Jam PMI Lamongan
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.local_hospital_rounded, color: Color(0xFFDC2626), size: 17),
                  ),
                  title: Text(
                    'Posko Donor Darah 24 Jam PMI Lamongan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Jl. Kusuma Bangsa No. 24, Lamongan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                  onTap: () {},
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Menu: Kebijakan Privasi & Enkripsi Rekam Medis
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF475569), size: 17),
                  ),
                  title: Text(
                    'Kebijakan Privasi & Enkripsi Rekam Medis',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  subtitle: Text(
                    'Data terlindungi UU PDP & standar Kemenkes',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Widget: Tombol Keluar dari Sesi Siaga Darurat ───
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: Text('Keluar Sesi?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              content: Text('Apakah Anda yakin ingin keluar dari sesi siaga darurat ini?', style: GoogleFonts.plusJakartaSans()),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Keluar', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );

          if (confirm == true && mounted) {
            await _authRepo.logout();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(context, AppRouter.loginRoute, (route) => false);
            }
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFF4338CA)),
        label: Text(
          'Keluar dari Sesi Siaga Darurat',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4338CA),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFEEF2FF),
          foregroundColor: const Color(0xFF4338CA),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFE0E7FF)),
          ),
        ),
      ),
    );
  }

  // ─── Widget: Catatan Protokol Resmi PMI ───
  Widget _buildFooterNote() {
    return Center(
      child: Text(
        'PROTOKOL RESMI UDD PMI KABUPATEN LAMONGAN • SIAGA TANGGAP DARURAT V2.4',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ─── Widget: Bottom Navigation Bar 3 Tab ───
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
                icon: Icons.description_outlined,
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
                icon: Icons.person_rounded,
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
