import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/routing_service.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../data/repositories/tracking_repository.dart';
import '../../../routes/app_router.dart';

class RequesterTrackingScreen extends StatefulWidget {
  final String? requestId;
  final VoidCallback? onNavigateToRequest;
  final VoidCallback? onNavigateToProfile;

  const RequesterTrackingScreen({
    super.key,
    this.requestId,
    this.onNavigateToRequest,
    this.onNavigateToProfile,
  });

  @override
  State<RequesterTrackingScreen> createState() => _RequesterTrackingScreenState();
}

class _RequesterTrackingScreenState extends State<RequesterTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _requestRepo = BloodRequestRepository();
  final _trackingRepo = TrackingRepository();
  final _routingService = RoutingService();
  final MapController _mapController = MapController();

  BloodRequestModel? _activeRequest;
  bool _isLoading = true;
  int _selectedTabIndex = 1; // Aktif di tab 1: Pantau

  // Koordinat Faskes RSUD Dr. Soegiri Lamongan
  static const LatLng _hospitalLocation = LatLng(-7.1159, 112.4103);
  // Titik awal donor di Jl. Basuki Rahmat Lamongan
  static const LatLng _startDonorLocation = LatLng(-7.132500, 112.418200);

  LatLng _volunteerLocation = _startDonorLocation;
  List<LatLng> _routePoints = [];

  StreamSubscription? _locationSubscription;
  Timer? _simTimer;
  double _simProgress = 0.35; // Posisi relawan sudah bergerak mendekati RSUD

  String _distanceKm = '1.4 km';
  String _etaMinutes = '~6 Menit';
  final String _speedText = '24 km/jam';
  String _hospitalName = 'RSUD Dr. Soegiri';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initScreenData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simTimer?.cancel();
    _locationSubscription?.cancel();
    _trackingRepo.stopTracking();
    super.dispose();
  }

  bool get _hasAcceptedDonor {
    if (_activeRequest == null) return false;
    if (_activeRequest!.donorName != null && _activeRequest!.donorName!.isNotEmpty) {
      return true;
    }
    final s = _activeRequest!.status.toLowerCase();
    return s == 'diproses' || s == 'diterima' || s == 'menuju_lokasi' || s == 'sampai';
  }

  Future<void> _initScreenData() async {
    final reqIdStr = widget.requestId ?? '1';

    // 1. Hubungkan WebSocket untuk pelacakan live dari relawan
    _trackingRepo.startTracking(reqIdStr);
    _locationSubscription = _trackingRepo.locationStream?.listen((data) {
      if (data is Map && mounted) {
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          setState(() {
            _volunteerLocation = LatLng(lat, lng);
          });
        }
      }
    });

    // 2. Ambil data permohonan darah
    try {
      BloodRequestModel? req;
      if (widget.requestId != null && int.tryParse(widget.requestId!) != null) {
        req = await _requestRepo.getRequestById(int.parse(widget.requestId!));
      } else {
        final allReqs = await _requestRepo.getRequests();
        if (allReqs.isNotEmpty) {
          req = allReqs.firstWhere(
            (r) => r.status == 'diproses' || r.status == 'menunggu' || r.urgencyLevel == 'kritis',
            orElse: () => allReqs.first,
          );
        }
      }

      if (mounted && req != null) {
        setState(() {
          _activeRequest = req;
          _hospitalName = req!.hospitalName ?? 'RSUD Dr. Soegiri';
        });
      }
    } catch (_) {}

    // 3. Hanya load rute jalan & jalankan simulasi pergerakan JIKA sudah ada relawan yang setuju
    if (_hasAcceptedDonor) {
      await _fetchRoadRoute();
      _startSmoothSimulation();
    } else {
      _simTimer?.cancel();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRoadRoute() async {
    try {
      final route = await _routingService.getRoadRoute(_startDonorLocation, _hospitalLocation);
      if (mounted && route.points.isNotEmpty) {
        setState(() {
          _routePoints = route.points;
          final idx = (_simProgress * (_routePoints.length - 1)).toInt();
          _volunteerLocation = _routePoints[idx];
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _routePoints = [
            _startDonorLocation,
            const LatLng(-7.128000, 112.418200),
            const LatLng(-7.120000, 112.412000),
            _hospitalLocation,
          ];
          _volunteerLocation = const LatLng(-7.120000, 112.412000);
        });
      }
    }
  }

  void _startSmoothSimulation() {
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted || _routePoints.length < 2) return;

      _simProgress += 0.04;
      if (_simProgress >= 0.95) {
        _simProgress = 0.92;
      }

      final index = (_simProgress * (_routePoints.length - 1)).clamp(0, _routePoints.length - 1).toInt();
      final currentPos = _routePoints[index];

      setState(() {
        _volunteerLocation = currentPos;
        final remDist = (1.4 * (1.0 - _simProgress)).clamp(0.2, 1.4);
        _distanceKm = '${remDist.toStringAsFixed(1)} km';
        final remMnt = (6 * (1.0 - _simProgress)).ceil().clamp(1, 6);
        _etaMinutes = '~$remMnt Menit';
      });
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == _selectedTabIndex) return;

    setState(() => _selectedTabIndex = index);

    if (index == 0) {
      if (widget.onNavigateToRequest != null) {
        widget.onNavigateToRequest!();
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.requesterRequestRoute);
      }
    } else if (index == 2) {
      if (widget.onNavigateToProfile != null) {
        widget.onNavigateToProfile!();
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.requesterProfileRoute);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDonor = _hasAcceptedDonor;

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
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ─── 1. HEADER APP BAR (PMI LAMONGAN DARURAT & PANTAU) ───
                          _buildHeader(),
                          const SizedBox(height: 12),

                          if (!hasDonor) ...[
                            // ─── KONDISI BELUM ADA PEN DONOR (STATUS: MENUNGGU) ───
                            _buildSearchingBanner(),
                            const SizedBox(height: 12),

                            // Peta Radius Radar (Tanpa rute motor / tanpa Budi Santoso)
                            _buildSearchingMapSection(),
                            const SizedBox(height: 14),

                            // Kartu Status: Menunggu Respon Pendonor
                            _buildSearchingVolunteerCard(),
                            const SizedBox(height: 14),
                          ] else ...[
                            // ─── KONDISI SUDAH ADA PENDONOR MENYETUJUI (STATUS: DIPROSES) ───
                            _buildStatusBanner(),
                            const SizedBox(height: 12),

                            // Peta Rute GPS Jalan Raya & Posisi Relawan
                            _buildInteractiveMapSection(),
                            const SizedBox(height: 14),

                            // Kartu Profil Relawan yang Menyetujui
                            _buildVolunteerCard(),
                            const SizedBox(height: 14),

                            // Pergerakan Terkini
                            _buildCurrentMovementCard(),
                            const SizedBox(height: 14),
                          ],

                          // ─── CARD: PANDUAN KEDATANGAN KELUARGA ───
                          _buildArrivalGuideChecklistCard(),
                          const SizedBox(height: 14),

                          // ─── FOOTER NOTE: RANTAI DINGIN (COLD BOX) ───
                          _buildColdChainFooterNote(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),

      // ─── BOTTOM NAVIGATION BAR (PERMOHONAN, PANTAU, PROFIL) ───
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // ─── 1. Header App Bar ───
  Widget _buildHeader() {
    return Row(
      children: [
        // Badge Logo PMI Kotak Merah
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'PMI LAMONGAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFDC2626),
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DARURAT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              'Pantau',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Tombol Grid Aksi
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFDBEAFE)),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: Color(0xFF2563EB),
            size: 18,
          ),
        ),
        const SizedBox(width: 8),
        // Tombol Avatar Merah
        InkWell(
          onTap: () {
            Navigator.pushNamed(context, AppRouter.requesterProfileRoute);
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF991B1B),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ─── 2A. Banner Pencarian Relawan (Kondisi Belum Disetujui) ───
  Widget _buildSearchingBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          // Radar Icon with Pulsing Dot
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.radar_rounded, color: Colors.white, size: 20),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // Teks Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFD97706),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'MEMINDAI RELAWAN DI SEKITAR',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFD97706),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Menunggu Respon Pendonor Siaga',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF78350F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Badge Radius
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE68A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.near_me_outlined, size: 12, color: Color(0xFF78350F)),
                const SizedBox(width: 4),
                Text(
                  'Radius 5 km',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF78350F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3A. Peta Pemindaian Radar (Kondisi Belum Disetujui) ───
  Widget _buildSearchingMapSection() {
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _hospitalLocation,
              initialZoom: 14.2,
              minZoom: 12.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.pmi.donordarah.lamongan',
              ),

              // Lingkaran Radar Pemindaian (Pulsing Radius)
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return CircleLayer(
                    circles: [
                      CircleMarker(
                        point: _hospitalLocation,
                        radius: 80 * _pulseAnimation.value,
                        useRadiusInMeter: false,
                        color: const Color(0xFFDC2626).withValues(alpha: 0.12),
                        borderColor: const Color(0xFFDC2626).withValues(alpha: 0.5),
                        borderStrokeWidth: 1.5,
                      ),
                      CircleMarker(
                        point: _hospitalLocation,
                        radius: 38,
                        useRadiusInMeter: false,
                        color: const Color(0xFFDC2626).withValues(alpha: 0.22),
                        borderColor: const Color(0xFFDC2626),
                        borderStrokeWidth: 2,
                      ),
                    ],
                  );
                },
              ),

              MarkerLayer(
                markers: [
                  // Marker Rumah Sakit / UDD PMI Tujuan
                  Marker(
                    point: _hospitalLocation,
                    width: 170,
                    height: 52,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626),
                            borderRadius: BorderRadius.circular(8),
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
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Lokasi Tujuan (RSUD)',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Overlay Info Pemindaian di Peta
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD97706),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pemindaian Siaga UDD PMI Lamongan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
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

  // ─── 4A. Kartu Status Pemindaian (Kondisi Belum Disetujui) ───
  Widget _buildSearchingVolunteerCard() {
    final bType = _activeRequest?.bloodType ?? 'O';
    final rh = _activeRequest?.rhesus ?? '+';
    final patient = _activeRequest?.patientName ?? 'Pasien Darurat';
    final bags = _activeRequest?.bagsNeeded ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Status
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Center(
                  child: Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Menunggu Pendonor',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Belum Ada Respon',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFB45309),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sinyal darurat aktif dipancarkan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Kotak Golongan Darah
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$bType$rh',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'DARAH',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),

          // Detail Kebutuhan Pasien
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nama Pasien:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                    Text(patient, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Faskes Penyerahan:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                    Text(_hospitalName, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kebutuhan Kantong:', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF64748B))),
                    Text('$bags Kantong ($bType$rh)', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w900, color: const Color(0xFFDC2626))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          // Info box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Belum ada relawan yang mengonfirmasi. Tampilan rute peta dan identitas relawan akan otomatis muncul setelah ada pendonor yang menekan tombol setuju.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF1E40AF),
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Perbarui Status & Hotline
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _initScreenData();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Memeriksa respon relawan pendonor...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF0F172A)),
                    label: Text(
                      'Periksa Status',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Menghubungi Posko Siaga UDD PMI Lamongan: (0322) 321118'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Colors.white),
                    label: Text(
                      'Call Center PMI',
                      style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  // ─── 2B. Status Banner (Live GPS Aktif & Sisa Jarak) ───
  Widget _buildStatusBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        children: [
          // Icon Panah Navigasi Merah dengan Titik Hijau
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.near_me_rounded, color: Colors.white, size: 18),
              ),
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),

          // Teks Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE GPS AKTIF',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFDC2626),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Menuju $_hospitalName',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Badge Jarak Hijau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF15803D),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  _distanceKm,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. Peta Interaktif (Live Map) ───
  Widget _buildInteractiveMapSection() {
    return Container(
      height: 240,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(-7.1260, 112.4168),
              initialZoom: 15.2,
              minZoom: 13.0,
              maxZoom: 18.0,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.pmi.donordarah.lamongan',
              ),

              // Polyline Jalur Rute Merah
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 4.5,
                      color: const Color(0xFFDC2626),
                    ),
                  ],
                ),

              // Circle Faskes Target Radius
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _hospitalLocation,
                    radius: 35,
                    useRadiusInMeter: false,
                    color: const Color(0xFF4ADE80).withValues(alpha: 0.35),
                    borderColor: const Color(0xFF22C55E),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  // Marker Faskes Tujuan (Kotak Palang Merah + Label Lobi BDRS)
                  Marker(
                    point: _hospitalLocation,
                    width: 130,
                    height: 52,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(Icons.add, color: Color(0xFFDC2626), size: 18),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4ADE80),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF22C55E)),
                          ),
                          child: Text(
                            'Lobi BDRS Lt. 1',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF064E3B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Marker Relawan (Motor Merah + Badge Budi O+)
                  Marker(
                    point: _volunteerLocation,
                    width: 100,
                    height: 48,
                    alignment: Alignment.centerLeft,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 17),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${_activeRequest?.donorName?.split(" ").first ?? "Relawan"} (${_activeRequest?.bloodType ?? "O"}+)',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Badge Overlay Kiri Atas: Akurasi GPS ±4m
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.satellite_alt_rounded, size: 12, color: Color(0xFF22C55E)),
                  const SizedBox(width: 4),
                  Text(
                    'Akurasi GPS ±4m',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Badge Overlay Kanan Atas: 24 km/jam
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed_rounded, size: 12, color: Color(0xFF60A5FA)),
                  const SizedBox(width: 4),
                  Text(
                    _speedText,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Badge Overlay Kiri Bawah: Jl. Basuki Rahmat
          Positioned(
            bottom: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Jl. Basuki Rahmat',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // Tombol Recenter Kanan Bawah (🎯)
          Positioned(
            bottom: 10,
            right: 10,
            child: InkWell(
              onTap: () {
                _mapController.move(_volunteerLocation, 15.5);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.gps_fixed_rounded, color: Color(0xFFDC2626), size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Kartu Relawan: Budi Santoso ───
  Widget _buildVolunteerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Relawan
          Row(
            children: [
              // Avatar dengan Badge Centang Hijau
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&auto=format&fit=crop&q=80'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),

              // Nama & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _activeRequest?.donorName ?? 'Relawan Terverifikasi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Terverifikasi',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Relawan Donor Cepat PMI',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Kotak Merah Tua O+ DARAH
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF991B1B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_activeRequest?.bloodType ?? "O"}${_activeRequest?.rhesus ?? "+"}',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'DARAH',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 2 Metrik Kotak: Estimasi Tiba (~6 Menit) & Kendaraan (Motor Matic)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 18, color: Color(0xFFDC2626)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESTIMASI TIBA',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            _etaMinutes,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.two_wheeler_rounded, size: 18, color: Color(0xFF0D9488)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KENDARAAN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            'Motor Matic',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
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
          const SizedBox(height: 10),

          // 2 Tombol Aksi: Telepon & WhatsApp
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Menghubungi Relawan ${_activeRequest?.donorName ?? "Terverifikasi"}...', style: GoogleFonts.plusJakartaSans()),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFDBEAFE)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.phone_rounded, size: 15, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          'Telepon',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Membuka obrolan WhatsApp dengan relawan...', style: GoogleFonts.plusJakartaSans()),
                        backgroundColor: const Color(0xFF15803D),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF15803D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          'WhatsApp',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
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
        ],
      ),
    );
  }

  // ─── 5. Card: Pergerakan Terkini ───
  Widget _buildCurrentMovementCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PERGERAKAN TERKINI',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFDC2626),
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Update 12 dtk lalu',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9.5,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.near_me_outlined, size: 16, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: const Color(0xFF334155),
                        height: 1.35,
                      ),
                      children: const [
                        TextSpan(text: 'Relawan telah melewati '),
                        TextSpan(
                          text: 'Jl. Basuki Rahmat',
                          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFDC2626)),
                        ),
                        TextSpan(text: ' • Sedang berbelok mendekati pintu gerbang barat RSUD Dr. Soegiri.'),
                      ],
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

  // ─── 6. Card: Panduan Kedatangan Keluarga (Checklist 2 dari 3) ───
  Widget _buildArrivalGuideChecklistCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PANDUAN KEDATANGAN KELUARGA',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                '2 dari 3 Siap',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Checklist 1: Siap
          _buildChecklistItem(
            isDone: true,
            text: 'Surat Keterangan Kebutuhan Darah siap di BDRS',
          ),
          const SizedBox(height: 6),

          // Checklist 2: Siap
          _buildChecklistItem(
            isDone: true,
            text: 'Formulir Skrining PMI Lamongan terverifikasi',
          ),
          const SizedBox(height: 6),

          // Checklist 3: Menunggu
          _buildChecklistItem(
            isDone: false,
            text: 'Bertemu Relawan di Loket Bank Darah (BDRS) Lt. 1',
          ),
          const SizedBox(height: 12),

          // Tombol Bantuan Petugas Posko PMI Lamongan
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Menghubungi Posko Siaga BDRS PMI Lamongan: (0322) 321118', style: GoogleFonts.plusJakartaSans()),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.headset_mic_rounded, size: 16, color: Colors.white),
              label: Text(
                'Bantuan Petugas Posko PMI Lamongan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({required bool isDone, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: isDone ? const Color(0xFF16A34A) : Colors.transparent,
              shape: BoxShape.circle,
              border: isDone ? null : Border.all(color: const Color(0xFFCBD5E1), width: 2),
            ),
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 12)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: isDone ? FontWeight.w700 : FontWeight.w600,
                color: isDone ? const Color(0xFF1E293B) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── 7. Footer Note: Rantai Dingin (Cold Box) ───
  Widget _buildColdChainFooterNote() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.ac_unit_rounded, size: 14, color: Color(0xFF0284C7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Darah donor langsung diproses serah terima dengan rantai dingin (cold box) standar PMI demi keselamatan pasien.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9.5,
                color: const Color(0xFF0369A1),
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Navigation Bar (3 Tabs) ───
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
                icon: Icons.assignment_outlined,
                label: 'Permohonan',
                isSelected: _selectedTabIndex == 0,
              ),
              _buildBottomNavItem(
                index: 1,
                icon: Icons.radar_rounded,
                label: 'Pantau',
                isSelected: _selectedTabIndex == 1,
              ),
              _buildBottomNavItem(
                index: 2,
                icon: Icons.person_outline_rounded,
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
