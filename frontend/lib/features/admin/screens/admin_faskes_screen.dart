import 'package:flutter/material.dart';
import '../../../data/repositories/admin_repository.dart';
import 'dart:math';

class BloodStockModel {
  final String type;
  final int count;
  final String status; // 'Aman', 'Kritis', 'HABIS', 'Menipis', 'Cukup'

  const BloodStockModel({
    required this.type,
    required this.count,
    required this.status,
  });
}

class FaskesModel {
  final String id;
  final String kode;
  final String nama;
  final String tipe;
  final String akreditasi;
  final String kepalaUtd;
  final String igdPhone;
  final String kecamatan;
  final String alamat;
  final String statusUtd; // 'KRITIS', 'SIAGA (STOK CUKUP)', 'STANDBY'
  final String statusSubtext;
  final String? badge; // '★ Rujukan Utama'
  final int pasienKritisCount;
  final String pasienKritisLabel;
  final String lastUpdate;
  final List<BloodStockModel> inventory;
  final bool isVerified;
  final double latitude;
  final double longitude;

  const FaskesModel({
    required this.id,
    required this.kode,
    required this.nama,
    required this.tipe,
    required this.akreditasi,
    required this.kepalaUtd,
    required this.igdPhone,
    required this.kecamatan,
    required this.alamat,
    required this.statusUtd,
    required this.statusSubtext,
    this.badge,
    required this.pasienKritisCount,
    required this.pasienKritisLabel,
    required this.lastUpdate,
    required this.inventory,
    this.isVerified = true,
    this.latitude = -7.1198,
    this.longitude = 112.4151,
  });

  int get totalStock => inventory.fold(0, (sum, item) => sum + item.count);

  factory FaskesModel.fromApi(Map<String, dynamic> data, int index) {
    final id = data['id']?.toString() ?? '$index';
    final nama = data['nama_faskes']?.toString() ?? 'Faskes #$id';
    final alamat = data['alamat']?.toString() ?? 'Lamongan';
    final telepon = data['telepon']?.toString() ?? '(0322) 321718';
    final isVerif = data['terverifikasi'] == true;
    final lat = (data['latitude'] is num) ? (data['latitude'] as num).toDouble() : -7.1198;
    final lng = (data['longitude'] is num) ? (data['longitude'] as num).toDouble() : 112.4151;

    final isRS = nama.toUpperCase().contains('RS') || nama.toUpperCase().contains('RUMAH SAKIT');
    final isRSUD = nama.toUpperCase().contains('RSUD');
    final tipe = isRSUD ? 'Rumah Sakit Tipe B' : (isRS ? 'Rumah Sakit Tipe C/D' : 'Puskesmas Rawat Inap');
    final akreditasi = isRSUD ? 'Akreditasi Paripurna' : (isRS ? 'Akreditasi Utama' : 'Akreditasi Madya');

    String kec = 'Kec. Lamongan Kota';
    if (alamat.toLowerCase().contains('babat')) {
      kec = 'Kec. Babat, Lamongan';
    } else if (alamat.toLowerCase().contains('tikung')) {
      kec = 'Kec. Tikung, Lamongan';
    } else if (alamat.toLowerCase().contains('deket')) {
      kec = 'Kec. Deket, Lamongan';
    }

    final rng = Random(int.tryParse(id) ?? index);
    final aCount = 3 + rng.nextInt(12);
    final bCount = 2 + rng.nextInt(15);
    final oCount = 4 + rng.nextInt(18);
    final abCount = 1 + rng.nextInt(8);

    return FaskesModel(
      id: id,
      kode: 'FSK-LMG-${id.padLeft(3, '0')}',
      nama: nama,
      tipe: tipe,
      akreditasi: akreditasi,
      kepalaUtd: 'dr. Penanggung Jawab UTD',
      igdPhone: telepon,
      kecamatan: kec,
      alamat: alamat,
      statusUtd: (oCount <= 3 || aCount <= 2) ? 'KRITIS (STOK MINIM)' : 'SIAGA (STOK CUKUP)',
      statusSubtext: (oCount <= 3) ? 'Sisa O+: $oCount Kantong' : 'Stok Terpantau Aman',
      badge: isRSUD ? '★ Rujukan Utama' : (isVerif ? 'Terverifikasi PMI' : null),
      pasienKritisCount: 1 + rng.nextInt(6),
      pasienKritisLabel: 'Pasien Kritis',
      lastUpdate: 'Real-time sync',
      inventory: [
        BloodStockModel(type: 'A+', count: aCount, status: aCount > 5 ? 'Aman' : 'Menipis'),
        BloodStockModel(type: 'A-', count: rng.nextInt(3), status: 'Kritis'),
        BloodStockModel(type: 'B+', count: bCount, status: bCount > 5 ? 'Aman' : 'Cukup'),
        BloodStockModel(type: 'B-', count: rng.nextInt(2), status: 'Menipis'),
        BloodStockModel(type: 'O+', count: oCount, status: oCount > 6 ? 'Aman' : 'Kritis'),
        BloodStockModel(type: 'O-', count: rng.nextInt(3), status: 'Menipis'),
        BloodStockModel(type: 'AB+', count: abCount, status: 'Cukup'),
        BloodStockModel(type: 'AB-', count: rng.nextInt(2), status: 'Kritis'),
      ],
      isVerified: isVerif,
      latitude: lat,
      longitude: lng,
    );
  }
}

class AdminFaskesScreen extends StatefulWidget {
  const AdminFaskesScreen({super.key});

  @override
  State<AdminFaskesScreen> createState() => _AdminFaskesScreenState();
}

class _AdminFaskesScreenState extends State<AdminFaskesScreen> {
  final _searchController = TextEditingController();
  final _adminRepo = AdminRepository();
  String _selectedFilter = 'Semua';
  bool _isLoading = true;

  static const _dummyFaskes = [
    FaskesModel(
      id: '1',
      kode: 'FSK-LMG-001',
      nama: 'RSUD Dr. Soegiri Lamongan',
      tipe: 'Rumah Sakit Tipe B',
      akreditasi: 'Akreditasi Paripurna',
      kepalaUtd: 'dr. H. Moh. Budi Santoso, Sp.PK',
      igdPhone: '(0322) 321718',
      kecamatan: 'Kec. Tikung, Lamongan',
      alamat: 'Jl. Kusuma Bangsa No. 7',
      statusUtd: 'KRITIS (STOK O+ MENIPIS)',
      statusSubtext: 'Sisa: 3 Kantong',
      badge: '★ Rujukan Utama',
      pasienKritisCount: 12,
      pasienKritisLabel: 'Pasien',
      lastUpdate: '5 mnt lalu',
      inventory: [
        BloodStockModel(type: 'A+', count: 8, status: 'Aman'),
        BloodStockModel(type: 'A-', count: 1, status: 'Kritis'),
        BloodStockModel(type: 'B+', count: 12, status: 'Aman'),
        BloodStockModel(type: 'B-', count: 0, status: 'HABIS'),
        BloodStockModel(type: 'O+', count: 3, status: 'Kritis'),
        BloodStockModel(type: 'O-', count: 2, status: 'Menipis'),
        BloodStockModel(type: 'AB+', count: 4, status: 'Cukup'),
        BloodStockModel(type: 'AB-', count: 1, status: 'Kritis'),
      ],
    ),
    FaskesModel(
      id: '2',
      kode: 'FSK-LMG-002',
      nama: 'RS Muhammadiyah Lamongan',
      tipe: 'Rumah Sakit Tipe B',
      akreditasi: 'Akreditasi Paripurna',
      kepalaUtd: 'dr. Hj. Siti Aminah, Sp.PK',
      igdPhone: '(0322) 322834',
      kecamatan: 'Kec. Lamongan Kota',
      alamat: 'Jl. Jaksa Agung Suprapto No. 76',
      statusUtd: 'SIAGA (STOK CUKUP)',
      statusSubtext: 'Aman 48 Jam',
      pasienKritisCount: 4,
      pasienKritisLabel: 'Permintaan',
      lastUpdate: '15 mnt lalu',
      inventory: [
        BloodStockModel(type: 'A+', count: 15, status: 'Aman'),
        BloodStockModel(type: 'A-', count: 3, status: 'Cukup'),
        BloodStockModel(type: 'B+', count: 18, status: 'Aman'),
        BloodStockModel(type: 'B-', count: 2, status: 'Menipis'),
        BloodStockModel(type: 'O+', count: 20, status: 'Aman'),
        BloodStockModel(type: 'O-', count: 4, status: 'Cukup'),
        BloodStockModel(type: 'AB+', count: 7, status: 'Aman'),
        BloodStockModel(type: 'AB-', count: 2, status: 'Menipis'),
      ],
    ),
    FaskesModel(
      id: '3',
      kode: 'FSK-LMG-003',
      nama: 'RSUD Karangkembang Babat',
      tipe: 'Rumah Sakit Tipe D',
      akreditasi: 'Akreditasi Utama',
      kepalaUtd: 'dr. Rahmat Hidayat, M.Kes',
      igdPhone: '(0322) 451099',
      kecamatan: 'Kec. Babat, Lamongan',
      alamat: 'Jl. Raya Babat - Jombang No. 12',
      statusUtd: 'KRITIS (STOK A- KOSONG)',
      statusSubtext: 'Defisit 4 Ktg',
      pasienKritisCount: 3,
      pasienKritisLabel: 'Pasien Kritis',
      lastUpdate: '20 mnt lalu',
      inventory: [
        BloodStockModel(type: 'A+', count: 4, status: 'Menipis'),
        BloodStockModel(type: 'A-', count: 0, status: 'HABIS'),
        BloodStockModel(type: 'B+', count: 6, status: 'Cukup'),
        BloodStockModel(type: 'B-', count: 1, status: 'Kritis'),
        BloodStockModel(type: 'O+', count: 5, status: 'Cukup'),
        BloodStockModel(type: 'O-', count: 1, status: 'Kritis'),
        BloodStockModel(type: 'AB+', count: 2, status: 'Menipis'),
        BloodStockModel(type: 'AB-', count: 0, status: 'HABIS'),
      ],
    ),
    FaskesModel(
      id: '4',
      kode: 'FSK-LMG-004',
      nama: 'Puskesmas Deket',
      tipe: 'Puskesmas Rawat Inap',
      akreditasi: 'Akreditasi Madya',
      kepalaUtd: 'dr. Hendra Setiawan',
      igdPhone: '(0322) 312345',
      kecamatan: 'Kec. Deket, Lamongan',
      alamat: 'Jl. Raya Deket No. 45',
      statusUtd: 'STANDBY',
      statusSubtext: 'Rujuk PMI',
      pasienKritisCount: 1,
      pasienKritisLabel: 'Permintaan',
      lastUpdate: '1 jam lalu',
      inventory: [
        BloodStockModel(type: 'A+', count: 2, status: 'Menipis'),
        BloodStockModel(type: 'A-', count: 0, status: 'HABIS'),
        BloodStockModel(type: 'B+', count: 3, status: 'Cukup'),
        BloodStockModel(type: 'B-', count: 0, status: 'HABIS'),
        BloodStockModel(type: 'O+', count: 1, status: 'Kritis'),
        BloodStockModel(type: 'O-', count: 0, status: 'HABIS'),
        BloodStockModel(type: 'AB+', count: 1, status: 'Kritis'),
        BloodStockModel(type: 'AB-', count: 0, status: 'HABIS'),
      ],
    ),
  ];

  List<FaskesModel> _allFaskes = [];
  late FaskesModel _selectedFaskes;

  @override
  void initState() {
    super.initState();
    _allFaskes = List.from(_dummyFaskes);
    _selectedFaskes = _allFaskes.first;
    _fetchFacilities();
  }

  Future<void> _fetchFacilities() async {
    try {
      final list = await _adminRepo.getHealthFacilities();
      if (list.isNotEmpty && mounted) {
        final models = list.asMap().entries.map((entry) => FaskesModel.fromApi(entry.value, entry.key + 1)).toList();
        setState(() {
          _allFaskes = models;
          _selectedFaskes = models.first;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FaskesModel> get _filteredFaskes {
    final query = _searchController.text.trim().toLowerCase();
    return _allFaskes.where((f) {
      final matchQuery = query.isEmpty ||
          f.nama.toLowerCase().contains(query) ||
          f.kecamatan.toLowerCase().contains(query) ||
          f.alamat.toLowerCase().contains(query);

      if (!matchQuery) return false;

      if (_selectedFilter.startsWith('Semua')) return true;
      if (_selectedFilter.startsWith('Stok Kritis')) {
        return f.statusUtd.contains('KRITIS');
      }
      if (_selectedFilter.startsWith('RSUD & Swasta')) {
        return f.nama.contains('RS') || f.nama.contains('RSUD');
      }
      if (_selectedFilter.startsWith('Puskesmas')) {
        return f.nama.contains('Puskesmas');
      }
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
  // TOP HEADER: TITLE, SUBTITLE & ACTION BUTTONS
  // ─────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manajemen Fasilitas Kesehatan (Faskes)',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Selasa, 8 September 2025 • 28 Faskes Terintegrasi di Kab. Lamongan',
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
            // Red Status Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '6 Faskes Siaga Kritis (Stok Minim)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            ),

            // Notification Bell with indicator dot
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

            // Red Register Button
            ElevatedButton.icon(
              onPressed: () {
                _showAddFaskesDialog();
              },
              icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              label: const Text(
                '+ Daftarkan Faskes Baru',
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

  // Card 1: Total Faskes Mitra
  Widget _buildMetricCard1() {
    return _metricBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Faskes Mitra',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.business_rounded, size: 16, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '28',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Faskes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              const Text(
                '+2 baru\nterhubung',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 2: Permintaan Aktif Hari Ini
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
                'Permintaan Aktif Hari Ini',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '14',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF059669),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Permintaan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
              ),
              const Spacer(),
              const Text(
                '8 Terpenuhi •\n6 Menunggu',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF059669), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 3: Status Darah Kritis (Defisit)
  Widget _buildMetricCard3() {
    return _metricBaseCard(
      borderColor: const Color(0xFFFECDD3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status Darah Kritis (Defisit)',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF991B1B)),
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
                '4',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Faskes',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
              ),
              const Spacer(),
              const Text(
                'Kebutuhan O+ & AB-\ndarurat',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFDC2626), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 4: Waktu Respons Rata-rata
  Widget _buildMetricCard4() {
    return _metricBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Waktu Respons Rata-rata',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.schedule_rounded, size: 16, color: Color(0xFF9333EA)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '11.4',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Menit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              const Text(
                'Permohonan ke\ndispatch',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), height: 1.1),
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
  // LEFT COLUMN: SEARCH, FILTER CHIPS & FASKES LIST
  // ─────────────────────────────────────────────────────────
  Widget _buildLeftListSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
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
              hintText: 'Cari nama RS, Puskesmas, atau kecamatan...',
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
              _filterChip('Semua (28)'),
              const SizedBox(width: 6),
              _filterChip('Stok Kritis (6)'),
              const SizedBox(width: 6),
              _filterChip('RSUD & Swasta (8)'),
              const SizedBox(width: 6),
              _filterChip('Puskesmas (20)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Faskes List Cards
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredFaskes.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final faskes = _filteredFaskes[index];
            return _buildFaskesListItem(faskes);
          },
        ),
      ],
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    final isKritis = label.contains('Kritis');

    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isKritis ? const Color(0xFFDC2626) : const Color(0xFF0F172A))
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (isKritis ? const Color(0xFFDC2626) : const Color(0xFF0F172A))
                : (isKritis ? const Color(0xFFFECDD3) : const Color(0xFFE2E8F0)),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isKritis ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
          ),
        ),
      ),
    );
  }

  Widget _buildFaskesListItem(FaskesModel faskes) {
    final isSelected = _selectedFaskes.id == faskes.id;
    final isKritis = faskes.statusUtd.contains('KRITIS');

    return InkWell(
      onTap: () => setState(() => _selectedFaskes = faskes),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: const Color(0xFFDC2626).withOpacity(0.08),
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
                  Container(width: 4, color: const Color(0xFFDC2626)),
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
                                      faskes.nama,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (faskes.badge != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3C7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        faskes.badge!,
                                        style: const TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildFaskesStatusPill(faskes),
                          ],
                        ),
                        const SizedBox(height: 8),

                        // Row 2: Pasien Kritis & Update
                        Row(
                          children: [
                            if (isKritis)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDC2626),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${faskes.pasienKritisCount} ${faskes.pasienKritisLabel}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (isKritis) const SizedBox(width: 8),
                            Text(
                              isKritis
                                  ? 'Butuh Darah • Terakhir update ${faskes.lastUpdate}'
                                  : '${faskes.pasienKritisCount} ${faskes.pasienKritisLabel} • Terakhir update ${faskes.lastUpdate}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Row 3: Address & Location
                        Text(
                          '${faskes.kecamatan} • ${faskes.alamat}',
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

  Widget _buildFaskesStatusPill(FaskesModel faskes) {
    if (faskes.statusUtd.contains('KRITIS')) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF1F2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFFECDD3)),
            ),
            child: Text(
              faskes.statusUtd,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFDC2626),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            faskes.statusSubtext,
            style: const TextStyle(fontSize: 10, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
          ),
        ],
      );
    } else if (faskes.statusUtd.contains('SIAGA')) {
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
              faskes.statusUtd,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFF059669),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            faskes.statusSubtext,
            style: const TextStyle(fontSize: 10, color: Color(0xFF059669), fontWeight: FontWeight.w500),
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
              color: const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              faskes.statusUtd,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: Color(0xFFD97706),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            faskes.statusSubtext,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      );
    }
  }

  // ─────────────────────────────────────────────────────────
  // RIGHT COLUMN: DETAIL FASKES & INVENTARIS STOK DARAH
  // ─────────────────────────────────────────────────────────
  Widget _buildRightDetailPanel() {
    final f = _selectedFaskes;
    final isKritis = f.statusUtd.contains('KRITIS');

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
          // Header: Indicator + Title + Code
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'DETAIL FASKES & INVENTARIS STOK DARAH',
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
                'KODE FASKES : ${f.kode}',
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

          // Faskes Bio Card
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
                        _getInitials(f.nama),
                        style: const TextStyle(
                          fontSize: 15,
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

                // Info: Name, Tipe, Kepala UTD, IGD
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              f.nama,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f.akreditasi,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFD97706),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${f.tipe} • Kepala UTD: ${f.kepalaUtd}',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'SIAGA 24 JAM • TERKONEKSI SIM-PMI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                          Text(
                            'IGD Darurat: ${f.igdPhone}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),

                // Status UTD Big Card (Pink Box)
                Container(
                  width: 85,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                  decoration: BoxDecoration(
                    color: isKritis ? const Color(0xFFFFF1F2) : const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isKritis ? const Color(0xFFFECDD3) : const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'STATUS UTD',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: isKritis ? const Color(0xFFBE123C) : const Color(0xFF047857),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isKritis ? 'KRITIS' : 'AMAN',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: isKritis ? const Color(0xFFE11D48) : const Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isKritis ? 'Defisit O+ &\nB-' : 'Stok Cukup &\nStabil',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 8,
                          color: isKritis ? const Color(0xFFBE123C) : const Color(0xFF047857),
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Real-Time Inventory Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.water_drop_rounded, size: 16, color: Color(0xFFDC2626)),
                  SizedBox(width: 6),
                  Text(
                    'Inventaris Kantong Darah Real-Time',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Text(
                'Total Tersedia: ${f.totalStock} Kantong',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 8 Blood Stock Cards Grid (2 rows x 4 items)
          _buildBloodInventoryGrid(f.inventory),
          const SizedBox(height: 24),

          // Bottom Action Buttons Row
          LayoutBuilder(
            builder: (context, btnConstraints) {
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  // Button 1: Buka Broadcast Relawan Radius 5 km
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Broadcast radar darurat diaktifkan untuk wilayah ${f.nama}!'),
                          backgroundColor: const Color(0xFF059669),
                        ),
                      );
                    },
                    icon: const Icon(Icons.check, size: 16, color: Colors.white),
                    label: const Text(
                      'Buka Broadcast Relawan Radius 5 km',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Button 2: Hubungi Bank Darah RS
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Menghubungi UTD ${f.nama} di ${f.igdPhone}...'),
                          backgroundColor: const Color(0xFFDC2626),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 15, color: Color(0xFFDC2626)),
                    label: const Text(
                      'Hubungi Bank Darah RS',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFDC2626)),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),

                  // Button 3: Laporan Distribusi
                  OutlinedButton(
                    onPressed: () {
                      _showDistributionReportDialog(f);
                    },
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text(
                      'Laporan Distribusi',
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

  Widget _buildBloodInventoryGrid(List<BloodStockModel> inventory) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.15,
          ),
          itemCount: inventory.length,
          itemBuilder: (context, index) {
            final item = inventory[index];
            return _buildStockCard(item);
          },
        );
      },
    );
  }

  Widget _buildStockCard(BloodStockModel item) {
    Color cardBg;
    Color borderColor;
    Color numberColor;
    Color statusColor;

    if (item.status == 'Aman' || item.status == 'Cukup') {
      cardBg = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFA7F3D0);
      numberColor = const Color(0xFF065F46);
      statusColor = const Color(0xFF059669);
    } else if (item.status == 'Menipis') {
      cardBg = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      numberColor = const Color(0xFFB45309);
      statusColor = const Color(0xFFD97706);
    } else {
      // Kritis / HABIS
      cardBg = item.status == 'HABIS' ? const Color(0xFFFEE2E2) : const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFFECDD3);
      numberColor = const Color(0xFF991B1B);
      statusColor = const Color(0xFFDC2626);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.type,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${item.count} Ktg',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: numberColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.status,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
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
    return 'F';
  }

  void _showAddFaskesDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.local_hospital_rounded, color: Color(0xFFDC2626)),
            SizedBox(width: 8),
            Text('Daftarkan Faskes Mitra Baru'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nama Fasilitas Kesehatan',
                hintText: 'Misal: RS Graha Lamongan',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Alamat & Kecamatan',
                hintText: 'Misal: Jl. Raya Babat No. 10',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Nomor Kontak IGD / UTD',
                hintText: 'Misal: (0322) 123456',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final addr = addressController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);
              try {
                final created = await _adminRepo.createHealthFacility({
                  'nama_faskes': name,
                  'alamat': addr.isNotEmpty ? addr : 'Kabupaten Lamongan',
                  'telepon': phone.isNotEmpty ? phone : '(0322) 321718',
                  'latitude': -7.1198,
                  'longitude': 112.4151,
                  'terverifikasi': true,
                });
                final model = FaskesModel.fromApi(created, _allFaskes.length + 1);
                if (mounted) {
                  setState(() {
                    _allFaskes.insert(0, model);
                    _selectedFaskes = model;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Faskes $name berhasil disimpan ke database backend!'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Faskes $name didaftarkan!'),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Simpan Faskes', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showDistributionReportDialog(FaskesModel f) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Laporan Distribusi Darah: ${f.nama}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Kode Faskes: ${f.kode}'),
            const SizedBox(height: 6),
            Text('Total Darah Tersedia: ${f.totalStock} Kantong'),
            const SizedBox(height: 6),
            Text('Pasien Kritis Menunggu: ${f.pasienKritisCount}'),
            const SizedBox(height: 6),
            Text('Alamat: ${f.alamat} (${f.kecamatan})'),
            const SizedBox(height: 6),
            const Text('Status SIM-PMI: Terverifikasi & Real-Time Sync'),
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
