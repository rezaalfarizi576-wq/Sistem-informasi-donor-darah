import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../routes/app_router.dart';

class DonorDispatchScreen extends StatefulWidget {
  final VoidCallback? onNavigateToRadar;
  final VoidCallback? onNavigateToBank;
  final VoidCallback? onNavigateToProfile;

  const DonorDispatchScreen({
    super.key,
    this.onNavigateToRadar,
    this.onNavigateToBank,
    this.onNavigateToProfile,
  });

  @override
  State<DonorDispatchScreen> createState() => _DonorDispatchScreenState();
}

class _DonorDispatchScreenState extends State<DonorDispatchScreen> {
  // Koordinat Lamongan untuk mini live tracking
  final LatLng _donorPos = const LatLng(-7.1245, 112.4150);
  final LatLng _faskesPos = const LatLng(-7.1190, 112.4195);
  final List<LatLng> _routePoints = const [
    LatLng(-7.1245, 112.4150),
    LatLng(-7.1235, 112.4162),
    LatLng(-7.1215, 112.4180),
    LatLng(-7.1190, 112.4195),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. TOP HEADER (PMI LAMONGAN Dispatch) ──
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
                          'Dispatch',
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
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Membuka pusat notifikasi...', style: GoogleFonts.plusJakartaSans()),
                                behavior: SnackBarBehavior.floating,
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
                    // Profile avatar
                    GestureDetector(
                      onTap: widget.onNavigateToProfile,
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

              const SizedBox(height: 12),

              // ── 2. CARD MISI DISPATCH AKTIF ──
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
                      // Header Card: Status Aktif & ID Penugasan
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFFDC2626),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'MISI DISPATCH AKTIF',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFDC2626),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
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
                                '#DSP-2025-0908',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 1, color: Color(0xFFF1F5F9)),

                      // Detail Rumah Sakit & Badge Darah
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FASILITAS TUJUAN',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'RSUD Dr. Soegiri Lamongan',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.hotel_rounded, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 5),
                                      Expanded(
                                        child: Text(
                                          'ICU Bed 03 • Pasien: Ny. Dewi Rahayu',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            color: const Color(0xFF64748B),
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
                            const SizedBox(width: 10),
                            // Badge Golongan Darah Kotak Gelap
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'O+',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'WHOLE\nBLOOD',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(alpha: 0.8),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w700,
                                      height: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Box Estimasi Waktu & Urgensi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFECDD3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.timer_outlined, color: Color(0xFFDC2626), size: 18),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '~8 Menit (3.8 km tersisa)',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        width: 5,
                                        height: 5,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF16A34A),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Menuju Faskes Rujukan',
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
                              const Spacer(),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Prioritas',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 9.5,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  Text(
                                    'Kritis P1',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Tombol Aksi: Buka Rute & Petugas UTD
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    AppRouter.donorLiveTrackingRoute,
                                    arguments: '1',
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFDC2626),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.near_me_rounded, size: 16),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Buka Rute',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Menghubungi Petugas Posko UTD Lamongan: (0322) 321-118...', style: GoogleFonts.plusJakartaSans()),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: const Color(0xFFF1F5F9),
                                  foregroundColor: const Color(0xFF1E293B),
                                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                                  padding: const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.phone_outlined, size: 16, color: Color(0xFF1E293B)),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Petugas UTD',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1E293B),
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
              ),

              const SizedBox(height: 14),

              // ── 3. GPS AKURAT & PETA RUTE AKTIF (LIVE TRACKING) ──
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
                      // Top indicator GPS
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        color: const Color(0xFFF0FDF4),
                        child: Row(
                          children: [
                            const Icon(Icons.satellite_alt_rounded, size: 15, color: Color(0xFF16A34A)),
                            const SizedBox(width: 6),
                            Text(
                              'GPS Akurat (±2m) • UTD Command Link Active',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDCFCE7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'LIVE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF16A34A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Peta Mini Interaktif (FlutterMap)
                      SizedBox(
                        height: 140,
                        child: Stack(
                          children: [
                            FlutterMap(
                              options: const MapOptions(
                                initialCenter: LatLng(-7.1215, 112.4175),
                                initialZoom: 14.5,
                                minZoom: 12.0,
                                maxZoom: 17.0,
                                interactionOptions: InteractionOptions(
                                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                                ),
                              ),
                              children: [
                                TileLayer(
                                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'id.pmi.donordarah.lamongan',
                                ),
                                PolylineLayer(
                                  polylines: [
                                    Polyline(
                                      points: _routePoints,
                                      strokeWidth: 4.5,
                                      color: const Color(0xFFDC2626),
                                    ),
                                  ],
                                ),
                                MarkerLayer(
                                  markers: [
                                    // Marker Posisi Pendonor
                                    Marker(
                                      point: _donorPos,
                                      width: 32,
                                      height: 32,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF2563EB),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 16),
                                      ),
                                    ),
                                    // Marker RSUD Tujuan
                                    Marker(
                                      point: _faskesPos,
                                      width: 36,
                                      height: 36,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDC2626),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.local_hospital_rounded, color: Colors.white, size: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Floating status lalu lintas bawah
                            Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.traffic_rounded, color: Color(0xFF4ADE80), size: 13),
                                      const SizedBox(width: 5),
                                      Text(
                                        'Jl. Kusuma Bangsa (Lancar)',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
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

              // ── 4. TIKET FAST-TRACK DONOR ──
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
                      // Header Tiket
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF1F2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.shield_outlined, color: Color(0xFFDC2626), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tiket Fast-Track Donor',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  'Akses prioritas bebas antrean pendaftaran',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFA7F3D0),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'JALUR BEBAS\nANTRE',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFF065F46),
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Box QR Code Triase Digital
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'KODE TRIASE DIGITAL',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF64748B),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  'TGP-2025-0908-0847',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Komponen QR Code Custom
                            const _FastTrackQrWidget(),

                            const SizedBox(height: 12),
                            Text(
                              'Tunjukkan QR Code ini langsung kepada barcode scanner meja triase UTD / IGD RSUD Dr. Soegiri.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
                                color: const Color(0xFF64748B),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 3 Langkah Cepat Saat Tiba
                      Text(
                        '3 LANGKAH CEPAT SAAT TIBA',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF334155),
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),

                      _buildLangkahItem(
                        number: '1',
                        title: 'Masuk Gate Khusus UTD PMI / IGD',
                        subtitle: 'Parkir kendaraan di zona kuning donor darurat depan lobi barat.',
                      ),
                      const SizedBox(height: 8),
                      _buildLangkahItem(
                        number: '2',
                        title: 'Pindai QR Fast-Track',
                        subtitle: 'Petugas langsung mencetak gelang donor tanpa pengisian formulir manual ulang.',
                      ),
                      const SizedBox(height: 8),
                      _buildLangkahItem(
                        number: '3',
                        title: 'Pemeriksaan HB & Pengambilan Darah',
                        subtitle: 'Langsung diarahkan ke Bed Apheresis / Donor Eksternal 01.',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ── 5. RIWAYAT MISI PENUGASAN ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Riwayat Misi Penugasan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '2 Selesai',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Misi 1
                    _buildRiwayatMisiCard(
                      badgeText: 'Berhasil Transfusi',
                      badgeBg: const Color(0xFFDCFCE7),
                      badgeColor: const Color(0xFF16A34A),
                      timestamp: '12 Mar 2025 • 14:20 WIB',
                      hospitalName: 'RS Muhammadiyah Lamongan',
                      details: 'Volume: 450 mL O+ • ID: #DSP-2025-0411',
                      isSuccess: true,
                    ),
                    const SizedBox(height: 10),
                    // Misi 2
                    _buildRiwayatMisiCard(
                      badgeText: 'Selesai Donor',
                      badgeBg: const Color(0xFFF1F5F9),
                      badgeColor: const Color(0xFF475569),
                      timestamp: '15 Nov 2024 • 09:15 WIB',
                      hospitalName: 'RSUD Dr. Soegiri Lamongan',
                      details: 'Volume: 350 mL O+ • ID: #DSP-2024-1102',
                      isSuccess: false,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 6. PROTOKOL KESELAMATAN & SOP ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.security_rounded, color: Color(0xFFDC2626), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      'Protokol Keselamatan & SOP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildSopCard(
                      icon: Icons.speed_rounded,
                      iconBg: const Color(0xFFEEF2FF),
                      iconColor: const Color(0xFF4F46E5),
                      title: 'Patuhi Batas Kecepatan',
                      subtitle: 'Keselamatan Anda utama. Jangan menerobos lampu merah tanpa pengawalan resmi.',
                    ),
                    const SizedBox(height: 8),
                    _buildSopCard(
                      icon: Icons.water_drop_outlined,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Hidrasi Pra-Penugasan',
                      subtitle: 'Konsumsi minimal 500 mL air putih sebelum tindakan pengambilan darah.',
                    ),
                    const SizedBox(height: 8),
                    _buildSopCard(
                      icon: Icons.badge_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Bawa Kartu Identitas Fisik',
                      subtitle: 'KTP/SIM asli tetap dibutuhkan untuk verifikasi akhir Sistem SIMDONDAR.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── 7. HOTLINE DARURAT PMI 24 JAM ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFB91C1C), Color(0xFFDC2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFDC2626).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.phone_in_talk_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOTLINE DARURAT PMI 24 JAM',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '(0322) 321-118 / 0811-332-990',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Menghubungi hotline darurat PMI Lamongan: (0322) 321-118...', style: GoogleFonts.plusJakartaSans()),
                              backgroundColor: const Color(0xFFB91C1C),
                              behavior: SnackBarBehavior.floating,
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
                          children: [
                            const Icon(Icons.phone_rounded, color: Color(0xFFDC2626), size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Panggil',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFFDC2626),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
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
    );
  }

  // ─── Helper: Langkah Cepat Item ───
  Widget _buildLangkahItem({
    required String number,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: const BoxDecoration(
              color: Color(0xFFDC2626),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
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
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Helper: Riwayat Misi Card ───
  Widget _buildRiwayatMisiCard({
    required String badgeText,
    required Color badgeBg,
    required Color badgeColor,
    required String timestamp,
    required String hospitalName,
    required String details,
    required bool isSuccess,
  }) {
    return Container(
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
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  badgeText,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: badgeColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                timestamp,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hospitalName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helper: SOP Item Card ───
  Widget _buildSopCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    fontSize: 12,
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
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Custom Widget: QR Code Fast-Track dengan emblem kunci di tengah ───
class _FastTrackQrWidget extends StatelessWidget {
  const _FastTrackQrWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      height: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(150, 150),
            painter: _QrPatternPainter(),
          ),
          // Emblem merah tengah (gembok/kunci)
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.lock_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _QrPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    const int gridSize = 21;
    final double cellSize = size.width / gridSize;

    // Pola dummy QR Code terstruktur dengan 3 finder pattern di sudut
    void drawFinderPattern(double x, double y) {
      // Outer 7x7
      canvas.drawRect(Rect.fromLTWH(x, y, 7 * cellSize, 7 * cellSize), paint);
      // Inner space 5x5
      canvas.drawRect(
        Rect.fromLTWH(x + cellSize, y + cellSize, 5 * cellSize, 5 * cellSize),
        Paint()..color = Colors.white,
      );
      // Center solid 3x3
      canvas.drawRect(
        Rect.fromLTWH(x + 2 * cellSize, y + 2 * cellSize, 3 * cellSize, 3 * cellSize),
        paint,
      );
    }

    // 3 Sudut Finder
    drawFinderPattern(0, 0);
    drawFinderPattern((gridSize - 7) * cellSize, 0);
    drawFinderPattern(0, (gridSize - 7) * cellSize);

    // Timing strips
    for (int i = 8; i < gridSize - 8; i++) {
      if (i % 2 == 0) {
        canvas.drawRect(Rect.fromLTWH(i * cellSize, 6 * cellSize, cellSize, cellSize), paint);
        canvas.drawRect(Rect.fromLTWH(6 * cellSize, i * cellSize, cellSize, cellSize), paint);
      }
    }

    // Data points acak beraturan untuk menyerupai QR sesungguhnya
    final patternPoints = [
      [8, 2], [9, 3], [11, 2], [12, 4], [8, 7], [10, 8], [12, 8],
      [2, 8], [3, 10], [5, 8], [4, 11], [1, 12], [3, 13],
      [14, 8], [16, 9], [18, 8], [20, 10], [15, 12], [17, 11],
      [8, 14], [10, 15], [9, 18], [11, 20], [8, 19],
      [14, 14], [15, 16], [18, 15], [19, 18], [16, 19], [14, 20],
      [18, 2], [20, 4], [14, 4], [16, 1], [18, 5],
      [2, 14], [4, 16], [5, 19], [1, 18], [4, 20],
      [11, 11], [12, 10], [10, 12], [13, 13]
    ];

    for (final pt in patternPoints) {
      canvas.drawRect(
        Rect.fromLTWH(pt[0] * cellSize, pt[1] * cellSize, cellSize, cellSize),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
