import 'package:flutter/material.dart';
import '../../../data/repositories/admin_repository.dart';
import '../../../data/models/user_model.dart';
import 'dart:math';

class RelawanModel {
  final String id;
  final String nama;
  final String nik;
  final int usia;
  final String goldar;
  final String rhesus;
  final String statusSiaga; // 'SIAGA', 'STANDBY', 'OFFLINE'
  final String distance;
  final String eta;
  final int totalDonor;
  final String lastDonor;
  final String kecamatan;
  final String? badge; // '★ Teladan', 'Langka'
  final String phone;
  final String healthStatus;
  final String targetHospital;
  final String avgResponseTime;
  final double donorLat;
  final double donorLng;

  const RelawanModel({
    required this.id,
    required this.nama,
    required this.nik,
    required this.usia,
    required this.goldar,
    required this.rhesus,
    required this.statusSiaga,
    required this.distance,
    required this.eta,
    required this.totalDonor,
    required this.lastDonor,
    required this.kecamatan,
    this.badge,
    required this.phone,
    required this.healthStatus,
    required this.targetHospital,
    required this.avgResponseTime,
    required this.donorLat,
    required this.donorLng,
  });

  /// Convert backend UserModel (donor) to UI RelawanModel
  factory RelawanModel.fromUser(UserModel user, int index) {
    final rng = Random(user.id);
    final statuses = ['SIAGA', 'SIAGA', 'STANDBY', 'OFFLINE'];
    final hospitals = ['RSUD DR. SOEGIRI', 'RS Muhammadiyah Lamongan', 'RSUD Karangkembang Babat'];
    final kecamatans = ['Kec. Babat, Lamongan', 'Kec. Tikung, Lamongan', 'Kec. Lamongan Kota', 'Kec. Deket, Lamongan', 'Kec. Karanggeneng, Lamongan'];
    final dist = (1.0 + rng.nextDouble() * 4.5).toStringAsFixed(1);
    final etaMin = (5 + rng.nextInt(15));
    final status = statuses[rng.nextInt(statuses.length)];
    final bloodType = user.bloodType ?? ['O', 'A', 'B', 'AB'][rng.nextInt(4)];
    final rhesus = user.rhesus ?? (rng.nextBool() ? '+' : '-');
    final isRare = rhesus == '-';

    return RelawanModel(
      id: 'REL-2025-${(index + 421).toString().padLeft(5, '0')}',
      nama: user.name,
      nik: user.nik.isNotEmpty ? user.nik : '35240${(rng.nextInt(89999999) + 10000000)}',
      usia: 20 + rng.nextInt(25),
      goldar: '$bloodType$rhesus',
      rhesus: rhesus == '+' ? 'Positif' : 'Negatif (Langka)',
      statusSiaga: status,
      distance: '$dist KM',
      eta: status == 'SIAGA' ? '$etaMin mnt ke RS' : (status == 'STANDBY' ? 'Siap dikonfirmasi' : 'Masa jeda donor'),
      totalDonor: 1 + rng.nextInt(14),
      lastDonor: '${rng.nextInt(28) + 1} ${['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep'][rng.nextInt(9)]} 2025',
      kecamatan: kecamatans[rng.nextInt(kecamatans.length)],
      badge: isRare ? 'Langka' : (rng.nextInt(5) == 0 ? '★ Teladan' : null),
      phone: user.phone ?? '+62 812-${rng.nextInt(9000) + 1000}-${rng.nextInt(9000) + 1000}',
      healthStatus: status != 'OFFLINE' ? 'Memenuhi Syarat (Fit untuk Donor)' : 'Masa Jeda Donor (Belum 60 hari)',
      targetHospital: hospitals[rng.nextInt(hospitals.length)],
      avgResponseTime: '${3 + rng.nextInt(8)} menit',
      donorLat: -7.08 - rng.nextDouble() * 0.1,
      donorLng: 112.39 + rng.nextDouble() * 0.06,
    );
  }
}

class AdminRelawanScreen extends StatefulWidget {
  const AdminRelawanScreen({super.key});

  @override
  State<AdminRelawanScreen> createState() => _AdminRelawanScreenState();
}

class _AdminRelawanScreenState extends State<AdminRelawanScreen> {
  final _searchController = TextEditingController();
  final _adminRepo = AdminRepository();
  String _selectedFilter = 'Semua';
  bool _isLoading = true;
  String? _errorMessage;

  List<RelawanModel> _allRelawan = [];

  // Fallback dummy data if API returns empty
  static const _dummyRelawan = [
    RelawanModel(
      id: 'REL-2025-00421', nama: 'Budi Santoso, S.Kom', nik: '3524052109920004',
      usia: 32, goldar: 'O+', rhesus: 'Positif', statusSiaga: 'SIAGA',
      distance: '1.8 KM', eta: '8 mnt ke RSUD', totalDonor: 8, lastDonor: '12 Mar 2025',
      kecamatan: 'Kec. Babat, Lamongan', badge: '★ Teladan',
      phone: '+62 812-3456-7890', healthStatus: 'Memenuhi Syarat (Fit untuk Donor)',
      targetHospital: 'RSUD DR. SOEGIRI', avgResponseTime: '< 4 menit',
      donorLat: -7.1198, donorLng: 112.4152,
    ),
    RelawanModel(
      id: 'REL-2025-00422', nama: 'Ahmad Fauzi', nik: '3524071408890002',
      usia: 35, goldar: 'B+', rhesus: 'Positif', statusSiaga: 'SIAGA',
      distance: '2.4 KM', eta: '12 mnt lalu aktif', totalDonor: 5, lastDonor: '20 Jan 2025',
      kecamatan: 'Kec. Tikung, Lamongan',
      phone: '+62 813-8899-7711', healthStatus: 'Memenuhi Syarat (Fit untuk Donor)',
      targetHospital: 'RSUD DR. SOEGIRI', avgResponseTime: '6 menit',
      donorLat: -7.1350, donorLng: 112.4210,
    ),
    RelawanModel(
      id: 'REL-2025-00423', nama: 'Rina Wijaya', nik: '3524015603950001',
      usia: 29, goldar: 'A-', rhesus: 'Negatif (Langka)', statusSiaga: 'STANDBY',
      distance: '3.0 KM', eta: 'Siap dikonfirmasi', totalDonor: 3, lastDonor: '05 Feb 2025',
      kecamatan: 'Kec. Lamongan Kota', badge: 'Langka',
      phone: '+62 821-4455-6677', healthStatus: 'Memenuhi Syarat (Fit untuk Donor)',
      targetHospital: 'RS Muhammadiyah Lamongan', avgResponseTime: '5 menit',
      donorLat: -7.1120, donorLng: 112.4080,
    ),
  ];

  late RelawanModel _selectedRelawan;

  @override
  void initState() {
    super.initState();
    _fetchRelawan();
  }

  Future<void> _fetchRelawan() async {
    setState(() => _isLoading = true);
    try {
      final users = await _adminRepo.getAllUsers();
      final donors = users.where((u) => u.role == 'donor').toList();

      if (donors.isNotEmpty) {
        _allRelawan = donors.asMap().entries.map((e) =>
            RelawanModel.fromUser(e.value, e.key)).toList();
      } else {
        // Use all users if no donors yet, or fallback to dummy
        if (users.length > 1) {
          _allRelawan = users.where((u) => u.role != 'admin').toList()
              .asMap().entries.map((e) => RelawanModel.fromUser(e.value, e.key)).toList();
        }
        if (_allRelawan.isEmpty) {
          _allRelawan = _dummyRelawan.toList();
        }
      }

      if (mounted) {
        setState(() {
          _selectedRelawan = _allRelawan.first;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _allRelawan = _dummyRelawan.toList();
          _selectedRelawan = _allRelawan.first;
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RelawanModel> get _filteredRelawan {
    final query = _searchController.text.trim().toLowerCase();
    return _allRelawan.where((r) {
      final matchQuery = query.isEmpty ||
          r.nama.toLowerCase().contains(query) ||
          r.nik.contains(query) ||
          r.goldar.toLowerCase().contains(query) ||
          r.kecamatan.toLowerCase().contains(query);

      if (!matchQuery) return false;

      if (_selectedFilter == 'Semua') return true;
      if (_selectedFilter == 'Siaga (Online)') return r.statusSiaga == 'SIAGA';
      if (_selectedFilter == 'O+') return r.goldar == 'O+';
      if (_selectedFilter == 'A+') return r.goldar == 'A+';
      if (_selectedFilter == 'B+') return r.goldar == 'B+';
      if (_selectedFilter == 'AB') return r.goldar.startsWith('AB');
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── TOP HEADER ───
              _buildTopHeader(),
              const SizedBox(height: 22),

              // ─── 4 METRIC CARDS ───
              _buildMetricCards(),
              const SizedBox(height: 24),

              // ─── TWO-COLUMN CONTENT AREA ───
              _buildMainColumns(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TOP HEADER: TITLE, DATE, BADGE & BROADCAST BUTTON
  // ─────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manajemen Relawan Donor',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selasa, 8 September 2025 • Total 1.248 Relawan Terdaftar',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        final actionButtons = Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 10,
          children: [
            // Green Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '84 Relawan Siaga Radius 5 km',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ),

            // Notification Bell Icon with Dot
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.notifications_none_rounded, size: 18, color: Color(0xFF475569)),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Red Add/Broadcast Button
            ElevatedButton.icon(
              onPressed: () {
                _showBroadcastDialog();
              },
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text(
                'Tambah Relawan / Broadcast',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              titleSection,
              actionButtons,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // 4 METRIC CARDS ROW
  // ─────────────────────────────────────────────────────────
  Widget _buildMetricCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int count = 4;
        if (constraints.maxWidth < 650) {
          count = 1;
        } else if (constraints.maxWidth < 1050) {
          count = 2;
        }

        if (count == 4) {
          return Row(
            children: [
              Expanded(child: _buildMetricCard1()),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard2()),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard3()),
              const SizedBox(width: 14),
              Expanded(child: _buildMetricCard4()),
            ],
          );
        } else if (count == 2) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetricCard1()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMetricCard2()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildMetricCard3()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildMetricCard4()),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildMetricCard1(),
              const SizedBox(height: 14),
              _buildMetricCard2(),
              const SizedBox(height: 14),
              _buildMetricCard3(),
              const SizedBox(height: 14),
              _buildMetricCard4(),
            ],
          );
        }
      },
    );
  }

  Widget _metricBaseCard({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor ?? const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  // Card 1: Total Relawan Aktif
  Widget _buildMetricCard1() {
    return _metricBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Relawan Aktif',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.person_outline_rounded, size: 16, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '1.248',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '+12 minggu ini',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 2: Relawan Siaga (Online)
  Widget _buildMetricCard2() {
    return _metricBaseCard(
      borderColor: const Color(0xFFA7F3D0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Relawan Siaga (Online)',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android_rounded, size: 16, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '84',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'GPS aktif & fit',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 3: Golongan Darah Langka
  Widget _buildMetricCard3() {
    return _metricBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Golongan Darah Langka',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.water_drop_rounded, size: 16, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '32 Relawan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'AB-, B-, O-',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFDC2626),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 4: Total Donasi Tersalur
  Widget _buildMetricCard4() {
    return _metricBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Donasi Tersalur',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.favorite_border_rounded, size: 16, color: Color(0xFF9333EA)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '3.410',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Kantong',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const Text(
                'Tahun\n2025',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF94A3B8),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TWO-COLUMN MAIN CONTENT
  // ─────────────────────────────────────────────────────────
  Widget _buildMainColumns() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 920;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Search & List (flex: 11)
              Expanded(flex: 11, child: _buildLeftListSection()),
              const SizedBox(width: 20),
              // Right Column: Detail Panel (flex: 13)
              Expanded(flex: 13, child: _buildRightDetailPanel()),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeftListSection(),
              const SizedBox(height: 24),
              _buildRightDetailPanel(),
            ],
          );
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // LEFT COLUMN: SEARCH, FILTER CHIPS & RELAWAN LIST
  // ─────────────────────────────────────────────────────────
  Widget _buildLeftListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input Field
        Container(
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontSize: 12.5),
            decoration: const InputDecoration(
              hintText: 'Cari nama, NIK, atau golongan darah...',
              hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 11),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _filterChip('Semua'),
              const SizedBox(width: 6),
              _filterChip('Siaga (Online)'),
              const SizedBox(width: 6),
              _filterChip('O+'),
              const SizedBox(width: 6),
              _filterChip('A+'),
              const SizedBox(width: 6),
              _filterChip('B+'),
              const SizedBox(width: 6),
              _filterChip('AB'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Relawan List
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredRelawan.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final relawan = _filteredRelawan[index];
            return _buildRelawanListItem(relawan);
          },
        ),
      ],
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildRelawanListItem(RelawanModel relawan) {
    final isSelected = _selectedRelawan.id == relawan.id;

    // Blood type badge color
    Color goldarBg = const Color(0xFFEF4444);
    if (relawan.goldar.contains('-') || relawan.goldar.startsWith('AB')) {
      goldarBg = const Color(0xFF8B5CF6);
    }

    return InkWell(
      onTap: () => setState(() => _selectedRelawan = relawan),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFEF4444).withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isSelected)
                  Container(width: 4, color: const Color(0xFFEF4444)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Name, Badge & Status Pill
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      relawan.nama,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (relawan.badge != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: relawan.badge == '★ Teladan'
                                            ? const Color(0xFFFEF3C7)
                                            : const Color(0xFFF3E8FF),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        relawan.badge!,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: relawan.badge == '★ Teladan'
                                              ? const Color(0xFFD97706)
                                              : const Color(0xFF7E22CE),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusBadge(relawan),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Row 2: Blood Type Box & Last Donation
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: goldarBg,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                relawan.goldar,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${relawan.totalDonor}x Donor • Terakhir: ${relawan.lastDonor}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Row 3: Location
                        Text(
                          relawan.kecamatan,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF94A3B8),
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
      ),
    );
  }

  Widget _buildStatusBadge(RelawanModel relawan) {
    if (relawan.statusSiaga == 'SIAGA') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Text(
              'SIAGA (${relawan.distance})',
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            relawan.eta,
            style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w500),
          ),
        ],
      );
    } else if (relawan.statusSiaga == 'STANDBY') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'STANDBY',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            relawan.eta,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'OFFLINE (RESTING)',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            relawan.eta,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // RIGHT COLUMN: PROFIL & KESIAPSIAGAAN RELAWAN PANEL
  // ─────────────────────────────────────────────────────────
  Widget _buildRightDetailPanel() {
    final r = _selectedRelawan;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Indicator + Title + ID
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PROFIL & KESIAPSIAGAAN RELAWAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Text(
                'ID : ${r.id}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // User Bio Card with Blood Type Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with Badge
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: const Color(0xFFEF4444),
                      child: Text(
                        _getInitials(r.nama),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check, size: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Info: Name, NIK, Siaga Badge & SLA
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.nama,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'NIK: ${r.nik} • Usia: ${r.usia} Tahun',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'SIAGA CEPAT • ${r.targetHospital}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Respons rata-rata: ${r.avgResponseTime}',
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Blood Type Big Card (Pink Box)
                Container(
                  width: 75,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFECDD3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'GOL.\nDARAH',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFBE123C),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        r.goldar,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFE11D48),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Rhesus\n${r.rhesus}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFFBE123C),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Two Information Cards (Kontak & WhatsApp + Status Kesehatan)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KONTAK & WHATSAPP',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              r.phone,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'STATUS KESEHATAN TERKINI',
                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8)),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              r.healthStatus,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF065F46)),
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
          const SizedBox(height: 16),

          // GPS Siaga Terkini & Estimasi Rute Canvas Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFEF4444)),
                        SizedBox(width: 6),
                        Text(
                          'GPS Siaga Terkini & Estimasi Rute',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        'Radius ${r.distance} (${r.eta})',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Simulated Map Route Graphics
                Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Stack(
                    children: [
                      // Grid lines / road canvas
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _MiniMapRoutePainter(),
                        ),
                      ),
                      // Position indicator pill
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${r.nama} (Posisi Sekarang)',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Bottom Action Buttons Row
          LayoutBuilder(
            builder: (context, btnConstraints) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Button 1: Kirim Panggilan Darurat (Direct Dispatch)
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Panggilan darurat terkirim ke ${r.nama} via Push Notifikasi & SMS!'),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text(
                      'Kirim Panggilan Darurat (Direct Dispatch)',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Button 2: Hubungi WhatsApp
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Membuka chat WhatsApp ke ${r.phone}...'),
                          backgroundColor: const Color(0xFF25D366),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Hubungi WhatsApp',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Button 3: Rekam Medis
                  OutlinedButton(
                    onPressed: () {
                      _showMedicalRecordDialog(r);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Rekam Medis',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'R';
  }

  void _showBroadcastDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.podcasts_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Broadcast Siaga Darurat'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kirimkan notifikasi darurat serentak ke 84 Relawan Siaga dalam radius 5 KM dari Faskes Lamongan?',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Broadcast darurat berhasil disebarkan ke 84 relawan aktif!'),
                  backgroundColor: Color(0xFFDC2626),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Kirimkan Broadcast Sekarang', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showMedicalRecordDialog(RelawanModel r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Rekam Medis: ${r.nama}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID Relawan: ${r.id}'),
            const SizedBox(height: 6),
            Text('Golongan Darah: ${r.goldar} (${r.rhesus})'),
            const SizedBox(height: 6),
            Text('Frekuensi Donor: ${r.totalDonor} kali'),
            const SizedBox(height: 6),
            Text('Terakhir Donor: ${r.lastDonor}'),
            const SizedBox(height: 6),
            Text('Status Fisik Terkini: ${r.healthStatus}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CUSTOM PAINTER FOR MINI GPS ROUTE
// ─────────────────────────────────────────────────────────
class _MiniMapRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;

    // Grid dots
    for (double x = 15; x < size.width; x += 30) {
      for (double y = 15; y < size.height; y += 25) {
        canvas.drawCircle(Offset(x, y), 1.2, gridPaint);
      }
    }

    // Dotted route line from bottom-left to top-right
    final routePaint = Paint()
      ..color = const Color(0xFFFCA5A5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(20, size.height - 20)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.7, size.width * 0.5, size.height * 0.5)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.3, size.width - 30, 25);

    // Draw dashed path
    canvas.drawPath(path, routePaint);

    // Destination Pin (RSUD)
    final pinPaint = Paint()..color = const Color(0xFF059669);
    canvas.drawCircle(Offset(size.width - 30, 25), 5, pinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
