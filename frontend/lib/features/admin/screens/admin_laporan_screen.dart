import 'package:flutter/material.dart';
import '../../../data/repositories/admin_repository.dart';
import 'dart:math';

// ─────────────────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────────────────

class DailyTrendData {
  final String day;
  final int permintaan;
  final int terpenuhi;

  const DailyTrendData({
    required this.day,
    required this.permintaan,
    required this.terpenuhi,
  });
}

class FaskesRankItem {
  final int rank;
  final String nama;
  final int permintaan;
  final int terpenuhi;

  const FaskesRankItem({
    required this.rank,
    required this.nama,
    required this.permintaan,
    required this.terpenuhi,
  });

  String get efisiensi =>
      '${((terpenuhi / permintaan) * 100).round()}%';
}

class PenyaluranItem {
  final String nama;
  final String golDarah;
  final int jumlahKantong;
  final String faskes;
  final String relawan;
  final String waktu;
  final String status; // 'SELESAI', 'PENDING', 'DARURAT'

  const PenyaluranItem({
    required this.nama,
    required this.golDarah,
    required this.jumlahKantong,
    required this.faskes,
    required this.relawan,
    required this.waktu,
    required this.status,
  });
}

// ─────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────

class AdminLaporanScreen extends StatefulWidget {
  const AdminLaporanScreen({super.key});

  @override
  State<AdminLaporanScreen> createState() => _AdminLaporanScreenState();
}

class _AdminLaporanScreenState extends State<AdminLaporanScreen> {
  final _adminRepo = AdminRepository();
  String _selectedPeriod = 'Bulan Ini (Sep 2025)';
  String _selectedFilter = 'Semua';
  int _totalRequests = 142;
  int _completedRequests = 134;
  int _totalVolumeKantong = 286;
  bool _isLoading = true;

  // ── SAMPLE DATA ──
  final List<DailyTrendData> _trendData = const [
    DailyTrendData(day: 'Sen', permintaan: 22, terpenuhi: 20),
    DailyTrendData(day: 'Sel', permintaan: 18, terpenuhi: 17),
    DailyTrendData(day: 'Rab', permintaan: 25, terpenuhi: 24),
    DailyTrendData(day: 'Kam', permintaan: 20, terpenuhi: 19),
    DailyTrendData(day: 'Jum', permintaan: 28, terpenuhi: 26),
    DailyTrendData(day: 'Sab', permintaan: 15, terpenuhi: 15),
    DailyTrendData(day: 'Min', permintaan: 14, terpenuhi: 13),
  ];

  final List<FaskesRankItem> _faskesRanking = const [
    FaskesRankItem(rank: 1, nama: 'RSUD Dr. Soegiri Lamongan', permintaan: 58, terpenuhi: 56),
    FaskesRankItem(rank: 2, nama: 'RS Muhammadiyah Lamongan', permintaan: 34, terpenuhi: 32),
    FaskesRankItem(rank: 3, nama: 'RSUD Karangkembang Babat', permintaan: 22, terpenuhi: 20),
    FaskesRankItem(rank: 4, nama: 'Puskesmas Lamongan Kota', permintaan: 16, terpenuhi: 16),
  ];

  List<PenyaluranItem> _allPenyaluran = [
    const PenyaluranItem(
      nama: 'Dewi Rahayu',
      golDarah: 'O+',
      jumlahKantong: 2,
      faskes: 'RSUD Dr. Soegiri',
      relawan: 'Budi Santoso',
      waktu: 'Hari ini, 09:14 WIB',
      status: 'SELESAI',
    ),
    const PenyaluranItem(
      nama: 'Bambang Sutrisno',
      golDarah: 'B+',
      jumlahKantong: 1,
      faskes: 'RS Muhammadiyah',
      relawan: 'Ahmad Fauzi',
      waktu: 'Kemarin, 14:30 WIB',
      status: 'SELESAI',
    ),
    const PenyaluranItem(
      nama: 'Siti Aminah',
      golDarah: 'A-',
      jumlahKantong: 1,
      faskes: 'RSUD Dr. Soegiri',
      relawan: 'Rina Wijaya',
      waktu: '6 Sep 2025 • 21:05 WIB',
      status: 'SELESAI',
    ),
    const PenyaluranItem(
      nama: 'Hendra Kusuma',
      golDarah: 'AB+',
      jumlahKantong: 2,
      faskes: 'Klinik Pratama',
      relawan: 'Nurul Hidayah',
      waktu: '5 Sep 2025 • 11:20 WIB',
      status: 'SELESAI',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fetchLaporanSummary();
  }

  Future<void> _fetchLaporanSummary() async {
    try {
      final summary = await _adminRepo.getReportsSummary();
      if (mounted) {
        setState(() {
          final totalReq = summary['total_requests'] as int?;
          final compReq = summary['completed_requests'] as int?;
          if (totalReq != null && totalReq > 0) {
            _totalRequests = totalReq;
          }
          if (compReq != null && compReq > 0) {
            _completedRequests = compReq;
          }
          final recent = summary['recent_requests'] as List?;
          if (recent != null && recent.isNotEmpty) {
            _allPenyaluran = recent.map((item) {
              final status = (item['status'] == 'terpenuhi' || item['status'] == 'selesai')
                  ? 'SELESAI'
                  : 'PENDING';
              return PenyaluranItem(
                nama: item['patient_name'] ?? 'Pasien',
                golDarah: item['blood_type'] ?? 'O+',
                jumlahKantong: item['bags'] ?? 1,
                faskes: item['hospital_name'] ?? 'RSUD Dr. Soegiri',
                relawan: 'Relawan Terverifikasi',
                waktu: item['created_at'] ?? 'Hari ini',
                status: status,
              );
            }).toList();
          }
          _totalVolumeKantong = _completedRequests > 0 ? _completedRequests * 2 : 286;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PenyaluranItem> get _filteredPenyaluran {
    if (_selectedFilter.startsWith('Semua')) return _allPenyaluran;
    if (_selectedFilter.startsWith('Darurat')) {
      return _allPenyaluran.where((p) => p.status == 'SELESAI').toList();
    }
    if (_selectedFilter.startsWith('Rhesus')) {
      return _allPenyaluran.where((p) => p.golDarah.contains('-')).toList();
    }
    return _allPenyaluran;
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
              _buildTopHeader(),
              const SizedBox(height: 22),
              _buildMetricCards(),
              const SizedBox(height: 24),
              _buildMainColumns(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TOP HEADER
  // ─────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Laporan & Rekapitulasi Darah',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Periode: September 2025 • Wilayah Kabupaten Lamongan',
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
            // Period Selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: InkWell(
                onTap: () {
                  _showPeriodPicker();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedPeriod,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),

            // Refresh Button
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Icon(Icons.sync_rounded, size: 18, color: Color(0xFF475569)),
            ),

            // Download Button
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mengunduh Laporan PDF/Excel...'),
                    backgroundColor: Color(0xFF059669),
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
              label: const Text(
                '+ Unduh Laporan (PDF/Excel)',
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
            children: [titleSection, actionButtons],
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
  // 4 METRIC CARDS
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

        final cards = [
          _buildMetricCard1(),
          _buildMetricCard2(),
          _buildMetricCard3(),
          _buildMetricCard4(),
        ];

        if (count == 4) {
          return Row(
            children: [
              for (int i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 14),
                Expanded(child: cards[i]),
              ],
            ],
          );
        } else if (count == 2) {
          return Column(
            children: [
              Row(children: [
                Expanded(child: cards[0]),
                const SizedBox(width: 14),
                Expanded(child: cards[1]),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: cards[2]),
                const SizedBox(width: 14),
                Expanded(child: cards[3]),
              ]),
            ],
          );
        } else {
          return Column(
            children: [
              for (int i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                cards[i],
              ],
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

  // Card 1: Total Permintaan Masuk
  Widget _buildMetricCard1() {
    return _metricBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Permintaan Masuk',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.description_outlined, size: 16, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$_totalRequests',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              const SizedBox(width: 6),
              const Text(
                'Permintaan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              const Text(
                '+18% vs bln\nlalu',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF10B981), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 2: Tingkat Pemenuhan
  Widget _buildMetricCard2() {
    final pct = _totalRequests > 0
        ? ((_completedRequests / _totalRequests) * 100).toStringAsFixed(1)
        : '94.2';
    return _metricBaseCard(
      borderColor: const Color(0xFFA7F3D0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tingkat Pemenuhan',
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF065F46)),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.check_circle_outline_rounded, size: 16, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                pct,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF059669), letterSpacing: -0.5),
              ),
              const Text(
                '%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
              ),
              const Spacer(),
              Text(
                '$_completedRequests Permintaan\nTerpenuhi',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF059669), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 3: Rata-rata Waktu Respons
  Widget _buildMetricCard3() {
    return _metricBaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rata-rata Waktu Respons',
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
                '9.8',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.5),
              ),
              const SizedBox(width: 6),
              const Text(
                'Menit',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              const Text(
                'Emergency dispatch\ncepat',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 4: Total Volume Tersalur
  Widget _buildMetricCard4() {
    return _metricBaseCard(
      borderColor: const Color(0xFFFECDD3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Volume Tersalur',
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
              Text(
                '$_totalVolumeKantong',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFDC2626), letterSpacing: -0.5),
              ),
              const SizedBox(width: 6),
              const Text(
                'Kantong',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
              ),
              const Spacer(),
              const Text(
                'A:64 • B:82 • O:118\n• AB:22',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFFDC2626), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TWO-COLUMN LAYOUT
  // ─────────────────────────────────────────────────────────
  Widget _buildMainColumns() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 920;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 12, child: _buildLeftPanel()),
              const SizedBox(width: 20),
              Expanded(flex: 11, child: _buildRightPanel()),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeftPanel(),
              const SizedBox(height: 24),
              _buildRightPanel(),
            ],
          );
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // LEFT PANEL: BAR CHART + FASKES RANKING
  // ─────────────────────────────────────────────────────────
  Widget _buildLeftPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTrendChart(),
        const SizedBox(height: 20),
        _buildFaskesRanking(),
      ],
    );
  }

  Widget _buildTrendChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    'TREN PERMINTAAN & KETERSEDIAAN HARIAN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const Text(
                '7 Hari Terakhir',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Legend Row
          Row(
            children: [
              _legendDot(const Color(0xFFDC2626), 'Permintaan'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF10B981), 'Terpenuhi'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  'Rata-rata 94% Terpenuhi',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Bar Chart
          SizedBox(
            height: 160,
            child: CustomPaint(
              size: const Size(double.infinity, 160),
              painter: _BarChartPainter(data: _trendData),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFaskesRanking() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'FASKES DENGAN PERMINTAAN TERBANYAK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: 0.5,
                ),
              ),
              const Text(
                '4 Fasilitas Utama',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ranking List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _faskesRanking.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _faskesRanking[index];
              return _buildRankItem(item);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRankItem(FaskesRankItem item) {
    final efisiensiVal = (item.terpenuhi / item.permintaan * 100).round();
    Color efBg;
    Color efText;
    if (efisiensiVal >= 98) {
      efBg = const Color(0xFFD1FAE5);
      efText = const Color(0xFF065F46);
    } else if (efisiensiVal >= 94) {
      efBg = const Color(0xFFECFDF5);
      efText = const Color(0xFF059669);
    } else {
      efBg = const Color(0xFFFEF3C7);
      efText = const Color(0xFFB45309);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Rank Badge
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: item.rank == 1 ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                '${item.rank}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: item.rank == 1 ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nama,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.permintaan} Permintaan • ${item.terpenuhi} Terpenuhi',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Efisiensi Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: efBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: efText.withOpacity(0.2)),
            ),
            child: Text(
              'Efisiensi $efisiensiVal%',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: efText),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // RIGHT PANEL: RIWAYAT PENYALURAN TERAKHIR
  // ─────────────────────────────────────────────────────────
  Widget _buildRightPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                    'RIWAYAT PENYALURAN TERAKHIR',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 10.5, fontFamily: 'monospace'),
                  children: [
                    TextSpan(
                      text: 'TOTAL : ',
                      style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                    TextSpan(
                      text: '142',
                      style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.w900),
                    ),
                    TextSpan(
                      text: '  DATA',
                      style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterChip('Semua (142)'),
                const SizedBox(width: 6),
                _filterChip('Darurat Terpenuhi (134)'),
                const SizedBox(width: 6),
                _filterChip('Rhesus Negatif (8)'),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Penyaluran List
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _filteredPenyaluran.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: const Color(0xFFE2E8F0).withOpacity(0.7)),
            itemBuilder: (context, index) {
              final item = _filteredPenyaluran[index];
              return _buildPenyaluranItem(item);
            },
          ),
          const SizedBox(height: 20),

          // Bottom Action Buttons
          Row(
            children: [
              // Lihat Semua Log
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Membuka log penyaluran lengkap...'),
                        backgroundColor: Color(0xFF475569),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.format_list_bulleted_rounded, size: 16, color: Color(0xFF475569)),
                      SizedBox(width: 8),
                      Text(
                        'Lihat Semua Log Penyaluran\n(142 Data)',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF475569), height: 1.3),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Cetak Berita Acara PMI
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mencetak Berita Acara PMI...'),
                      backgroundColor: Color(0xFFDC2626),
                    ),
                  );
                },
                icon: const Icon(Icons.print_rounded, size: 16, color: Colors.white),
                label: const Text(
                  'Cetak Berita Acara PMI',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label) {
    final isSelected = _selectedFilter == label;
    final isDarurat = label.contains('Darurat');
    final isRhesus = label.contains('Rhesus');

    Color bgColor;
    Color textColor;
    Color borderColor;

    if (isSelected) {
      bgColor = const Color(0xFF0F172A);
      textColor = Colors.white;
      borderColor = const Color(0xFF0F172A);
    } else if (isDarurat) {
      bgColor = Colors.white;
      textColor = const Color(0xFF059669);
      borderColor = const Color(0xFFA7F3D0);
    } else if (isRhesus) {
      bgColor = Colors.white;
      textColor = const Color(0xFFDC2626);
      borderColor = const Color(0xFFFECDD3);
    } else {
      bgColor = Colors.white;
      textColor = const Color(0xFF64748B);
      borderColor = const Color(0xFFE2E8F0);
    }

    return InkWell(
      onTap: () => setState(() => _selectedFilter = label),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPenyaluranItem(PenyaluranItem item) {
    Color golBg;
    Color golText;
    if (item.golDarah.contains('-')) {
      golBg = const Color(0xFFFEE2E2);
      golText = const Color(0xFFDC2626);
    } else if (item.golDarah.startsWith('O')) {
      golBg = const Color(0xFFFEE2E2);
      golText = const Color(0xFFDC2626);
    } else if (item.golDarah.startsWith('A')) {
      golBg = const Color(0xFFEFF6FF);
      golText = const Color(0xFF2563EB);
    } else if (item.golDarah.startsWith('B')) {
      golBg = const Color(0xFFF0FDF4);
      golText = const Color(0xFF059669);
    } else {
      golBg = const Color(0xFFFEF3C7);
      golText = const Color(0xFFB45309);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.nama,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: golBg,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        'Gol. ${item.golDarah} (${item.jumlahKantong} Ktg)',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: golText),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.faskes} • Relawan: ${item.relawan}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  item.waktu,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),

          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: item.status == 'SELESAI' ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: item.status == 'SELESAI' ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
              ),
            ),
            child: Text(
              item.status,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: item.status == 'SELESAI' ? const Color(0xFF059669) : const Color(0xFFD97706),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showPeriodPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Color(0xFF2563EB)),
            SizedBox(width: 8),
            Text('Pilih Periode Laporan'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _periodOption(ctx, 'Bulan Ini (Sep 2025)'),
            _periodOption(ctx, 'Bulan Lalu (Agu 2025)'),
            _periodOption(ctx, 'Q3 2025 (Jul-Sep)'),
            _periodOption(ctx, 'Semester 1 2025'),
            _periodOption(ctx, 'Tahun 2025'),
          ],
        ),
      ),
    );
  }

  Widget _periodOption(BuildContext ctx, String label) {
    final isSelected = _selectedPeriod == label;
    return InkWell(
      onTap: () {
        setState(() => _selectedPeriod = label);
        Navigator.pop(ctx);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// CUSTOM BAR CHART PAINTER
// ─────────────────────────────────────────────────────────
class _BarChartPainter extends CustomPainter {
  final List<DailyTrendData> data;

  _BarChartPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxVal = data.map((d) => max(d.permintaan, d.terpenuhi)).reduce(max).toDouble();
    final barAreaHeight = size.height - 30; // Leave room for labels
    final groupWidth = size.width / data.length;
    final barWidth = groupWidth * 0.25;
    final gap = 3.0;

    final permintaanPaint = Paint()..color = const Color(0xFFDC2626);
    final terpenuhiPaint = Paint()..color = const Color(0xFF10B981);
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF94A3B8),
    );

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final centerX = groupWidth * i + groupWidth / 2;

      // Permintaan bar (left)
      final pH = (d.permintaan / maxVal) * barAreaHeight;
      final pRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX - barWidth - gap / 2, barAreaHeight - pH, barWidth, pH),
        const Radius.circular(4),
      );
      canvas.drawRRect(pRect, permintaanPaint);

      // Terpenuhi bar (right)
      final tH = (d.terpenuhi / maxVal) * barAreaHeight;
      final tRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(centerX + gap / 2, barAreaHeight - tH, barWidth, tH),
        const Radius.circular(4),
      );
      canvas.drawRRect(tRect, terpenuhiPaint);

      // Day label
      final textPainter = TextPainter(
        text: TextSpan(text: d.day, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      textPainter.paint(
        canvas,
        Offset(centerX - textPainter.width / 2, barAreaHeight + 10),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
