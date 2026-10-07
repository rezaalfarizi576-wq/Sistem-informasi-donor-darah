import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/blood_request_repository.dart';
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

  UserModel? _currentUser;
  BloodRequestModel? _urgentRequest;
  bool _isLoading = true;

  // Bank Darah tab state
  String _bankSelectedFilter = 'Semua';
  String _reservasiLocation = 'UTD PMI Cabang Lamongan';
  DateTime _reservasiDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _reservasiTime = const TimeOfDay(hour: 10, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepo.getCurrentUser();
      final requests = await _requestRepo.getRequests();

      // Cari permintaan paling urgent
      BloodRequestModel? urgentReq;
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

      if (mounted) {
        setState(() {
          _currentUser = user;
          _urgentRequest = urgentReq;
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
    final distance = req != null ? req.radiusKm.toStringAsFixed(1) : '2.5';
    final eta = req != null
        ? '${(req.radiusKm * 4).round().clamp(5, 45)}'
        : '15';
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
    return Column(
      children: [
        Row(
          children: [
            // Card 1: Total Donor
            Expanded(
              child: _buildSingleStatCard(
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFFD32F2F),
                value: '3.2 L',
                title: 'Total Donor',
                subtitle: '8 kali donasi',
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
            // Card 3: Donor Terakhir
            Expanded(
              child: _buildSingleStatCard(
                icon: Icons.calendar_month_rounded,
                iconColor: const Color(0xFF3B82F6),
                value: '12 Mar',
                title: 'Donor Terakhir',
                subtitle: '2025',
              ),
            ),
            const SizedBox(width: 12),
            // Card 4: Status PMI
            Expanded(
              child: _buildSingleStatCard(
                icon: Icons.workspace_premium_rounded,
                iconColor: const Color(0xFFF59E0B),
                value: 'Relawan A',
                title: 'Status PMI',
                subtitle: 'Verified Aktif',
                subtitleColor: const Color(0xFF16A34A),
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
            // Informasi Riwayat
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PMI Cabang Surabaya',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '12 Maret 2025 • 350 ml',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            // Badge Berhasil
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Berhasil',
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
  // TAB 3: MENU BANK DARAH (REFERENSI DESAIN BARU)
  // ─────────────────────────────────────────────────────────────
  Widget _buildPmiBankView() {
    final List<String> filters = ['Semua', 'A+', 'B+', 'O+', 'AB+', 'A-', 'B-', 'O-', 'AB-'];

    // Data stok golongan darah
    final List<_BloodStockData> stockData = [
      _BloodStockData('A+', 42, '#1', const Color(0xFF16A34A), false),
      _BloodStockData('B+', 38, '#2', const Color(0xFF16A34A), false),
      _BloodStockData('O+', 24, '#3', const Color(0xFFEF4444), false),
      _BloodStockData('AB+', 17, '#4', const Color(0xFFF59E0B), false),
    ];

    // Data fasilitas
    final List<_FasilitasData> fasilitas = [
      _FasilitasData('UTD PMI Cabang Lamongan', 'Jl. Kusuma Bangsa No. 25, Lamongan', 88, true),
      _FasilitasData('BDRS RSUD Dr. Soegiri Lamongan', 'Jl. Kusuma Bangsa No. 7, Lamongan', 14, false),
      _FasilitasData('BDRS RS Muhammadiyah Lamongan', 'Jl. Jaksa Agung Suprapto No. 76', 29, false),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 110,
            pinned: true,
            backgroundColor: const Color(0xFFD32F2F),
            elevation: 0,
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFB71C1C), Color(0xFFD32F2F), Color(0xFFE53935)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: PMI Lamongan + sync icon + timer
                        Row(
                          children: [
                            const Icon(Icons.account_balance_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Menu Bank Darah',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.sync_rounded, color: Colors.white, size: 13),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Row 2: Live Sync badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
                              ),
                              child: Row(
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
                                    'Live Sync • Faskes Lamongan',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '5 detik lalu',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.65),
                                fontSize: 10,
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
            // Search bar pinned
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: const Color(0xFFD32F2F),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Cari golongan darah, faskes...',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.tune_rounded, color: Color(0xFFD32F2F), size: 17),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── FILTER CHIPS GOLONGAN DARAH ──
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final f = filters[i];
                    final selected = _bankSelectedFilter == f;
                    return GestureDetector(
                      onTap: () => setState(() => _bankSelectedFilter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected ? const Color(0xFFD32F2F) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? const Color(0xFFD32F2F) : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: selected
                              ? [BoxShadow(color: const Color(0xFFD32F2F).withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Text(
                          f,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // ── ALERT DARURAT ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: const Color(0xFFD32F2F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emergency_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BUTUH GOLONGAN DARAH O+ (3 Kantong)',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Detail',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFFD32F2F),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── STOK DONOR TERSEDIA ──
              _buildBankSectionHeader('Stok Donor Tersedia Lamongan', 'Tapi 10 Pend'),
              const SizedBox(height: 10),

              // 2x2 stok grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5,
                children: stockData.map((s) => _buildBloodStockCard(s)).toList(),
              ),

              const SizedBox(height: 14),

              // ── RHESUS NEGATIF UNIT ──
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bloodtype_rounded, color: Color(0xFF475569), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rhensius Negatif Unit',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Semua Golongan Rh-',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
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
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFD32F2F),
                            height: 1,
                          ),
                        ),
                        Text(
                          'kantong',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── DIREKTORI FASILITAS & BDRS ──
              _buildBankSectionHeader('Direktori Fasilitas & BDRS', '${fasilitas.length} Fasilitas Terhubung'),
              const SizedBox(height: 10),

              ...fasilitas.map((f) => _buildFasilitasCard(f)).toList(),

              const SizedBox(height: 16),

              // ── RESERVASI DONOR SUKARELA ──
              _buildBankSectionHeader('Reservasi Donor Sukarela', null),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Pilih lokasi
                    _buildReservasiRow(
                      Icons.location_on_rounded,
                      const Color(0xFFD32F2F),
                      'PMI Tempat',
                      _reservasiLocation,
                      onTap: () async {
                        final List<String> lokasi = [
                          'UTD PMI Cabang Lamongan',
                          'BDRS RSUD Dr. Soegiri Lamongan',
                          'BDRS RS Muhammadiyah Lamongan',
                        ];
                        final picked = await showDialog<String>(
                          context: context,
                          builder: (_) => SimpleDialog(
                            title: Text('Pilih Lokasi', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                            children: lokasi
                                .map((l) => SimpleDialogOption(
                                      onPressed: () => Navigator.pop(context, l),
                                      child: Text(l, style: GoogleFonts.plusJakartaSans()),
                                    ))
                                .toList(),
                          ),
                        );
                        if (picked != null) setState(() => _reservasiLocation = picked);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // Pilih tanggal
                    _buildReservasiRow(
                      Icons.calendar_today_rounded,
                      const Color(0xFF3B82F6),
                      'Tanggal',
                      '${_reservasiDate.day.toString().padLeft(2, '0')}/${_reservasiDate.month.toString().padLeft(2, '0')}/${_reservasiDate.year}',
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _reservasiDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFFD32F2F)),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _reservasiDate = picked);
                      },
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    // Pilih waktu
                    _buildReservasiRow(
                      Icons.access_time_rounded,
                      const Color(0xFF8B5CF6),
                      'Waktu',
                      '${_reservasiTime.hour.toString().padLeft(2, '0')}:${_reservasiTime.minute.toString().padLeft(2, '0')}',
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: _reservasiTime,
                          builder: (context, child) => Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(primary: Color(0xFFD32F2F)),
                            ),
                            child: child!,
                          ),
                        );
                        if (picked != null) setState(() => _reservasiTime = picked);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Tombol Konfirmasi Reservasi
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Reservasi berhasil! $_reservasiLocation, ${_reservasiDate.day}/${_reservasiDate.month}/${_reservasiDate.year} pukul ${_reservasiTime.hour.toString().padLeft(2, '0')}:${_reservasiTime.minute.toString().padLeft(2, '0')}',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volunteer_activism_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '✓ Konfirmasi Reservasi Donor',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── RIWAYAT CEPAT DONOR DARAH ──
              _buildBankSectionHeader('Riwayat Cepat Donor Darah', null),
              const SizedBox(height: 10),

              _buildRiwayatDonorCard('UTD PMI Cabang Lamongan', '12 Mar 2025', '350 ml', 'Berhasil', const Color(0xFF16A34A)),
              _buildRiwayatDonorCard('RSUD Dr. Soegiri Lamongan', '08 Nov 2024', '450 ml', 'Berhasil', const Color(0xFF16A34A)),
              _buildRiwayatDonorCard('UTD PMI Cabang Lamongan', '20 Jun 2024', '350 ml', 'Berhasil', const Color(0xFF16A34A)),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helper: section header ───
  Widget _buildBankSectionHeader(String title, String? sub) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        if (sub != null) ...[
          const Spacer(),
          Text(
            sub,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  // ─── Helper: blood stock card ───
  Widget _buildBloodStockCard(_BloodStockData s) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: s.color.withValues(alpha: 0.06),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: s.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  s.type,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: s.color,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  s.rank,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${s.count}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1,
            ),
          ),
          Text(
            'kantong',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10.5,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper: fasilitas card ───
  Widget _buildFasilitasCard(_FasilitasData f) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: f.isUTD ? const Color(0xFFFFF1F2) : const Color(0xFFF0F9FF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              f.isUTD ? Icons.bloodtype_rounded : Icons.local_hospital_rounded,
              color: f.isUTD ? const Color(0xFFD32F2F) : const Color(0xFF0EA5E9),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  f.address,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${f.stock}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: f.stock < 20 ? const Color(0xFFEF4444) : const Color(0xFF0F172A),
                  height: 1,
                ),
              ),
              Text(
                'kantong',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Antri ke ${f.name}', style: GoogleFonts.plusJakartaSans()),
                      backgroundColor: const Color(0xFFD32F2F),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD32F2F),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Antri',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helper: reservasi row ───
  Widget _buildReservasiRow(IconData icon, Color iconColor, String label, String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 18),
          ],
        ),
      ),
    );
  }

  // ─── Helper: riwayat donor card ───
  Widget _buildRiwayatDonorCard(String faskes, String tanggal, String volume, String status, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFFD32F2F), size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  faskes,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$tanggal • $volume',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
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

// ─── Data model helpers untuk Bank Darah tab ───

class _BloodStockData {
  final String type;
  final int count;
  final String rank;
  final Color color;
  final bool isCritical;

  const _BloodStockData(this.type, this.count, this.rank, this.color, this.isCritical);
}

class _FasilitasData {
  final String name;
  final String address;
  final int stock;
  final bool isUTD;

  const _FasilitasData(this.name, this.address, this.stock, this.isUTD);
}

