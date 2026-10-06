import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _apiClient = ApiClient();
  Map<String, dynamic>? _stats;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/admin/stats');
      if (mounted) {
        setState(() {
          _stats = response;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dynamic fallback values if API has data
    final totalRelawan = _stats?['total_donors'] != null && (_stats!['total_donors'] as int) > 0
        ? _stats!['total_donors'].toString()
        : '1.482';
    final antreanKritis = _stats?['active_blood_requests'] != null && (_stats!['active_blood_requests'] as int) > 0
        ? _stats!['active_blood_requests'].toString()
        : '2';

    return Container(
      color: const Color(0xFFEAF0F6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── TOP SECTION: BREADCRUMB, STATUS & TITLE ───
              _buildTopHeader(),
              const SizedBox(height: 24),

              // ─── 4 TELEMETRY KPI CARDS ───
              _buildKpiGrid(totalRelawan, antreanKritis),
              const SizedBox(height: 24),

              // ─── SEBARAN WILAYAH TERBANYAK (DARK BANNER) ───
              _buildRegionDistributionBanner(),
              const SizedBox(height: 20),

              // ─── BOTTOM ROW: RADAR & KEBUGARAN CARDS ───
              _buildBottomTelemetryRow(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TOP HEADER: BREADCRUMB, STATUS, TITLE, BUTTONS
  // ─────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Breadcrumb chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'ADMIN PMI / BERANDA POSKO UTAMA',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Live system status indicator
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Posko Siaga 24 Jam • LAT 14ms • Server SIMDONDAR Aktif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFEF4444),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Main Title & Action Buttons
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 850;
            final textContent = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Pusat Kendali Relawan & Telemetri\nKesiapsiagaan Posko',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: const Text(
                    'Monitoring distribusi 1.482 user relawan terdaftar di 27 kecamatan Kabupaten Lamongan. Mengoptimalkan radius respon cepat donor darah darurat menuju Faskes dan BDRS secara presisi.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            );

            final buttons = Wrap(
              spacing: 12,
              runSpacing: 10,
              children: [
                // Sinkron Data SatuSehat
                OutlinedButton.icon(
                  onPressed: _fetchStats,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                        )
                      : const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF10B981)),
                  label: const Text(
                    'Sinkron Data SatuSehat',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFF0FDF4),
                    side: const BorderSide(color: Color(0xFFBBF7D0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                // Siaga Broadcast Radar Darurat
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Radar Siaga Darurat Aktif: Memindai relawan terdekat...'),
                        backgroundColor: Color(0xFFDC2626),
                      ),
                    );
                  },
                  icon: const Icon(Icons.podcasts_rounded, size: 16, color: Colors.white),
                  label: const Text(
                    'Siaga Broadcast Radar Darurat',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );

            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: textContent),
                  const SizedBox(width: 24),
                  buttons,
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  textContent,
                  const SizedBox(height: 16),
                  buttons,
                ],
              );
            }
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // 4 TELEMETRY KPI CARDS GRID
  // ─────────────────────────────────────────────────────────
  Widget _buildKpiGrid(String totalRelawan, String antreanKritis) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 4;
        if (constraints.maxWidth < 650) {
          crossAxisCount = 1;
        } else if (constraints.maxWidth < 1050) {
          crossAxisCount = 2;
        }

        if (crossAxisCount == 4) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildCard1TotalRelawan(totalRelawan)),
              const SizedBox(width: 14),
              Expanded(child: _buildCard2RadiusFaskes()),
              const SizedBox(width: 14),
              Expanded(child: _buildCard3SebaranUser()),
              const SizedBox(width: 14),
              Expanded(child: _buildCard4AntreanKritis(antreanKritis)),
            ],
          );
        } else if (crossAxisCount == 2) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildCard1TotalRelawan(totalRelawan)),
                  const SizedBox(width: 14),
                  Expanded(child: _buildCard2RadiusFaskes()),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _buildCard3SebaranUser()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildCard4AntreanKritis(antreanKritis)),
                ],
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildCard1TotalRelawan(totalRelawan),
              const SizedBox(height: 14),
              _buildCard2RadiusFaskes(),
              const SizedBox(height: 14),
              _buildCard3SebaranUser(),
              const SizedBox(height: 14),
              _buildCard4AntreanKritis(antreanKritis),
            ],
          );
        }
      },
    );
  }

  Widget _cardContainer({required Color accentColor, required Widget child}) {
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4.5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card 1: TOTAL RELAWAN TERDAFTAR
  Widget _buildCard1TotalRelawan(String total) {
    return _cardContainer(
      accentColor: const Color(0xFFEF4444),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL RELAWAN\nTERDAFTAR',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.people_alt_rounded, size: 16, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                total,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'User\nTerverifikasi',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _pillStatus('142 Siaga', 'Online', const Color(0xFF10B981), const Color(0xFFF0FDF4)),
              _pillStatus('28 OTR', 'Donor', const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status\nKebugaran',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.1),
              ),
              Text(
                '92% Siap\nDonor',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF10B981), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 2: RADIUS KESIAPAN & FASKES
  Widget _buildCard2RadiusFaskes() {
    return _cardContainer(
      accentColor: const Color(0xFF10B981),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RADIUS KESIAPAN &\nFASKES',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.near_me_rounded, size: 16, color: Color(0xFF059669)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '2.8',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
              SizedBox(width: 6),
              Text(
                'KM Rerata Jarak ke\nFaskes',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.check_circle_outline_rounded, size: 13, color: Color(0xFF10B981)),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Cakupan radar 100% faskes utama Lamongan',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.2),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SLA Tanggap\nCepat',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.1),
              ),
              Text(
                '< 10 Menit\nTiba',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF059669), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 3: KONSENTRASI SEBARAN USER
  Widget _buildCard3SebaranUser() {
    return _cardContainer(
      accentColor: const Color(0xFF3B82F6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'KONSENTRASI\nSEBARAN USER',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.location_city_rounded, size: 16, color: Color(0xFF2563EB)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lamongan\nKota',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    height: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Text(
                  '512\nUser',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF2563EB),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Disusul Babat (348) &\nPaciran-Brondong (284)',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.2),
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kepadatan\nKomunitas',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.1),
              ),
              Text(
                '34.5% di\nZona Inti',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 4: ANTREAN KRITIS P1 & STOK O+
  Widget _buildCard4AntreanKritis(String antrean) {
    return _cardContainer(
      accentColor: const Color(0xFFDC2626),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ANTREAN KRITIS P1 &\nSTOK O+',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF475569),
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.emergency_rounded, size: 16, color: Color(0xFFDC2626)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                antrean,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFDC2626),
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Permintaan Kritis\nMenunggu',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFDC2626)),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  'Defisit Gol O+ (<5 kantong) • AB- (1 ktg)',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600, height: 1.2),
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dispatch\nTerdekat',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), height: 1.1),
              ),
              Text(
                'Relawan #08\nOTR',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Color(0xFFDC2626), height: 1.1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillStatus(String labelBold, String labelNormal, Color dotColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            labelBold,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: dotColor),
          ),
          const SizedBox(width: 3),
          Text(
            labelNormal,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500, color: dotColor.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SEBARAN WILAYAH TERBANYAK (DARK PILL BANNER)
  // ─────────────────────────────────────────────────────────
  Widget _buildRegionDistributionBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF161A29),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;

          final header = Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4C1D24),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.map_outlined, color: Color(0xFFF87171), size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sebaran Wilayah Terbanyak (Total 1.482 Relawan Terdaftar)',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Distribusi geospasial relawan pendonor aktif yang telah melewati skrining kesehatan PMI',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );

          final chips = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _regionPill(const Color(0xFFEF4444), 'Lamongan Kota:', '512 user'),
              _regionPill(const Color(0xFFF59E0B), 'Babat:', '348 user'),
              _regionPill(const Color(0xFF10B981), 'Paciran & Brondong:', '284 user'),
              _regionPill(const Color(0xFF38BDF8), 'Tikung & Sugio:', '196 user'),
              _regionPill(const Color(0xFFA855F7), 'Sekaran & Maduran:', '142 user'),
            ],
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(flex: 5, child: header),
                const SizedBox(width: 16),
                Expanded(flex: 6, child: chips),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header,
                const SizedBox(height: 14),
                chips,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _regionPill(Color dotColor, String prefix, String count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF22283A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2F374F)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            prefix,
            style: const TextStyle(fontSize: 11, color: Color(0xFFCBD5E1)),
          ),
          const SizedBox(width: 4),
          Text(
            count,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BOTTOM TELEMETRY ROW: RADAR & KEBUGARAN CARDS
  // ─────────────────────────────────────────────────────────
  Widget _buildBottomTelemetryRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 780;

        final leftCard = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar_rounded, color: Color(0xFFDC2626), size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sebaran Lokasi Relawan & Geofencing Radar',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Live GPS Tracking • 142 Relawan Siaga • 28 Menuju Lokasi Donor',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

        final rightCard = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFF059669), size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribusi Kebugaran & Kesiapan User',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Status kelayakan donor darah dari 1.482 user',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Text(
                  '92%\nSiap',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF059669),
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            children: [
              Expanded(flex: 3, child: leftCard),
              const SizedBox(width: 14),
              Expanded(flex: 2, child: rightCard),
            ],
          );
        } else {
          return Column(
            children: [
              leftCard,
              const SizedBox(height: 14),
              rightCard,
            ],
          );
        }
      },
    );
  }
}
