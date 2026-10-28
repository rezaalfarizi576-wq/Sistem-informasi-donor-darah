import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../routes/app_router.dart';
import '../../donor/screens/notification_screen.dart';

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

    return 'Dimas Prayoga';
  }

  /// Format alamat email
  String _resolveEmail() {
    final email = _currentUser?.email.trim() ?? '';
    return email.isNotEmpty ? email : 'dimas@example.com';
  }

  /// Nama pasien yang valid (tidak menampilkan placeholder 'string')
  String _resolvePatientName() {
    final reqName = _activeRequest?.patientName.trim() ?? '';
    if (reqName.isNotEmpty && reqName.toLowerCase() != 'string') {
      return reqName;
    }
    return 'Satriatama Bisma Yodha';
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
    final displayName = _resolveDisplayName();
    final userEmail = _resolveEmail();
    final patientName = _resolvePatientName();
    final bloodType = _activeRequest?.bloodType ?? 'B';
    final rhesus = _activeRequest?.rhesus ?? '+';
    final hospital = _activeRequest?.hospitalName ?? 'RSUD Dr. Soegiri Lamongan';
    final bagsNeeded = _activeRequest?.bagsNeeded ?? 1;
    final phone = _currentUser?.phone ?? '089577556823';
    final nik = (_currentUser?.nik.isNotEmpty == true && _currentUser!.nik.toLowerCase() != 'string')
        ? _currentUser!.nik
        : '3524021908920001';

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

                        // ── 4. STATUS PERMOHONAN & KEBUTUHAN DARAH ──
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

                        // ── 5. CARD DATA PASIEN & DIAGNOSIS MEDIS ──
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
                      builder: (_) => const NotificationScreen(),
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
                            '• ID: REQ-${_currentUser?.id ?? 155}',
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
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menghubungi Hotline Darurat PMI Lamongan: (0322) 321118', style: GoogleFonts.plusJakartaSans()),
                          backgroundColor: const Color(0xFFDC2626),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
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
                _buildPatientInfoRow('Usia / Gender', '28 Tahun • Laki-laki'),
                const SizedBox(height: 6),
                _buildPatientInfoRow('Rumah Sakit', hospital),
                const SizedBox(height: 6),
                _buildPatientInfoRow('Diagnosis Medis', 'Operasi Emergensi & Anemia Gravis'),
                const SizedBox(height: 6),
                _buildPatientInfoRow('Dokter Penanggung', 'dr. Andri Kusuma, Sp.PD (BDRS)'),
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

          // 2 Card Metrik Besar (Identik Donor)
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
                        '4.200',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0F172A),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Mililiter (4.2 L)\nTerfasilitasi',
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
                        '100%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF059669),
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pemenuhan Kebutuhan\nPasien Darurat',
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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membuka riwayat permohonan darah...', style: GoogleFonts.plusJakartaSans()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
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
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Dokumen rujukan telah terverifikasi oleh BDRS.', style: GoogleFonts.plusJakartaSans()),
                    backgroundColor: const Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.cell_tower_rounded,
              iconBg: const Color(0xFFEEF2FF),
              iconColor: const Color(0xFF4F46E5),
              title: 'Notifikasi Broadcast Radar Relawan',
              subtitle: 'Notifikasi real-time via WhatsApp & Push Alert',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pengaturan broadcast aktif untuk relawan terdekat.', style: GoogleFonts.plusJakartaSans()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.support_agent_rounded,
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFDC2626),
              title: 'Posko & Layanan Darurat PMI Lamongan',
              subtitle: 'Jl. Kusuma Bangsa No. 24, Lamongan • (0322) 321118',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Menghubungi Posko PMI Lamongan: (0322) 321118', style: GoogleFonts.plusJakartaSans()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildMenuItem(
              icon: Icons.privacy_tip_outlined,
              iconBg: const Color(0xFFF8FAFC),
              iconColor: const Color(0xFF64748B),
              title: 'Kebijakan Privasi & Enkripsi Rekam Medis',
              subtitle: 'Data terenkripsi dan terlindungi standar Kemenkes',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Membuka pedoman privasi & kerahasiaan rekam medis...', style: GoogleFonts.plusJakartaSans()),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mengunduh Surat Bukti Permohonan Darah resmi PDF...', style: GoogleFonts.plusJakartaSans()),
                  backgroundColor: const Color(0xFFDC2626),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
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
}
