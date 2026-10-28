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
import 'donor_dispatch_screen.dart';
import 'donor_profile_screen.dart';
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

  // Bank Darah tab state
  String _bankSelectedFilter = 'Semua';
  String _bankSelectedComponent = 'SEMUA KOMPONEN';
  String _selectedDonorBloodType = 'O';
  String _selectedSesiWaktu = '08.00 - 11.00 (Pagi)';
  DateTime _reservasiDate = DateTime.now().add(const Duration(days: 1));
  final TextEditingController _searchBankController = TextEditingController();
  String _searchBankQuery = '';

  @override
  void dispose() {
    _searchBankController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepo.getCurrentUser();

      // Safeguard: Jika role adalah peminta (requester), alihkan ke dashboard peminta
      if (user != null && user.role.toLowerCase() == 'requester') {
        if (mounted) {
          Navigator.pushReplacementNamed(context, AppRouter.requesterRequestRoute);
          return;
        }
      }

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
          DonorDispatchScreen(
            onNavigateToRadar: () => setState(() => _currentTabIndex = 0),
            onNavigateToBank: () => setState(() => _currentTabIndex = 2),
            onNavigateToProfile: () => setState(() => _currentTabIndex = 3),
          ),
          _buildPmiBankView(),
          DonorProfileScreen(
            currentUser: _currentUser,
          ),
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
        : 'Pendonor';

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
  // TAB 3: MENU BANK DARAH (PERSIS SESUAI REFERENSI DESAIN USER)
  // ─────────────────────────────────────────────────────────────
  Widget _buildPmiBankView() {
    final bloodFilters = ['Semua', 'A+', 'B+', 'O+', 'AB+', 'Rh-'];
    final compFilters = [
      'SEMUA KOMPONEN',
      'WB (WHOLE BLOOD)',
      'PRC (SEL MERAH)',
      'TC (TROMBOSIT)',
    ];

    // Ambil stok dinamis dari backend jika tersedia
    int getStockCount(String type, int defaultVal) {
      if (_bloodStock != null && _bloodStock!.stocks.isNotEmpty) {
        final cleanType = type.replaceAll('+', '').replaceAll('-', '');
        final cleanRhesus = type.contains('-') ? '-' : '+';
        final match = _bloodStock!.stocks.where(
          (s) => s.bloodType.toUpperCase() == cleanType && s.rhesus == cleanRhesus,
        );
        if (match.isNotEmpty) return match.first.bags;
      }
      return defaultVal;
    }

    final countA = getStockCount('A+', 42);
    final countB = getStockCount('B+', 18);
    final countO = getStockCount('O+', 4);
    final countAB = getStockCount('AB+', 24);

    // Data 4 Golongan Darah Terpadu
    final List<_BloodStockData> stockList = [
      _BloodStockData(
        type: 'A+',
        count: countA,
        status: countA > 20 ? 'AMAN' : (countA > 10 ? 'WASPADA' : 'DEFISIT'),
        statusBg: countA > 20 ? const Color(0xFFDCFCE7) : (countA > 10 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
        statusTextColor: countA > 20 ? const Color(0xFF16A34A) : (countA > 10 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
        progress: (countA / 50).clamp(0.05, 1.0),
        barColor: countA > 20 ? const Color(0xFF16A34A) : (countA > 10 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
        isDeficit: countA <= 10,
        components: 'WB: 18 • PRC: 20 • TC: 4',
        capacityText: '${((countA / 50) * 100).toInt()}% Kapasitas',
        target: 50,
      ),
      _BloodStockData(
        type: 'B+',
        count: countB,
        status: countB > 20 ? 'AMAN' : (countB > 10 ? 'WASPADA' : 'DEFISIT'),
        statusBg: countB > 20 ? const Color(0xFFDCFCE7) : (countB > 10 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
        statusTextColor: countB > 20 ? const Color(0xFF16A34A) : (countB > 10 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
        progress: (countB / 35).clamp(0.05, 1.0),
        barColor: countB > 20 ? const Color(0xFF16A34A) : (countB > 10 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
        isDeficit: countB <= 10,
        components: 'WB: 8 • PRC: 7 • TC: 3',
        capacityText: '${((countB / 35) * 100).toInt()}% Kapasitas',
        target: 35,
      ),
      _BloodStockData(
        type: 'O+',
        count: countO,
        status: countO > 20 ? 'AMAN' : (countO > 10 ? 'WASPADA' : 'KRITIS'),
        statusBg: countO > 20 ? const Color(0xFFDCFCE7) : (countO > 10 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
        statusTextColor: countO > 20 ? const Color(0xFF16A34A) : (countO > 10 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
        progress: (countO / 40).clamp(0.05, 1.0),
        barColor: countO > 20 ? const Color(0xFF16A34A) : (countO > 10 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
        isDeficit: true,
        components: 'WB: 1 • PRC: 2 • TC: 1',
        capacityText: '${((countO / 40) * 100).toInt()}% Kapasitas',
        target: 40,
      ),
      _BloodStockData(
        type: 'AB+',
        count: countAB,
        status: countAB > 20 ? 'AMAN' : (countAB > 10 ? 'WASPADA' : 'DEFISIT'),
        statusBg: countAB > 20 ? const Color(0xFFDCFCE7) : (countAB > 10 ? const Color(0xFFFEF3C7) : const Color(0xFFFEE2E2)),
        statusTextColor: countAB > 20 ? const Color(0xFF16A34A) : (countAB > 10 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
        progress: (countAB / 30).clamp(0.05, 1.0),
        barColor: countAB > 20 ? const Color(0xFF16A34A) : (countAB > 10 ? const Color(0xFFD97706) : const Color(0xFFDC2626)),
        isDeficit: countAB <= 10,
        components: 'WB: 10 • PRC: 11 • TC: 3',
        capacityText: '${((countAB / 30) * 100).toInt()}% Kapasitas',
        target: 30,
      ),
    ];

    // Data Direktori Faskes & BDRS
    final List<_FasilitasData> faskesList = [
      const _FasilitasData(
        name: 'UTD PMI Cabang Lamongan',
        address: 'Jl. Veteran No. 43, Jetis, Lamongan • 1.2 km',
        stock: 88,
        badgeText: 'PUSAT UTD',
        badgeBg: Color(0xFFFEF3C7),
        badgeTextColor: Color(0xFFD97706),
        hours: 'Buka 24 Jam',
        components: ['WB: 34', 'PRC: 41', 'TC: 13'],
      ),
      const _FasilitasData(
        name: 'BDRS RSUD Dr. Soegiri Lamongan',
        address: 'Jl. Kusuma Bangsa No. 7, Lamongan • 2.5 km',
        stock: 14,
        badgeText: 'KRITIS (O+)',
        badgeBg: Color(0xFFFEE2E2),
        badgeTextColor: Color(0xFFDC2626),
        hours: 'Buka 24 Jam',
        components: ['WB: 4', 'PRC (O+): 1', 'TC: 7'],
        isCritical: true,
      ),
      const _FasilitasData(
        name: 'BDRS RS Muhammadiyah Lamor',
        address: 'Jl. Jaksa Agung Suprapto No. 76 • 4.1 km',
        stock: 29,
        badgeText: 'RUMAH SAKIT',
        badgeBg: Color(0xFFE0E7FF),
        badgeTextColor: Color(0xFF4338CA),
        hours: '07.00 - 21.00',
        components: ['WB: 10', 'PRC: 15', 'TC: 4'],
      ),
    ];

    // Filter daftar faskes sesuai pilihan chip & search query
    final filteredFaskes = faskesList.where((f) {
      // 1. Filter Rh- (khusus Pusat UTD)
      if (_bankSelectedFilter == 'Rh-') {
        if (!f.badgeText.contains('PUSAT UTD')) return false;
      }

      // 2. Filter Komponen Darah
      if (_bankSelectedComponent != 'SEMUA KOMPONEN') {
        final compKey = _bankSelectedComponent.startsWith('WB')
            ? 'WB'
            : _bankSelectedComponent.startsWith('PRC')
                ? 'PRC'
                : 'TC';
        if (!f.components.any((c) => c.toUpperCase().contains(compKey))) {
          return false;
        }
      }

      // 3. Filter Text Pencarian
      if (_searchBankQuery.isNotEmpty) {
        final q = _searchBankQuery.toLowerCase();
        final matchName = f.name.toLowerCase().contains(q);
        final matchAddr = f.address.toLowerCase().contains(q);
        final matchComp = f.components.any((c) => c.toLowerCase().contains(q));
        if (!matchName && !matchAddr && !matchComp) return false;
      }

      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              // ── 1. TOP HEADER (PMI LAMONGAN Blood Bank) ──
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
                          'Blood Bank',
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
                    // Notifikasi bell icon dengan badge merah
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
                    // Profile Avatar bulat merah tua
                    GestureDetector(
                      onTap: () {
                        setState(() => _currentTabIndex = 3);
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: Color(0xFF991B1B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // ── 2. SUB BAR: LIVE SYNC & STATUS ──
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
                      'Live Sync UTD & Faskes Lamongan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF334155),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '5 mnt lalu',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // ── 3. SEARCH BAR ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _searchBankQuery.isNotEmpty
                        ? const Color(0xFFDC2626)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchBankController,
                        onChanged: (val) => setState(() => _searchBankQuery = val.trim()),
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Cari faskes, BDRS, atau komponen darah...',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFF94A3B8),
                            fontSize: 12.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchBankQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchBankController.clear();
                          setState(() => _searchBankQuery = '');
                        },
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                      ),
                  ],
                ),
              ),

              // ── 4. FILTER GOLONGAN DARAH CHIPS ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: bloodFilters.map((f) {
                    final selected = _bankSelectedFilter == f;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _bankSelectedFilter = f;
                            if (f != 'Semua' && f != 'Rh-') {
                              _selectedDonorBloodType = f.replaceAll('+', '').replaceAll('-', '');
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                f,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: selected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                              if (f == 'O+') ...[
                                const SizedBox(width: 5),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: selected ? Colors.white : const Color(0xFFDC2626),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── 5. FILTER KOMPONEN DARAH CHIPS ──
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: compFilters.map((comp) {
                    final selected = _bankSelectedComponent == comp;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _bankSelectedComponent = comp),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                          decoration: BoxDecoration(
                            color: selected ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            comp,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: selected ? Colors.white : const Color(0xFF64748B),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── 6. BANNER KONDISI SIAGA KRITIS (MERAH) ──
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'KONDISI SIAGA KRITIS',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stok Golongan O+ Menipis (< 5 Kantong)',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kebutuhan mendesak di BDRS RSUD Dr. Soegiri untuk pasien gawat darurat & operasi bedah.',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              'Target: 15 Pendonor Hari ini',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _bankSelectedFilter = 'O+';
                              _selectedDonorBloodType = 'O';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Golongan darah O dipilih untuk reservasi donor!',
                                  style: GoogleFonts.plusJakartaSans(),
                                ),
                                backgroundColor: const Color(0xFFDC2626),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFDC2626),
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Donor Sekarang',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFFDC2626)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── 7. STOK DARAH TERPADU LAMONGAN ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Stok Darah Terpadu Lamongan',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'LIVE',
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
                            'Agregasi stok UTD PMI Cabang & BDRS RSUD Dr. Soegiri Lamongan',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_bankSelectedFilter != 'Semua')
                      GestureDetector(
                        onTap: () => setState(() => _bankSelectedFilter = 'Semua'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Reset ($_bankSelectedFilter)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.close_rounded, size: 14, color: Color(0xFFDC2626)),
                            ],
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bloodtype_outlined, size: 14, color: Color(0xFFDC2626)),
                            const SizedBox(width: 5),
                            Text(
                              'Total: ${_bloodStock?.totalBags ?? 105} Kantong',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF0F172A),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Responsive Grid Stok Darah (4 Columns Desktop/Tablet, 2 Columns Mobile)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, cardConstraints) {
                    final isDesktop = cardConstraints.maxWidth >= 680;
                    final crossAxisCount = isDesktop ? 4 : 2;
                    final aspectRatio = isDesktop ? 1.40 : 1.15;

                    return GridView.count(
                      crossAxisCount: crossAxisCount,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: aspectRatio,
                      children: stockList.map((s) {
                        final isSelected = _bankSelectedFilter == s.type;
                        final isDimmed = _bankSelectedFilter != 'Semua' && !isSelected;
                        return _buildExactBloodStockCard(
                          s,
                          isSelected: isSelected,
                          isDimmed: isDimmed,
                          onTap: () {
                            setState(() {
                              _bankSelectedFilter = isSelected ? 'Semua' : s.type;
                              if (_bankSelectedFilter != 'Semua' && _bankSelectedFilter != 'Rh-') {
                                _selectedDonorBloodType = s.type.replaceAll('+', '').replaceAll('-', '');
                              }
                            });
                          },
                        );
                      }).toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Card Rhesus Negatif (All)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _bankSelectedFilter = _bankSelectedFilter == 'Rh-' ? 'Semua' : 'Rh-';
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _bankSelectedFilter == 'Rh-' ? const Color(0xFFFAF5FF) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _bankSelectedFilter == 'Rh-'
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFE2E8F0),
                        width: _bankSelectedFilter == 'Rh-' ? 2 : 1.2,
                      ),
                      boxShadow: _bankSelectedFilter == 'Rh-'
                          ? [
                              BoxShadow(
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                    ),
                    child: Opacity(
                      opacity: (_bankSelectedFilter != 'Semua' && _bankSelectedFilter != 'Rh-') ? 0.45 : 1.0,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'Rh-',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Rhesus Negatif (Rh-)',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13.5,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEDE9FE),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _bankSelectedFilter == 'Rh-' ? 'DIPILIH' : 'LANGKA (~0.5%)',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF7C3AED),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'A-: 0 • B-: 1 • O-: 1 • AB-: 0 • Pengelolaan Khusus UTD PMI Lamongan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '02',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF5B21B6),
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Kantong',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (_bankSelectedFilter != 'Semua')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Menampilkan ketersediaan & faskes untuk Golongan $_bankSelectedFilter',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 18),

              // ── 8. DIREKTORI FASKES & BDRS ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(
                  children: [
                    Text(
                      'Direktori Faskes & BDRS',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${filteredFaskes.length} Faskes Terkoneksi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFFDC2626),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: filteredFaskes.isEmpty
                    ? Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded, size: 40, color: Color(0xFF94A3B8)),
                            const SizedBox(height: 10),
                            Text(
                              'Tidak Ada Faskes yang Cocok',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coba ganti kata kunci pencarian atau filter komponen di atas.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                _searchBankController.clear();
                                setState(() {
                                  _bankSelectedFilter = 'Semua';
                                  _bankSelectedComponent = 'SEMUA KOMPONEN';
                                  _searchBankQuery = '';
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Reset Semua Filter'),
                              style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: filteredFaskes
                            .map((f) => _buildExactFaskesCard(f, activeComponent: _bankSelectedComponent))
                            .toList(),
                      ),
              ),

              const SizedBox(height: 14),

              // ── 9. RESERVASI DONOR SUKARELA ──
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
                      // Header Card Reservasi
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDC2626),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reservasi Donor Sukarela',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'UTD PMI Lamongan • Jalur Cepat & Antrean Pas',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Input Tanggal & Sesi Waktu
                      Row(
                        children: [
                          // Tanggal
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _reservasiDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 30)),
                                  builder: (context, child) => Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(primary: Color(0xFFDC2626)),
                                    ),
                                    child: child!,
                                  ),
                                );
                                if (picked != null) setState(() => _reservasiDate = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pilih Tanggal',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_reservasiDate.day.toString().padLeft(2, '0')}/${_reservasiDate.month.toString().padLeft(2, '0')}/${_reservasiDate.year}',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Sesi Waktu
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final sesiList = [
                                  '08.00 - 11.00 (Pagi)',
                                  '11.00 - 14.00 (Siang)',
                                  '14.00 - 17.00 (Sore)',
                                ];
                                final picked = await showDialog<String>(
                                  context: context,
                                  builder: (_) => SimpleDialog(
                                    title: Text('Pilih Sesi Waktu', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                                    children: sesiList
                                        .map((s) => SimpleDialogOption(
                                              onPressed: () => Navigator.pop(context, s),
                                              child: Text(s, style: GoogleFonts.plusJakartaSans()),
                                            ))
                                        .toList(),
                                  ),
                                );
                                if (picked != null) setState(() => _selectedSesiWaktu = picked);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sesi Waktu',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10.5,
                                        color: const Color(0xFF64748B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _selectedSesiWaktu,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Golongan Darah Pendonor
                      Text(
                        'Golongan Darah Pendonor',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Segmented 4 Tombol: A, B, O, AB
                      Row(
                        children: ['A', 'B', 'O', 'AB'].map((type) {
                          final isSelected = _selectedDonorBloodType == type;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: GestureDetector(
                                onTap: () => setState(() => _selectedDonorBloodType = type),
                                child: Container(
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    type,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? Colors.white : const Color(0xFF334155),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                      const SizedBox(height: 16),

                      // Tombol Konfirmasi Reservasi Donor
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Reservasi Sukarela Golongan $_selectedDonorBloodType berhasil! Tanggal ${_reservasiDate.day}/${_reservasiDate.month}/${_reservasiDate.year} ($_selectedSesiWaktu).',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                ),
                                backgroundColor: const Color(0xFF16A34A),
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
                              const Icon(Icons.person_add_alt_1_rounded, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Konfirmasi Reservasi Donor',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── 10. SYARAT CEPAT DONOR DARAH ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Syarat Cepat Donor Darah',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Usia 17-60 th, BB ≥ 45 kg, Istirahat minimal 5 jam, tidak sedang minum antibiotik.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: const Color(0xFF475569),
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    ),
  ),
);
}

  // ─── Helper: exact blood stock card ───
  Widget _buildExactBloodStockCard(
    _BloodStockData s, {
    bool isSelected = false,
    bool isDimmed = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isDimmed ? 0.45 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (s.isDeficit ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4))
                : (s.isDeficit ? const Color(0xFFFFF8F8) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFFDC2626)
                  : s.isDeficit
                      ? const Color(0xFFFECACA)
                      : const Color(0xFFE2E8F0),
              width: isSelected ? 2.0 : 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.16),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Row 1: Drop Icon + Blood Type + Status Badge
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: s.isDeficit
                          ? const Color(0xFFFEE2E2)
                          : (s.status == 'AMAN' ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.water_drop_rounded,
                      size: 18,
                      color: s.isDeficit
                          ? const Color(0xFFDC2626)
                          : (s.status == 'AMAN' ? const Color(0xFF16A34A) : const Color(0xFFD97706)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.type,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: s.isDeficit ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                    ),
                  ),
                  if (isSelected) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFFDC2626)),
                  ],
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: s.statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: s.statusTextColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          s.status,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: s.statusTextColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Row 2: Large Count Number + "Kantong" + Capacity Text
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      s.count.toString().padLeft(2, '0'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: s.isDeficit ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'Kantong',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      s.capacityText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: s.isDeficit ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),

              // Row 3: Modern Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: s.progress,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(s.barColor),
                  minHeight: 5,
                ),
              ),

              // Row 4: Component Breakdown or Deficit Tag
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: s.isDeficit
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text(
                              'Darurat • Butuh Pendonor',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Text(
                        s.components,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper: exact faskes card ───
  Widget _buildExactFaskesCard(_FasilitasData f, {String activeComponent = 'SEMUA KOMPONEN'}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges row: Type badge + hours
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: f.badgeBg,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            f.badgeText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: f.badgeTextColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          f.hours,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      f.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      f.address,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Kantong Badge Box
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: f.isCritical ? const Color(0xFFFEE2E2) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      '${f.stock}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: f.isCritical ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                        height: 1,
                      ),
                    ),
                    Text(
                      'KANTONG',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: f.isCritical ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Component tags row + Action buttons
          Row(
            children: [
              // Components
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: f.components.map((c) {
                    final compKey = activeComponent.startsWith('WB')
                        ? 'WB'
                        : activeComponent.startsWith('PRC')
                            ? 'PRC'
                            : activeComponent.startsWith('TC')
                                ? 'TC'
                                : '';
                    final isFilterMatch = compKey.isNotEmpty && c.toUpperCase().contains(compKey);
                    final isHighlighted = c.contains('(O+)') || isFilterMatch;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isHighlighted ? const Color(0xFFFEE2E2) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                          color: isHighlighted ? const Color(0xFFFECACA) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        c,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isHighlighted ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Action buttons (Phone & Arah)
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: IconButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Menghubungi ${f.name}...', style: GoogleFonts.plusJakartaSans()),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.phone_outlined, size: 15, color: Color(0xFF475569)),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Membuka rute ke ${f.name}...', style: GoogleFonts.plusJakartaSans()),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.navigation_rounded, size: 12, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            'Arah',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2563EB),
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
        ],
      ),
    );
  }
}

// ─── Data model helpers untuk Bank Darah tab ───

class _BloodStockData {
  final String type;
  final int count;
  final String status;
  final Color statusBg;
  final Color statusTextColor;
  final double progress;
  final Color barColor;
  final bool isDeficit;
  final String components;
  final String capacityText;
  final int target;

  const _BloodStockData({
    required this.type,
    required this.count,
    required this.status,
    required this.statusBg,
    required this.statusTextColor,
    required this.progress,
    required this.barColor,
    this.isDeficit = false,
    this.components = '',
    this.capacityText = '',
    this.target = 50,
  });
}

class _FasilitasData {
  final String name;
  final String address;
  final int stock;
  final String badgeText;
  final Color badgeBg;
  final Color badgeTextColor;
  final String hours;
  final List<String> components;
  final bool isCritical;

  const _FasilitasData({
    required this.name,
    required this.address,
    required this.stock,
    required this.badgeText,
    required this.badgeBg,
    required this.badgeTextColor,
    required this.hours,
    required this.components,
    this.isCritical = false,
  });
}

