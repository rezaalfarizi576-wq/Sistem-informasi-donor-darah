import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/utils/url_helper.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../routes/app_router.dart';
import 'requester_notification_screen.dart';

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
  List<BloodRequestModel> _allRequests = [];
  bool _isLoading = true;
  bool _isRadarWaActive = true;
  bool _isPushAlertActive = true;
  double _radarRadiusKm = 10.0;
  int _selectedTabIndex = 2; // Default aktif di Tab 'Profil'

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final user = await _authRepo.getCurrentUser();
      final requests = await _requestRepo.getMyRequests();

      BloodRequestModel? activeReq;
      if (requests.isNotEmpty) {
        // Cari permintaan yang sedang aktif
        try {
          activeReq = requests.firstWhere(
            (r) => r.status == 'diproses' || r.status == 'menunggu',
          );
        } catch (_) {
          activeReq = null;
        }
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _allRequests = requests;
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

  /// Menyesuaikan nama pemohon dari email jika nama kosong atau berisi default 'string'
  String _resolveDisplayName() {
    final rawName = _currentUser?.name.trim() ?? '';
    final email = _currentUser?.email.trim() ?? '';

    if (rawName.isNotEmpty && rawName.toLowerCase() != 'string') {
      return rawName;
    }

    if (email.isNotEmpty) {
      final username = email.split('@').first;
      final parts = username.split(RegExp(r'[._\-\+]')).where((p) => p.isNotEmpty).toList();
      if (parts.isNotEmpty) {
        final formatted = parts.map((p) {
          final clean = p.replaceAll(RegExp(r'^[0-9]+|[0-9]+$'), '');
          final word = clean.isNotEmpty ? clean : p;
          if (word.isEmpty) return '';
          return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
        }).where((w) => w.isNotEmpty).join(' ');

        if (formatted.isNotEmpty) return formatted;
      }
      return username;
    }

    return 'Pemohon Siaga';
  }

  /// Format alamat email
  String _resolveEmail() {
    final email = _currentUser?.email.trim() ?? '';
    return email.isNotEmpty ? email : '-';
  }

  /// Nama pasien yang valid
  String _resolvePatientName() {
    final reqName = _activeRequest?.patientName.trim() ?? '';
    if (reqName.isNotEmpty && reqName.toLowerCase() != 'string') {
      return reqName;
    }
    return _currentUser?.name ?? 'Pasien Darurat';
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
        final reqId = _activeRequest?.id.toString();
        Navigator.pushReplacementNamed(context, AppRouter.requesterPantauRoute, arguments: reqId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _resolveDisplayName();
    final userEmail = _resolveEmail();
    final patientName = _resolvePatientName();
    final bloodType = _currentUser?.bloodType ?? _activeRequest?.bloodType ?? 'A';
    final rhesus = _currentUser?.rhesus ?? _activeRequest?.rhesus ?? '+';
    final hospital = _activeRequest?.hospitalName ?? 'RSUD Dr. Soegiri Lamongan';
    final bagsNeeded = _activeRequest?.bagsNeeded ?? 0;
    final rawPhone = _currentUser?.phone?.trim() ?? '';
    final phone = (rawPhone.isNotEmpty && rawPhone.toLowerCase() != 'string') ? rawPhone : '-';
    final rawNik = _currentUser?.nik?.trim() ?? '';
    final nik = (rawNik.isNotEmpty && rawNik.toLowerCase() != 'string') ? rawNik : '-';

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── 1. TOP HEADER (Identik dengan Donor Profile) ──
                        _buildTopHeader(),

                        const Divider(height: 1, color: Color(0xFFF1F5F9)),

                        // ── 2. SUB BAR: STATUS IDENTITAS & FASKES ──
                        _buildSubBar(hospital),

                        const SizedBox(height: 8),

                        // ── 3. CARD UTAMA PROFIL PEMOHON (Merah Stripe & Card Putih) ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildMainProfileCard(
                            displayName: displayName,
                            userEmail: userEmail,
                            phone: phone,
                            nik: nik,
                            bloodType: bloodType,
                            rhesus: rhesus,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // ── 4 & 5. STATUS PERMOHONAN & DATA PASIEN (HANYA JIKA ADA REQUEST AKTIF) ──
                        if (_activeRequest != null) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildEmergencyStatusCard(
                              bagsNeeded: bagsNeeded,
                              bloodType: bloodType,
                              rhesus: rhesus,
                              hospital: hospital,
                            ),
                          ),
                          const SizedBox(height: 14),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildPatientDataCard(
                              patientName: patientName,
                              hospital: hospital,
                              bloodType: bloodType,
                              rhesus: rhesus,
                            ),
                          ),
                          const SizedBox(height: 14),
                        ] else ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: _buildNoActiveRequestCard(),
                          ),
                          const SizedBox(height: 14),
                        ],

                        const SizedBox(height: 14),

                        // ── 6. STATISTIK PERMOHONAN DARAH (2 METRIK BESAR) ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildStatisticsCard(),
                        ),

                        const SizedBox(height: 14),

                        // ── 7. PENGATURAN AKUN & BANTUAN ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildSettingsGroup(),
                        ),

                        const SizedBox(height: 18),

                        // ── 8. TOMBOL AKSI BAWAH ──
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: _buildBottomActionButtons(),
                        ),

                        const SizedBox(height: 16),

                        // ── 9. FOOTER PROTOKOL RESMI PMI ──
                        _buildFooterNote(),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),

      // ─── BOTTOM NAVIGATION BAR (PERMOHONAN, PANTAU, PROFIL) ───
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ── 1. TOP HEADER (PMI LAMONGAN Requester Profile) ──
  Widget _buildTopHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PMI LAMONGAN',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFDC2626),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              Text(
                'Requester Profile',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF0F172A),
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Lonceng Notifikasi
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RequesterNotificationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569), size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Positioned(
                right: 1,
                top: 1,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDC2626),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          // Profile Avatar Aktif
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF991B1B),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  // ── 2. SUB BAR: STATUS IDENTITAS & FASKES ──
  Widget _buildSubBar(String hospital) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF22C55E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'IDENTITAS TERVERIFIKASI DUKCAPIL & KIS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF15803D),
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 13, color: Color(0xFF94A3B8)),
              const SizedBox(width: 2),
              Text(
                hospital.contains('Soegiri') ? 'RSUD Soegiri (1.8 km)' : 'Lamongan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 3. CARD UTAMA PROFIL PEMOHON ──
  Widget _buildMainProfileCard({
    required String displayName,
    required String userEmail,
    required String phone,
    required String nik,
    required String bloodType,
    required String rhesus,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
          // Accent line merah tipis atas (Signature PMI)
          Container(
            height: 3.5,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),

          // User Info Row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar Profil dengan Badge Centang Hijau
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFECDD3)),
                      ),
                      child: const Icon(Icons.person_rounded, color: Color(0xFFDC2626), size: 36),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Nama & Identitas Email / ID
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.mail_outline_rounded, size: 12, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              userEmail,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone_rounded, size: 12, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF334155),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '• ID: REQ-${_currentUser?.id ?? ''}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF94A3B8),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.shield_outlined, size: 13, color: Color(0xFFDC2626)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Pemohon Siaga BDRS Terverifikasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF475569),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Badge Golongan Darah Kotak Hitam (Identik dengan Profil Donor)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        bloodType,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                      Text(
                        'Rh$rhesus',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Box Toggle Siaga Radar Darurat (Identik dengan Toggle Donor)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.radar_rounded, color: Color(0xFFDC2626), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Radar Relawan Siaga (Radius 10 km)',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Koneksi live broadcast WhatsApp & Aplikasi Relawan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isRadarWaActive,
                    activeThumbColor: const Color(0xFFDC2626),
                    activeTrackColor: const Color(0xFFFECDD3),
                    onChanged: (val) {
                      setState(() => _isRadarWaActive = val);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            val
                                ? 'Radar Relawan Siaga Aktif! Notifikasi broadcast diaktifkan.'
                                : 'Radar Relawan Dinonaktifkan.',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: val ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 2 Tombol Aksi Cepat: Ubah Data Profil & Hotline PMI
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
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
                      UrlHelper.makePhoneCall(context, '(0322) 321118');
                    },
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                    label: Text(
                      'Hotline PMI (24 Jam)',
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
          ),
        ],
      ),
    );
  }

  // ── 4. STATUS PERMOHONAN & KEBUTUHAN DARAH (Identik dengan Indeks Kebugaran Donor) ──
  // ─── CARD EMPTY STATE KHUSUS PEMOHON TANPA PERMOHONAN AKTIF ───
  Widget _buildNoActiveRequestCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.assignment_outlined, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 8),
              Text(
                'Status Permohonan Darah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TIDAK ADA PERMINTAAN AKTIF',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Saat ini akun Anda belum memiliki permohonan darah darurat yang sedang berjalan di rumah sakit.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _onBottomNavTapped(0),
            icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.white),
            label: Text(
              'Buat Permohonan Darah Baru',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyStatusCard({
    required int bagsNeeded,
    required String bloodType,
    required String rhesus,
    required String hospital,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Row(
            children: [
              const Icon(Icons.health_and_safety_outlined, color: Color(0xFFDC2626), size: 18),
              const SizedBox(width: 8),
              Text(
                'Status Permohonan &\nKebutuhan Darah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'TERVALIDASI\nBDRS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF4F46E5),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Box Progres Dispatch Relawan (Identik Progress Box Donor)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      'PROGRES DISPATCH RELAWAN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _activeRequest != null && _activeRequest!.acceptedDonorsCount > 0
                          ? '${_activeRequest!.acceptedDonorsCount} Relawan Siaga Menuju RS'
                          : 'Belum Ada Relawan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: _activeRequest != null && _activeRequest!.acceptedDonorsCount > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _activeRequest != null && _activeRequest!.acceptedDonorsCount > 0
                        ? 0.70
                        : 0.15,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _activeRequest != null && _activeRequest!.acceptedDonorsCount > 0
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.history_rounded, size: 13, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 4),
                    Text(
                      _activeRequest != null && _activeRequest!.acceptedDonorsCount > 0
                          ? 'Terakhir: Resep BDRS Diverifikasi'
                          : 'Menunggu konfirmasi relawan...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _activeRequest != null && _activeRequest!.acceptedDonorsCount > 0
                          ? 'Est. Tiba: ~12 Menit'
                          : 'Menunggu...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _activeRequest != null && _activeRequest!.acceptedDonorsCount > 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3 Kolom Vital Signs / Specs
          Row(
            children: [
              Expanded(
                child: _buildVitalSignBox(
                  label: 'Kebutuhan',
                  value: '$bagsNeeded',
                  unit: 'Ktg',
                  status: '● Menunggu',
                  statusColor: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVitalSignBox(
                  label: 'Gol. Darah',
                  value: bloodType,
                  unit: 'Rh$rhesus',
                  status: '● Kritis',
                  statusColor: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildVitalSignBox(
                  label: 'Lokasi RS',
                  value: 'Soegiri',
                  unit: '',
                  status: '● Rawat Inap',
                  statusColor: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 5. CARD DATA PASIEN & DIAGNOSIS MEDIS ──
  Widget _buildPatientDataCard({
    required String patientName,
    required String hospital,
    required String bloodType,
    required String rhesus,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.personal_injury_outlined, color: Color(0xFFDC2626), size: 18),
              const SizedBox(width: 8),
              Text(
                'Data Pasien & Diagnosis Medis',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RAWAT INAP',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildPatientInfoRow('Nama Pasien', patientName, isHighlight: true),
                const SizedBox(height: 6),
                _buildPatientInfoRow('Rumah Sakit', hospital),
                const SizedBox(height: 6),
                _buildPatientInfoRow('Kebutuhan Darah', '${_activeRequest?.bagsNeeded ?? 1} Kantong ($bloodType$rhesus)'),
                const SizedBox(height: 6),
                _buildPatientInfoRow(
                  'Catatan Medis',
                  (_activeRequest?.notes?.isNotEmpty == true && _activeRequest!.notes!.toLowerCase() != 'string')
                      ? _activeRequest!.notes!
                      : 'Permohonan Darah Siaga Emergensi RS',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? const Color(0xFF0F172A) : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  // ── 6. STATISTIK PERMOHONAN DARAH (Identik Statistik Kontribusi Jiwa Donor) ──
  Widget _buildStatisticsCard() {
    final bags = _activeRequest?.bagsNeeded ?? 0;
    final donorsCount = _activeRequest?.acceptedDonorsCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.track_changes_rounded, color: Color(0xFFDC2626), size: 18),
              const SizedBox(width: 8),
              Text(
                'Statistik Permohonan Darah',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'PRIORITAS RESMI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFDC2626),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 2 Card Metrik Pemohon Darah
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.water_drop_rounded, color: Color(0xFFDC2626), size: 20),
                      const SizedBox(height: 8),
                      Text(
                        '$bags',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kantong Darah\nDibutuhkan',
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
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF059669), size: 20),
                      const SizedBox(height: 8),
                      Text(
                        '$donorsCount',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF059669),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Relawan Siaga\nMenuju RS',
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
          ),

          const SizedBox(height: 10),

          // Card Progress Target Pin Layanan
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAF5FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF3E8FF)),
            ),
            child: Row(
              children: [
                const Icon(Icons.military_tech_rounded, color: Color(0xFF9333EA), size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Layanan Prioritas BDRS',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Standar UDD PMI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF9333EA),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Seluruh permintaan darah diverifikasi dokter spesialis patologi klinik & BDRS.',
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
          ),
        ],
      ),
    );
  }

  // ── 7. PENGATURAN AKUN & BANTUAN (Identik Donor Profile) ──
  Widget _buildSettingsGroup() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PENGATURAN & LAYANAN RESMI',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),

        Column(
          children: [
            _buildMenuItem(
              icon: Icons.history_rounded,
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFDC2626),
              title: 'Riwayat Permohonan Darah Selesai',
              subtitle: 'Arsip riwayat permohonan & distribusi donor',
              onTap: () => _showHistoryModal(),
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.verified_outlined,
              iconBg: const Color(0xFFF0FDF4),
              iconColor: const Color(0xFF16A34A),
              title: 'Surat Bukti Kebutuhan Darah (BDRS)',
              subtitle: 'Formulir resmi rujukan dokter rumah sakit',
              badge: 'TERVERIFIKASI',
              badgeBg: const Color(0xFFDCFCE7),
              badgeColor: const Color(0xFF16A34A),
              onTap: () => _showBdrsDocumentModal(),
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.cell_tower_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'Notifikasi Broadcast Radar Relawan',
              subtitle: 'Notifikasi real-time via WhatsApp & Push Alert',
              onTap: () => _showRadarSettingsModal(),
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.support_agent_rounded,
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFDC2626),
              title: 'Posko & Layanan Darurat PMI Lamongan',
              subtitle: 'Jl. Kusuma Bangsa No. 24, Lamongan • (0322) 321118',
              onTap: () => _showPoskoModal(),
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              iconBg: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF64748B),
              title: 'Kebijakan Privasi & Enkripsi Rekam Medis',
              subtitle: 'Data terenkripsi dan terlindungi standar Kemenkes',
              onTap: () => _showPrivacyPolicyModal(),
            ),
          ],
        ),
      ],
    );
  }

  // ── 8. TOMBOL AKSI BAWAH (Unduh Bukti & Keluar Akun) ──
  Widget _buildBottomActionButtons() {
    return Column(
      children: [
        // Tombol Unduh Bukti Permohonan Darah
        SizedBox(
          width: double.infinity,
          height: 46,
          child: ElevatedButton(
            onPressed: () => _showDownloadProofModal(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.download_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Unduh Bukti Permohonan Darah (PDF)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Tombol Keluar Sesi Akun Pemohon
        SizedBox(
          width: double.infinity,
          height: 44,
          child: OutlinedButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Konfirmasi Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  content: Text('Apakah Anda yakin ingin keluar dari akun pemohon?', style: GoogleFonts.plusJakartaSans()),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Batal', style: GoogleFonts.plusJakartaSans()),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Keluar', style: GoogleFonts.plusJakartaSans(color: Colors.white)),
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
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFECDD3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.logout_rounded, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Keluar Sesi Akun Pemohon',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── 9. FOOTER PROTOKOL RESMI PMI ──
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

  // ─── Helper: Vital Sign / Spec Box (Identik Donor) ───
  Widget _buildVitalSignBox({
    required String label,
    required String value,
    required String unit,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 2),
                Text(
                  unit,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Text(
            status,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper: Menu List Item (Identik Donor) ───
  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeBg,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badge,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  // ─── Bottom Navigation Bar (Permohonan, Pantau, Profil) ───
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

  // ─────────────────────────────────────────────────────────
  // MODAL 1: RIWAYAT PERMOHONAN DARAH SELESAI
  // ─────────────────────────────────────────────────────────
  void _showHistoryModal() {
    final finishedList = _allRequests.where((r) => r.status.toLowerCase() == 'selesai' || r.status.toLowerCase() == 'in_progress').toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.history_rounded, color: Color(0xFFDC2626), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Permohonan Darah',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Total ${_allRequests.length} permohonan tercatat di sistem',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 12),
            Expanded(
              child: _allRequests.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada riwayat permohonan darah.',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: _allRequests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (c, idx) {
                        final req = _allRequests[idx];
                        final isDone = req.status.toLowerCase() == 'selesai';
                        final badgeColor = isDone ? const Color(0xFF16A34A) : const Color(0xFFD97706);
                        final badgeBg = isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7);
                        final statusText = isDone ? 'SELESAI DIDONORKAN' : req.status.toUpperCase();

                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${req.bloodType}${req.rhesus}',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        req.patientName.isNotEmpty ? req.patientName : 'Pasien',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      statusText,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w800,
                                        color: badgeColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.local_hospital_outlined, size: 13, color: Color(0xFF64748B)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      req.hospitalName ?? 'RSUD Dr. Soegiri Lamongan',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF475569)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${req.bagsNeeded} Kantong',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Tutup', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // MODAL 2: SURAT BUKTI KEBUTUHAN DARAH (BDRS)
  // ─────────────────────────────────────────────────────────
  void _showBdrsDocumentModal() {
    final req = _activeRequest ?? (_allRequests.isNotEmpty ? _allRequests.first : null);
    final patient = req?.patientName ?? 'Pasien Rujukan UDD';
    final hospital = req?.hospitalName ?? 'RSUD Dr. Soegiri Lamongan';
    final goldar = req != null ? '${req.bloodType}${req.rhesus}' : 'O+';
    final bags = req?.bagsNeeded ?? 2;
    final doctor = 'dr. Bambang Irawan, Sp.PK';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Formulir Kebutuhan Darah (BDRS)',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Verifikasi Bank Darah Rumah Sakit & UDD PMI',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Lambang PMI / BDRS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BANK DARAH RUMAH SAKIT',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              Text(
                                hospital.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'TERVALIDASI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFE2E8F0)),

                      _buildDataRow('Nama Pasien', patient),
                      _buildDataRow('No. Rekam Medis (RM)', 'RM-2026-${(req?.id ?? 1).toString().padLeft(5, "0")}'),
                      _buildDataRow('Golongan Darah', goldar),
                      _buildDataRow('Kebutuhan Kantong', '$bags Kantong (Packed Red Cell / WB)'),
                      _buildDataRow('Faskes Penyelenggara', hospital),
                      _buildDataRow('Dokter Penanggung Jawab', doctor),
                      _buildDataRow('Status Uji Cocok Serasi', 'Compatible (Cocok Non-Reaktif)'),
                      _buildDataRow('Penyalur Distribusi', 'UDD PMI Kabupaten Lamongan'),

                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDBEAFE)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF2563EB)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Formulir ini diterbitkan secara otomatis dan terdaftar pada sistem registrasi UDD PMI Lamongan.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF1E40AF)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Tutup Dokumen', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // MODAL 3: NOTIFIKASI BROADCAST RADAR RELAWAN
  // ─────────────────────────────────────────────────────────
  void _showRadarSettingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cell_tower_rounded, color: Color(0xFF4F46E5), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Radar Siaga Relawan & Alert',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Konfigurasi jangkauan siaga relawan donor terdekat',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                value: _isRadarWaActive,
                activeColor: const Color(0xFF4F46E5),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Kirim Alert Langsung ke WhatsApp Relawan',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Kirim pesan WhatsApp otomatis ke relawan yang cocok dalam radius radar.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                onChanged: (val) {
                  setModalState(() => _isRadarWaActive = val);
                  setState(() => _isRadarWaActive = val);
                },
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              SwitchListTile(
                value: _isPushAlertActive,
                activeColor: const Color(0xFF4F46E5),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Push Notification Suara Darurat',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Membunyikan sirene notifikasi darurat pada HP relawan siaga.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                ),
                onChanged: (val) {
                  setModalState(() => _isPushAlertActive = val);
                  setState(() => _isPushAlertActive = val);
                },
              ),
              const Divider(height: 16, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Radius Radar Jangkauan Relawan',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '${_radarRadiusKm.toInt()} Km',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _radarRadiusKm,
                min: 3.0,
                max: 30.0,
                divisions: 9,
                activeColor: const Color(0xFF4F46E5),
                onChanged: (val) {
                  setModalState(() => _radarRadiusKm = val);
                  setState(() => _radarRadiusKm = val);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pengaturan radar broadcast berhasil disimpan.', style: GoogleFonts.plusJakartaSans()),
                        backgroundColor: const Color(0xFF4F46E5),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Simpan Pengaturan', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // MODAL 4: POSKO & LAYANAN DARURAT PMI LAMONGAN
  // ─────────────────────────────────────────────────────────
  void _showPoskoModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UDD PMI Kabupaten Lamongan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Layanan Darurat & Bank Darah Siaga 24 Jam',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Jl. Kombespol M. Duryat No. 42 / Jl. Kusuma Bangsa, Lamongan',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text(
                        'Pelayanan: 24 Jam Non-Stop (Setiap Hari)',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      UrlHelper.makePhoneCall(context, '(0322) 321118');
                    },
                    icon: const Icon(Icons.phone_rounded, size: 16),
                    label: Text(
                      'Panggil Telepon',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      UrlHelper.openWhatsApp(
                        context,
                        rawPhone: '081234889123',
                        message: 'Halo Posko UDD PMI Lamongan, saya pemohon darah ingin menanyakan kesiapan stok kantong darah darurat. Terima kasih.',
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                    label: Text(
                      'Chat WhatsApp',
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // MODAL 5: KEBIJAKAN PRIVASI & ENKRIPSI REKAM MEDIS
  // ─────────────────────────────────────────────────────────
  void _showPrivacyPolicyModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF475569), size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privasi & Enkripsi Rekam Medis',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Kepatuhan Standar UU PDP & Kemenkes RI',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPrivacyItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Enkripsi Data End-to-End',
                      desc: 'NIK dan data sensitif pasien dienkripsi pada database dan transmisi SSL/TLS 256-bit standar medis.',
                    ),
                    _buildPrivacyItem(
                      icon: Icons.medical_information_outlined,
                      title: 'Kerahasiaan Diagnosa & Rekam Medis',
                      desc: 'Relawan hanya melihat inisial, rumah sakit rujukan, dan jenis golongan darah yang dibutuhkan tanpa diagnosa medis pasien.',
                    ),
                    _buildPrivacyItem(
                      icon: Icons.admin_panel_settings_outlined,
                      title: 'Verifikasi Otoritas BDRS',
                      desc: 'Hanya dokter BDRS dan tim admin PMI Lamongan yang berhak melihat dokumen surat rujukan fisik.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Saya Mengerti', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // MODAL 6: UNDUH BUKTI PERMOHONAN DARAH RESMI
  // ─────────────────────────────────────────────────────────
  void _showDownloadProofModal() {
    final req = _activeRequest ?? (_allRequests.isNotEmpty ? _allRequests.first : null);
    final patient = req?.patientName ?? 'Pasien Rujukan UDD';
    final hospital = req?.hospitalName ?? 'RSUD Dr. Soegiri Lamongan';
    final goldar = req != null ? '${req.bloodType}${req.rhesus}' : 'O+';
    final bags = req?.bagsNeeded ?? 1;
    final reqId = req?.id != null ? 'REQ-LMG-${req!.id.toString().padLeft(5, "0")}' : 'REQ-LMG-00128';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        child: Column(
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Lembar Bukti Registrasi Permohonan Darah',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Tunjukkan dokumen digital ini ke petugas UDD PMI / BDRS',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Kop Dokumen
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PALANG MERAH INDONESIA',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                                Text(
                                  'KABUPATEN LAMONGAN',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VERIFIED',
                              style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w900, color: const Color(0xFF16A34A)),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),

                      // Barcode / QR Code
                      Center(
                        child: QrImageView(
                          data: 'PMI-LAMONGAN:$reqId:$patient:$goldar:$hospital',
                          version: QrVersions.auto,
                          size: 130.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reqId,
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 14),

                      _buildDataRow('Nama Pasien', patient),
                      _buildDataRow('Golongan Darah', goldar),
                      _buildDataRow('Jumlah Dibutuhkan', '$bags Kantong'),
                      _buildDataRow('Faskes Tujuan', hospital),
                      _buildDataRow('Pemohon', _resolveDisplayName()),
                      _buildDataRow('Status', (req?.status ?? 'DIPROSES').toUpperCase()),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Tutup', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Dokumen bukti permohonan $reqId berhasil disimpan ke perangkat.', style: GoogleFonts.plusJakartaSans()),
                          backgroundColor: const Color(0xFF16A34A),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.file_download_done_rounded, size: 16),
                    label: Text('Simpan File', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem({required IconData icon, required String title, required String desc}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
