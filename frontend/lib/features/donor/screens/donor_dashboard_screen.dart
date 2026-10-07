import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/blood_stock_model.dart';
import '../../../data/models/donor_stats_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../data/repositories/donor_repository.dart';
import '../../../routes/app_router.dart';
import 'donation_history_screen.dart';
import 'notification_screen.dart';

class DonorDashboardScreen extends StatefulWidget {
  const DonorDashboardScreen({super.key});

  @override
  State<DonorDashboardScreen> createState() => _DonorDashboardScreenState();
}

class _DonorDashboardScreenState extends State<DonorDashboardScreen> {
  int _currentTabIndex = 0;
  final _authRepo = AuthRepository();
  final _requestRepo = BloodRequestRepository();
  final _donorRepo = DonorRepository();

  UserModel? _currentUser;
  BloodRequestModel? _urgentRequest;
  DonorStatsModel? _donorStats;
  BloodStockResponseModel? _bloodStock;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepo.getCurrentUser();

      // Ambil posisi GPS donor (atau fallback Lamongan)
      double donorLat = -7.126500;
      double donorLng = 112.418200;
      try {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          donorLat = pos.latitude;
          donorLng = pos.longitude;
        }
      } catch (_) {}

      // Saring permohonan darah yang berada dalam radius 5 - 10 km dari donor
      List<BloodRequestModel> nearby = [];
      try {
        nearby = await _requestRepo.getNearbyRequests(
          lat: donorLat,
          lng: donorLng,
          maxRadius: 10.0,
        );
      } catch (_) {}

      // Cari permintaan paling urgent
      BloodRequestModel? urgentReq;
      if (nearby.isNotEmpty) {
        urgentReq = nearby.first;
      } else {
        final requests = await _requestRepo.getRequests();
        if (requests.isNotEmpty) {
          urgentReq = requests.firstWhere(
            (r) =>
                r.status == 'diproses' ||
                r.status == 'menunggu' ||
                r.urgencyLevel == 'kritis' ||
                r.urgencyLevel == 'tinggi' ||
                r.urgencyLevel == 'urgent' ||
                r.urgencyLevel == 'critical',
            orElse: () => requests.first,
          );
        }
      }

      // Ambil statistik donor dari backend
      DonorStatsModel? stats;
      try {
        stats = await _donorRepo.getDonorStats();
      } catch (_) {}

      // Ambil stok kantong darah dari backend
      BloodStockResponseModel? stock;
      try {
        stock = await _donorRepo.getBloodStock();
      } catch (_) {}

      if (mounted) {
        setState(() {
          _currentUser = user;
          _urgentRequest = urgentReq;
          _donorStats = stats;
          _bloodStock = stock;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi,';
    if (hour < 15) return 'Selamat Siang,';
    if (hour < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildRadarView(),
          const NotificationScreen(),
          _buildPmiBankView(),
          _buildProfileView(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFFD32F2F),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.radar_rounded),
              activeIcon: Icon(Icons.radar_rounded, size: 26),
              label: 'Radar',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping_outlined),
              activeIcon: Icon(Icons.local_shipping_rounded, size: 26),
              label: 'Dispatch',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_outlined),
              activeIcon: Icon(Icons.account_balance_rounded, size: 26),
              label: 'Bank',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded, size: 26),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 1: RADAR (SESUAI DOKUMENTASI REFERENSI DESAIN USER)
  // ─────────────────────────────────────────────────────────────
  Widget _buildRadarView() {
    final userName = _currentUser?.name.isNotEmpty == true
        ? _currentUser!.name
        : 'Budi Santoso';

    final bloodType = _currentUser?.bloodType?.isNotEmpty == true
        ? '${_currentUser!.bloodType}${_currentUser!.rhesus ?? "+"}'
        : 'O+';

    final rhesusLabel = _currentUser?.rhesus == '-'
        ? 'Rhesus Negatif'
        : 'Rhesus Positif';

    return RefreshIndicator(
      color: const Color(0xFFD32F2F),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── TOP HEADER MERAH CURVED ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFD32F2F),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Greeting & Nama User
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userName,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      // Action Icons: Notifikasi & Profil
                      Row(
                        children: [
                          _buildHeaderIconButton(
                            icon: Icons.notifications_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const NotificationScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 10),
                          _buildHeaderIconButton(
                            icon: Icons.person_rounded,
                            onTap: () {
                              setState(() => _currentTabIndex = 3);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoading)
              const LinearProgressIndicator(
                backgroundColor: Colors.transparent,
                color: Color(0xFFD32F2F),
                minHeight: 2,
              ),

            // ── BODY CONTENT ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // ── KARTU PERMINTAAN DARAH DARURAT (RED BORDER) ──
                  _buildEmergencyRequestCard(),

                  const SizedBox(height: 24),

                  // ── SECTION: STATISTIK DONOR SAYA • PMI DATA ──
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'STATISTIK DONOR SAYA • PMI DATA',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // ── 2x2 STATISTIK GRID ──
                  _buildStatsGrid(bloodType, rhesusLabel),

                  const SizedBox(height: 24),

                  // ── SECTION: RIWAYAT DONASI ──
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'RIWAYAT DONASI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),

                  // ── KARTU RIWAYAT DONASI ──
                  _buildDonationHistoryCard(),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // KARTU PERMINTAAN DARURAT (RED STROKE CARD)
  // ─────────────────────────────────────────────────────────────
  Widget _buildEmergencyRequestCard() {
    // Ambil data jika tersedia dari backend atau gunakan referensi default
    final req = _urgentRequest;
    final bloodLabel = req != null ? req.bloodLabel : 'O+';
    final hospitalName = req?.hospitalName ?? 'RSUD Dr. Soegiri\nLamongan';
    final distance = req != null
        ? (req.distanceDisplay?.replaceAll(' km', '') ?? req.radiusKm.toStringAsFixed(1))
        : '1.7';
    final eta = req != null
        ? '${((req.distanceKm ?? req.radiusKm) * 2.5).round().clamp(3, 30)}'
        : '8';
    final urgencyText = req != null
        ? (req.urgencyLevel == 'kritis' || req.urgencyLevel == 'critical'
            ? 'SEGERA'
            : req.urgencyLevel.toUpperCase())
        : 'SEGERA';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFD32F2F),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header: Blood Badge & Info Rumah Sakit
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Golongan Darah Merah
              Container(
                width: 50,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  bloodLabel,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Nama Golongan Darah & Lokasi RS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Golongan Darah $bloodLabel',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hospitalName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3 Stat Boxes: Jarak, ETA, Status
          Row(
            children: [
              // Box 1: Jarak
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$distance ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            TextSpan(
                              text: 'KM',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Jarak',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Box 2: ETA
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$eta ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                            TextSpan(
                              text: 'MNT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFE65100),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ETA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Box 3: Status
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        urgencyText,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFD32F2F),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tombol Aksi "Bantu Sekarang"
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (req != null) {
                  Navigator.pushNamed(
                    context,
                    AppRouter.respondRequestRoute,
                    arguments: req,
                  );
                } else {
                  // Jika belum ada request di db, buat dummy model untuk demo respons
                  final dummy = BloodRequestModel(
                    id: 1,
                    requesterId: 1,
                    bloodType: 'O',
                    rhesus: '+',
                    bagsNeeded: 2,
                    urgencyLevel: 'kritis',
                    latitudeFaskes: -7.126500,
                    longitudeFaskes: 112.418200,
                    radiusKm: 2.5,
                    hospitalName: 'RSUD Dr. Soegiri Lamongan',
                    status: 'diproses',
                    patientName: 'Pasien IGD Darurat',
                  );
                  Navigator.pushNamed(
                    context,
                    AppRouter.respondRequestRoute,
                    arguments: dummy,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.water_drop_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Bantu Sekarang',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 2x2 STATISTIK GRID
  // ─────────────────────────────────────────────────────────────
  Widget _buildStatsGrid(String bloodType, String rhesusLabel) {
    // Gunakan data live dari backend jika tersedia
    final totalLitersDisplay = _donorStats?.totalLitersDisplay ?? '0.0 L';
    final totalDonationsDisplay = _donorStats?.totalDonationsDisplay ?? '0 kali donasi';
    final lastDonationDisplay = _donorStats?.lastDonationDisplay ?? '-';
    final lastDonationYear = _donorStats?.lastDonationYear ?? '-';
    final pmiStatus = _donorStats?.pmiStatus ?? 'Relawan Aktif';
    final isEligible = _donorStats?.eligibleToDonate ?? true;
    final statusSubtitle = isEligible ? 'Siap Donor' : 'Belum Layak';
    final statusColor = isEligible ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return Column(
      children: [
        Row(
          children: [
            // Card 1: Total Donor (dari backend)
            Expanded(
              child: _buildSingleStatCard(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFFD32F2F),
                value: totalLitersDisplay,
                title: 'Total Donor',
                subtitle: totalDonationsDisplay,
              ),
            ),
            const SizedBox(width: 12),
            // Card 2: Golongan Darah
            Expanded(
              child: _buildSingleStatCard(
                icon: Icons.favorite_rounded,
                iconColor: const Color(0xFFEF4444),
                value: bloodType,
                title: 'Golongan Darah',
                subtitle: rhesusLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 3: Donor Terakhir (dari backend)
            Expanded(
              child: _buildSingleStatCard(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF3B82F6),
                value: lastDonationDisplay,
                title: 'Donor Terakhir',
                subtitle: lastDonationYear,
              ),
            ),
            const SizedBox(width: 12),
            // Card 4: Status PMI (dari backend)
            Expanded(
              child: _buildSingleStatCard(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: pmiStatus,
                title: 'Status PMI',
                subtitle: statusSubtitle,
                subtitleColor: statusColor,
                isSubtitleBold: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    bool isSubtitleBold = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 22,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: isSubtitleBold ? FontWeight.bold : FontWeight.w400,
              color: subtitleColor ?? const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // KARTU RIWAYAT DONASI
  // ─────────────────────────────────────────────────────────────
  Widget _buildDonationHistoryCard() {
    // Gunakan data riwayat terakhir dari backend
    final latestDonation = _donorStats?.latestDonation;
    final location = latestDonation?.location ?? 'Belum ada riwayat';
    final dateInfo = latestDonation != null
        ? '${latestDonation.date} • ${latestDonation.volumeMl} ml'
        : 'Belum pernah donor';
    final status = latestDonation?.status ?? '-';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const DonationHistoryScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar Ikon Donasi
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.volunteer_activism_rounded,
                color: Color(0xFFD32F2F),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            // Informasi Riwayat (dari backend)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    dateInfo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Badge Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                status,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 3: STOK DARAH PMI (BANK)
  // ─────────────────────────────────────────────────────────────
  Widget _buildPmiBankView() {
    // Gunakan data live dari backend
    final uddName = _bloodStock?.uddInfo.name ?? 'UDD PMI Kab. Lamongan';
    final uddAddress = _bloodStock?.uddInfo.address ?? 'Jl. Kombespol M. Duryat No. 42, Jetis, Lamongan';
    final uddHours = _bloodStock?.uddInfo.operatingHours ?? 'Buka 24 Jam';
    final uddPhone = _bloodStock?.uddInfo.callCenter ?? '(0322) 321118';
    final totalBags = _bloodStock?.totalBags ?? 0;

    Color _statusColor(String status) {
      switch (status.toLowerCase()) {
        case 'aman':
          return const Color(0xFF16A34A);
        case 'waspada':
          return const Color(0xFFF59E0B);
        case 'kritis':
        case 'sangat kritis':
          return const Color(0xFFDC2626);
        default:
          return const Color(0xFF64748B);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Bank & Stok Darah PMI',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFD32F2F),
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // UDD Info Card (dari backend)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.apartment_rounded,
                        color: Color(0xFFD32F2F),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            uddName,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$uddAddress\n$uddHours • Call Center: $uddPhone',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'KETERSEDIAAN STOK KANTONG DARAH (TOTAL: $totalBags)',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 12),

              // Blood stock items (dari backend)
              if (_bloodStock != null)
                ..._bloodStock!.stocks.map((stock) => _buildStockItem(
                      stock.label,
                      stock.bags,
                      stock.status,
                      _statusColor(stock.status),
                    ))
              else ...
                [
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                    ),
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockItem(String type, int count, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1F2),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.bloodtype_rounded,
                  color: Color(0xFFD32F2F),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '$count Kantong Siap Pakai',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // TAB 4: PROFILE SAYA
  // ─────────────────────────────────────────────────────────────
  Widget _buildProfileView() {
    final userName = _currentUser?.name.isNotEmpty == true
        ? _currentUser!.name
        : 'Budi Santoso';
    final userNik = _currentUser?.nik.isNotEmpty == true
        ? _currentUser!.nik
        : '3524000000000001';
    final userPhone = _currentUser?.phone ?? '085769120001';
    final userEmail = _currentUser?.email ?? 'budi.santoso@donor-darah.id';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Profil Pendonor',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: const Color(0xFFD32F2F).withValues(alpha: 0.1),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 42,
                      color: Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Verified Relawan PMI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Detail Akun Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildProfileRow(Icons.badge_outlined, 'NIK / ID PMI', userNik),
                  const Divider(),
                  _buildProfileRow(Icons.email_outlined, 'Email', userEmail),
                  const Divider(),
                  _buildProfileRow(Icons.phone_outlined, 'No. Telepon', userPhone),
                  const Divider(),
                  _buildProfileRow(Icons.bloodtype_outlined, 'Golongan Darah', 'O+ (Rhesus Positif)'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Logout
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _authRepo.logout();
                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRouter.loginRoute,
                      (route) => false,
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  side: const BorderSide(color: Color(0xFFFCA5A5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout_rounded),
                label: Text(
                  'Keluar dari Akun',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF64748B), size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
