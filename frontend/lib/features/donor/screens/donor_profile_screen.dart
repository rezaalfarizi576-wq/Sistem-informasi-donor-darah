import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/utils/url_helper.dart';
import '../../../data/models/donor_stats_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/donor_repository.dart';
import '../../../routes/app_router.dart';
import 'donation_history_screen.dart';
import 'notification_screen.dart';

class DonorProfileScreen extends StatefulWidget {
  final UserModel? currentUser;
  final VoidCallback? onLogout;

  const DonorProfileScreen({
    super.key,
    this.currentUser,
    this.onLogout,
  });

  @override
  State<DonorProfileScreen> createState() => _DonorProfileScreenState();
}

class _DonorProfileScreenState extends State<DonorProfileScreen> {
  final _authRepo = AuthRepository();
  final _donorRepo = DonorRepository();
  bool _isSiagaDaruratActive = true;
  UserModel? _currentUser;
  DonorStatsModel? _donorStats;
  bool _isLoadingStats = true;

  // State Pengaturan Geofencing
  double _geofenceRadiusKm = 5.0;

  // State Kontak Darurat Keluarga
  String _emergencyContactName = 'Siti Rahayu';
  String _emergencyContactRelation = 'Istri';
  String _emergencyContactPhone = '0812-3488-9123';

  // Titik koordinat pusat Lamongan untuk Geofence map
  final LatLng _pmiLocation = const LatLng(-7.1265, 112.4182);

  @override
  void initState() {
    super.initState();
    _currentUser = widget.currentUser;
    _loadUserAndStats();
  }

  Future<void> _loadUserAndStats() async {
    if (_currentUser == null) {
      final user = await _authRepo.getCurrentUser();
      if (user != null && mounted) {
        setState(() => _currentUser = user);
      }
    }
    try {
      final stats = await _donorRepo.getDonorStats();
      if (mounted) {
        setState(() {
          _donorStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser ?? widget.currentUser;
    final userName = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : 'Pendonor';
    final userBloodType = user?.bloodType ?? 'O';
    final userRhesus = user?.rhesus ?? '+';

    final stats = _donorStats;
    final totalDonations = stats?.totalDonations ?? 0;
    final totalVolumeMl = (stats != null && stats.totalBags > 0)
        ? stats.totalBags * 350
        : (totalDonations * 350);
    final totalLitersStr = (totalVolumeMl / 1000.0).toStringAsFixed(1);
    final livesSaved = totalDonations > 0 ? '${totalDonations * 3}+' : '0';

    // Perhitungan jeda regenerasi donor
    final daysSinceLast = stats?.daysSinceLast ?? 999;
    final eligibleToDonate = stats?.eligibleToDonate ?? true;
    final bool hasDonatedBefore = totalDonations > 0;

    String jedaText;
    double progressJeda;
    String jadwalText;
    String terakhirText;

    if (!hasDonatedBefore) {
      jedaText = 'SIAP DONOR';
      progressJeda = 1.0;
      jadwalText = 'Kapan Saja';
      terakhirText = 'Belum Ada Riwayat Donor';
    } else if (eligibleToDonate) {
      jedaText = 'SIAP DONOR';
      progressJeda = 1.0;
      jadwalText = 'Hari Ini';
      terakhirText = 'Terakhir: ${stats?.latestDonation?.location ?? "PMI Lamongan"} (${stats?.lastDonationDisplay})';
    } else {
      final sisaHari = (60 - daysSinceLast).clamp(1, 60);
      jedaText = '$sisaHari Hari Lagi';
      progressJeda = (daysSinceLast / 60.0).clamp(0.05, 1.0);
      jadwalText = 'Jadwal: +$sisaHari hari';
      terakhirText = 'Terakhir: ${stats?.latestDonation?.location ?? "PMI Lamongan"} (${stats?.lastDonationDisplay})';
    }

    // Level status relawan
    String levelBadge;
    Color levelBadgeColor;
    Color levelBadgeBg;
    if (totalDonations >= 10) {
      levelBadge = 'GOLD DONOR';
      levelBadgeColor = const Color(0xFFD97706);
      levelBadgeBg = const Color(0xFFFEF3C7);
    } else if (totalDonations >= 5) {
      levelBadge = 'SILVER DONOR';
      levelBadgeColor = const Color(0xFFDC2626);
      levelBadgeBg = const Color(0xFFFEE2E2);
    } else if (totalDonations >= 1) {
      levelBadge = 'BRONZE DONOR';
      levelBadgeColor = const Color(0xFFB45309);
      levelBadgeBg = const Color(0xFFFEF3C7);
    } else {
      levelBadge = 'RELAWAN BARU';
      levelBadgeColor = const Color(0xFF2563EB);
      levelBadgeBg = const Color(0xFFDBEAFE);
    }

    final targetMilestone = totalDonations < 10 ? 10 : (((totalDonations ~/ 10) + 1) * 10);
    final progressTarget = totalDonations == 0 ? 0.0 : ((totalDonations % 10) / 10.0).clamp(0.0, 1.0);
    final percentTarget = (progressTarget * 100).toInt();
    final remainingTarget = totalDonations == 0 ? 1 : (targetMilestone - totalDonations);

    // Vital signs dinamis
    final bloodPressure = stats?.bloodPressure ?? '120/80';
    final hemoglobin = stats != null ? stats.hemoglobin.toStringAsFixed(1) : '14.5';
    final weight = (stats?.weight ?? 68).toString();

    // Nomor KTA dinamis
    final ktaId = (user?.idPmi != null && user!.idPmi!.isNotEmpty)
        ? user.idPmi!
        : (stats?.idPmi ?? 'PMI-LMG-${(user?.id ?? 1).toString().padLeft(4, '0')}');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. TOP HEADER (PMI LAMONGAN Donor Profile) ──
              if (_isLoadingStats)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: Color(0xFFE11D48),
                  backgroundColor: Color(0xFFFEE2E2),
                ),
              Container(
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
                          'Donor Profile',
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
                    // Lonceng notifikasi
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
                    // Profile avatar aktif
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
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // ── 2. SUB BAR: STATUS GEOFENCING ──
              Padding(
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
                      'GPS GEOFENCING AKTIF',
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
                          'RSUD Soegiri (1.8 km)',
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
              ),

              const SizedBox(height: 8),

              // ── 3. CARD UTAMA PROFIL RELAWAN ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                      // Accent line merah tipis atas
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
                            // Foto / Avatar Profil dengan Badge
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

                            // Nama & ID Relawan
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'ID: LMG-89410294',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11.5,
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.military_tech_rounded, size: 14, color: Color(0xFFDC2626)),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          'Relawan Aktif Tingkat Madya',
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

                            // Badge Golongan Darah Kotak Hitam
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    userBloodType,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    'Rh$userRhesus',
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

                      // Box Toggle Siaga Darurat
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
                                child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFDC2626), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Siaga Darurat (Radius 5 km)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Siap radar emergency RSUD Soegiri',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _isSiagaDaruratActive,
                                activeThumbColor: const Color(0xFFDC2626),
                                activeTrackColor: const Color(0xFFFECDD3),
                                onChanged: (val) {
                                  setState(() => _isSiagaDaruratActive = val);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        val ? 'Siaga Darurat Aktif! Anda akan menerima alarm darurat.' : 'Siaga Darurat Dinonaktifkan.',
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 4. INDEKS KEBUGARAN & KELAYAKAN CARD ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                            'Indeks Kebugaran &\nKelayakan',
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
                              'TERVALIDASI\nLAB',
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

                      // Box Jeda Wajib Regenerasi
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
                                  'JEDA WAJIB REGENERASI',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  jedaText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: eligibleToDonate ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressJeda,
                                backgroundColor: const Color(0xFFE2E8F0),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  eligibleToDonate ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                ),
                                minHeight: 6,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.history_rounded, size: 13, color: Color(0xFF94A3B8)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    terakhirText,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  jadwalText,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 3 Kolom Vital Signs
                      Row(
                        children: [
                          Expanded(
                            child: _buildVitalSignBox(
                              label: 'Tekanan Darah',
                              value: bloodPressure,
                              unit: '',
                              status: '● Normal',
                              statusColor: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildVitalSignBox(
                              label: 'Hemoglobin',
                              value: hemoglobin,
                              unit: 'g/dL',
                              status: '● Sangat Baik',
                              statusColor: const Color(0xFF16A34A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildVitalSignBox(
                              label: 'Berat Badan',
                              value: weight,
                              unit: 'kg',
                              status: '● Memenuhi',
                              statusColor: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 5. STATISTIK KONTRIBUSI JIWA CARD ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
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
                            'Statistik Kontribusi Jiwa',
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
                              color: levelBadgeBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              levelBadge,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: levelBadgeColor,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 2 Card Metrik Besar
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
                                    totalVolumeMl.toString(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF0F172A),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Mililiter ($totalLitersStr L)\nDidonorkan',
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
                                    livesSaved,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF059669),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jiwa Kritis\nTertolong',
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

                      // Card Progress Target Pin Emas
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
                                        '$totalDonations / $targetMilestone Donor',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$percentTarget%',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    totalDonations == 0
                                        ? 'Mulai donor pertama Anda untuk meraih Pin Kehormatan'
                                        : 'Tinggal $remainingTarget donor menuju Pin Kehormatan $targetMilestone Donor',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
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
                ),
              ),

              const SizedBox(height: 14),

              // ── 6. RADIUS PANTAU SIAGA (MINI MAP GEOFENCE) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      // Header Map
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_outlined, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Radius Pantau Siaga',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${_geofenceRadiusKm.toStringAsFixed(1)} KM GEOFENCE',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Peta Geofence
                      SizedBox(
                        height: 110,
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: MapOptions(
                                initialCenter: _pmiLocation,
                                initialZoom: 13.5,
                                minZoom: 11.0,
                                maxZoom: 16.0,
                                interactionOptions: const InteractionOptions(
                                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'id.pmi.donordarah.lamongan',
                                ),
                                CircleLayer(
                                  circles: [
                                    CircleMarker(
                                      point: _pmiLocation,
                                      radius: (35 + (_geofenceRadiusKm * 9)).clamp(30.0, 160.0),
                                      useRadiusInMeter: false,
                                      color: const Color(0xFFDC2626).withValues(alpha: 0.15),
                                      borderColor: const Color(0xFFDC2626),
                                      borderStrokeWidth: 1.5,
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    Marker(
                                      point: _pmiLocation,
                                      width: 28,
                                      height: 28,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Floating status bawah map
                            Positioned(
                              bottom: 6,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        'UTD PMI Cabang Lamongan Siap Hubungkan',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── 7. LAYANAN & DOKUMEN RESMI ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Layanan & Dokumen Resmi',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.shield_outlined,
                      iconBg: const Color(0xFFFFF1F2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'E-Sertifikat & Piagam Penghargaan',
                      subtitle: '$totalDonations Piagam tersimpan • Tervalidasi PMI Pusat',
                      onTap: () => _showCertificateModal(context, userName, '$userBloodType$userRhesus', totalDonations, totalVolumeMl),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.verified_outlined,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Hasil Skrining IMLTD & Uji Lab',
                      subtitle: 'HIV, Hep B/C, Sifilis • Uji Darah Aman',
                      badge: 'NON-\nREAKTIF',
                      badgeBg: const Color(0xFFDCFCE7),
                      badgeColor: const Color(0xFF16A34A),
                      onTap: () => _showLabScreeningModal(context, userName),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.map_outlined,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF4F46E5),
                      title: 'Pengaturan Radius Geofencing',
                      subtitle: 'Jangkauan saat ini: ${_geofenceRadiusKm.toStringAsFixed(1)} kilometer',
                      onTap: () => _showGeofenceSettingsModal(context),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.contact_phone_outlined,
                      iconBg: const Color(0xFFFFF1F2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Kontak Darurat Keluarga',
                      subtitle: '$_emergencyContactName • $_emergencyContactPhone ($_emergencyContactRelation)',
                      onTap: () => _showEmergencyContactModal(context),
                    ),
                    const SizedBox(height: 8),
                    _buildMenuItem(
                      icon: Icons.menu_book_outlined,
                      iconBg: const Color(0xFFF8FAFC),
                      iconColor: const Color(0xFF64748B),
                      title: 'SOP Relawan & Bantuan UDD',
                      subtitle: 'Protokol penanganan donor darurat PMI',
                      onTap: () => _showSopModal(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── 8. TOMBOL AKSI BAWAH ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Tombol Unduh KTA PMI
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: () => _showKtaDigitalModal(context, userName, userBloodType, userRhesus, ktaId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.badge_outlined, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Lihat Kartu Donor Digital (KTA PMI)',
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

                    // Tombol Keluar Akun Relawan
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Konfirmasi Keluar', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                              content: Text('Apakah Anda yakin ingin keluar dari akun relawan?', style: GoogleFonts.plusJakartaSans()),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: Text('Batal', style: GoogleFonts.plusJakartaSans()),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
                                  child: Text('Keluar', style: GoogleFonts.plusJakartaSans()),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _authRepo.logout();
                            if (context.mounted) {
                              Navigator.pushReplacementNamed(context, AppRouter.loginRoute);
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          backgroundColor: const Color(0xFFF8FAFC),
                          foregroundColor: const Color(0xFFDC2626),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Text(
                              'Keluar Akun Relawan',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper: Vital Sign Box ───
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

  // ─── Helper: Menu List Item ───
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
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MODAL 1: E-SERTIFIKAT & PIAGAM PENGHARGAAN
  // ─────────────────────────────────────────────────────────────
  void _showCertificateModal(BuildContext context, String name, String bloodType, int totalDonations, int totalVolumeMl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 24),
                const SizedBox(width: 8),
                Text(
                  'Piagam Penghargaan Relawan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.08),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.shield_rounded, color: Color(0xFFDC2626), size: 36),
                  const SizedBox(height: 6),
                  Text(
                    'PALANG MERAH INDONESIA',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFDC2626),
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'KABUPATEN LAMONGAN',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF78350F),
                    ),
                  ),
                  const Divider(height: 20, color: Color(0xFFFDE68A)),
                  Text(
                    'PIAGAM PENGHARGAAN DONOR DARAH',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nomor: PMI-LMG/2026/0847',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: const Color(0xFFB45309),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Diberikan dengan hormat dan apresiasi kepada:',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF451A03),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    name.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalDonations > 0
                        ? 'Atas dedikasi mulia dan ketulusan hati sebagai Pendonor Darah Sukarela Golongan $bloodType sebanyak $totalDonations Kali ($totalVolumeMl mL) demi kemanusiaan dan menyelamatkan kehidupan sesama.'
                        : 'Atas kesiapan dan komitmen mulia sebagai Relawan Donor Darah Siaga Golongan $bloodType UTD PMI Kabupaten Lamongan.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF78350F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Donasi:', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF92400E))),
                          Text('$totalDonations Kali ($totalVolumeMl mL)', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Status Verifikasi:', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF92400E))),
                          Text('Tervalidasi PMI Pusat', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
                  );
                },
                icon: const Icon(Icons.history_rounded, size: 18),
                label: Text('Lihat Riwayat Donasi Lengkap', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MODAL 2: HASIL SKRINING IMLTD & UJI LAB
  // ─────────────────────────────────────────────────────────────
  void _showLabScreeningModal(BuildContext context, String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Row(
              children: [
                const Icon(Icons.biotech_rounded, color: Color(0xFF16A34A), size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hasil Uji Saring IMLTD & Lab',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'UTD PMI Cabang Kabupaten Lamongan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Semua parameter infeksi dinyatakan NON-REAKTIF. Darah aman untuk transfusi.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF15803D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Rincian Parameter Uji Saring Darah:',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            _buildLabRow('HIV 1 & 2', 'Antibodi / Antigen p24', 'NON-REAKTIF'),
            _buildLabRow('Hepatitis B', 'HBsAg (Surface Antigen)', 'NON-REAKTIF'),
            _buildLabRow('Hepatitis C', 'Anti-HCV', 'NON-REAKTIF'),
            _buildLabRow('Sifilis', 'TP Rapid / Treponema Pallidum', 'NON-REAKTIF'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: Color(0xFF64748B), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Standar Uji: Permenkes RI No. 91/2015 • Lab UTD PMI Lamongan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
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

  Widget _buildLabRow(String title, String method, String result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                Text(method, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF64748B))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              result,
              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF16A34A)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MODAL 3: PENGATURAN RADIUS GEOFENCING
  // ─────────────────────────────────────────────────────────────
  void _showGeofenceSettingsModal(BuildContext context) {
    double tempRadius = _geofenceRadiusKm;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              Row(
                children: [
                  const Icon(Icons.radar_rounded, color: Color(0xFF4F46E5), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Pengaturan Radius Geofencing',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tentukan jarak jangkauan radar alarm siaga Anda terhadap lokasi rumah sakit/faskes di Lamongan.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 18),
              Center(
                child: Column(
                  children: [
                    Text(
                      '${tempRadius.toStringAsFixed(1)} KM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                    Text(
                      'Radius Pantau Permohonan Darah Darurat',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Slider(
                value: tempRadius,
                min: 1.0,
                max: 20.0,
                divisions: 38,
                activeColor: const Color(0xFF4F46E5),
                inactiveColor: const Color(0xFFE0E7FF),
                onChanged: (val) {
                  setModalState(() => tempRadius = val);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1.0 km', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF94A3B8))),
                  Text('10.0 km', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF94A3B8))),
                  Text('20.0 km', style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 12),
              // Preset Cepat
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [3.0, 5.0, 10.0, 15.0].map((preset) {
                  final isSelected = (tempRadius - preset).abs() < 0.3;
                  return ChoiceChip(
                    label: Text('${preset.toInt()} km'),
                    selected: isSelected,
                    selectedColor: const Color(0xFF4F46E5),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setModalState(() => tempRadius = preset);
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _geofenceRadiusKm = tempRadius;
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Radius geofencing diperbarui menjadi ${_geofenceRadiusKm.toStringAsFixed(1)} km.'),
                        backgroundColor: const Color(0xFF4F46E5),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Simpan Radius', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MODAL 4: KONTAK DARURAT KELUARGA
  // ─────────────────────────────────────────────────────────────
  void _showEmergencyContactModal(BuildContext context) {
    final nameCtrl = TextEditingController(text: _emergencyContactName);
    final relCtrl = TextEditingController(text: _emergencyContactRelation);
    final phoneCtrl = TextEditingController(text: _emergencyContactPhone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
              Row(
                children: [
                  const Icon(Icons.contact_phone_rounded, color: Color(0xFFDC2626), size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Kontak Darurat Keluarga',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Dihubungi PMI bila terjadi kondisi darurat atau verifikasi relawan siaga.',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Nama Lengkap Kontak',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: relCtrl,
                decoration: InputDecoration(
                  labelText: 'Hubungan Keluarga (Istri, Suami, dll)',
                  prefixIcon: const Icon(Icons.family_restroom, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Nomor HP / WhatsApp',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (nameCtrl.text.trim().isNotEmpty) _emergencyContactName = nameCtrl.text.trim();
                      if (relCtrl.text.trim().isNotEmpty) _emergencyContactRelation = relCtrl.text.trim();
                      if (phoneCtrl.text.trim().isNotEmpty) _emergencyContactPhone = phoneCtrl.text.trim();
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Kontak darurat berhasil diperbarui!'),
                        backgroundColor: Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Simpan Kontak', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MODAL 5: SOP RELAWAN & BANTUAN UDD
  // ─────────────────────────────────────────────────────────────
  void _showSopModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
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
            Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: Color(0xFFDC2626), size: 24),
                const SizedBox(width: 8),
                Text(
                  'SOP & Panduan Relawan PMI',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSopStep('1', 'Panggilan Darurat', 'Pastikan tubuh dalam kondisi fit, tidur min. 5 jam, dan telah makan sebelum merespons panggilan.'),
            _buildSopStep('2', 'Penerbitan Tiket Fast-Track', 'Tekan "Bantu Sekarang" untuk mendapatkan kode tiket triase IGD prioritas tanpa antre umum.'),
            _buildSopStep('3', 'Kedatangan di Faskes', 'Tunjukkan KTA PMI dan Tiket Penugasan di ruang skrining donor darah UTD/RS.'),
            _buildSopStep('4', 'Konfirmasi Selesai', 'Setelah pengambilan kantong darah selesai, tekan "Sampai di Lokasi" untuk update status sistem.'),
            const SizedBox(height: 14),
            InkWell(
              onTap: () {
                UrlHelper.makePhoneCall(context, '(0322) 321718');
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.phone_in_talk_rounded, color: Color(0xFFDC2626), size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hotline UTD PMI Lamongan 24 Jam (Ketuk untuk Panggil):', style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF991B1B))),
                          Text('(0322) 321718 • Jl. Kusuma Bangsa Lamongan', style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: const Color(0xFFDC2626))),
                        ],
                      ),
                    ),
                    const Icon(Icons.call_made_rounded, color: Color(0xFFDC2626), size: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
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

  Widget _buildSopStep(String num, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                Text(desc, style: GoogleFonts.plusJakartaSans(fontSize: 10.5, color: const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // MODAL 6: KARTU TANDA ANGGOTA (KTA) DIGITAL PMI
  // ─────────────────────────────────────────────────────────────
  void _showKtaDigitalModal(BuildContext context, String name, String bloodType, String rhesus, String ktaId) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'KTA Digital PMI',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // CARD KTA UTAMA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF991B1B), Color(0xFFDC2626)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header KTA
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.water_drop_rounded, color: Color(0xFFDC2626), size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PALANG MERAH INDONESIA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.6,
                              ),
                            ),
                            Text(
                              'KABUPATEN LAMONGAN • UTD RESMI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'KTA RESMI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Body KTA (Foto Profil WA Kosong + Data Diri)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // FOTO PROFIL WA KOSONG (Default Silhouette Avatar)
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 50,
                              color: Color(0xFF94A3B8), // Warna siluet abu-abu default WA
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.toUpperCase(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: $ktaId',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // Badge Golongan Darah
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.bloodtype_rounded, size: 12, color: Color(0xFFDC2626)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Gol. $bloodType$rhesus',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w900,
                                            color: const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  // Badge Status Relawan
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'AKTIF',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
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
                    const Divider(height: 1, color: Colors.white24),
                    const SizedBox(height: 8),

                    // Footer KTA
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Masa Berlaku: Seumur Hidup',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.qr_code_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'VERIFIKASI PMI',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('KTA Digital PMI berhasil disimpan ke galeri dokumen Anda!'),
                        backgroundColor: Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('Simpan KTA Digital', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
