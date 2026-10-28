import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/services/routing_service.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../data/repositories/donor_repository.dart';
import '../../../data/repositories/tracking_repository.dart';
import 'donation_success_screen.dart';

class DonorLiveTrackingScreen extends StatefulWidget {
  final String requestId;

  const DonorLiveTrackingScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<DonorLiveTrackingScreen> createState() => _DonorLiveTrackingScreenState();
}

class _DonorLiveTrackingScreenState extends State<DonorLiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _trackingRepo = TrackingRepository();
  final _requestRepo = BloodRequestRepository();
  final _donorRepo = DonorRepository();
  final _routingService = RoutingService();
  final MapController _mapController = MapController();

  // Koordinat Faskes RSUD Dr. Soegiri Lamongan
  static const LatLng _defaultHospitalLocation = LatLng(-7.1159, 112.4103);
  // Posisi awal donor (Jalan Basuki Rahmat / Veteran Lamongan)
  static const LatLng _defaultDonorLocation = LatLng(-7.132500, 112.418200);

  LatLng _hospitalLocation = _defaultHospitalLocation;
  LatLng _donorLocation = _defaultDonorLocation;
  String _hospitalName = 'RSUD Dr. Soegiri';

  // Rute Jalan Riil
  List<LatLng> _routePoints = [];
  bool _isArriving = false;

  // Metrik Perjalanan
  String _distanceDisplay = '1.8 km';
  String _etaDisplay = '8 mnt';
  String _speedDisplay = '32 km/h';
  double _progressValue = 0.55;

  StreamSubscription? _locationSubscription;
  StreamSubscription<Position>? _gpsStreamSubscription;
  Timer? _simulationTimer;
  double _simProgress = 0.0;
  bool _isAutoCenter = true;
  bool _isRealGps = true;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).clearSnackBars();
    });

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.35).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadDataAndConnectBackend();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulationTimer?.cancel();
    _gpsStreamSubscription?.cancel();
    _locationSubscription?.cancel();
    _trackingRepo.stopTracking();
    super.dispose();
  }

  Future<void> _loadDataAndConnectBackend() async {
    final reqIdInt = int.tryParse(widget.requestId) ?? 1;

    // 1. Hubungkan WebSocket ke Backend
    _trackingRepo.startTracking(widget.requestId);
    _locationSubscription = _trackingRepo.locationStream?.listen((data) {
      if (data is Map && mounted) {
        if (data.containsKey('latitude') && data.containsKey('longitude')) {
          final lat = (data['latitude'] as num).toDouble();
          final lng = (data['longitude'] as num).toDouble();
          setState(() {
            _donorLocation = LatLng(lat, lng);
            if (_isAutoCenter) {
              _mapController.move(_donorLocation, _mapController.camera.zoom);
            }
          });
        }
      }
    });

    // 2. Ambil data dari Backend REST API
    try {
      final trackingData = await _donorRepo.getTrackingStatus(
        reqIdInt,
        lat: _donorLocation.latitude,
        lng: _donorLocation.longitude,
      );

      if (mounted) {
        setState(() {
          _hospitalName = trackingData['hospital_name'] ?? 'RSUD Dr. Soegiri';
          if (trackingData['destination_lat'] != null && trackingData['destination_lng'] != null) {
            _hospitalLocation = LatLng(
              (trackingData['destination_lat'] as num).toDouble(),
              (trackingData['destination_lng'] as num).toDouble(),
            );
          }
          _distanceDisplay = trackingData['distance_display'] ?? '1.8 km';
          _etaDisplay = trackingData['eta_display'] ?? '8 mnt';
          _speedDisplay = trackingData['speed_display'] ?? '32 km/h';
          final progressPercent = (trackingData['progress_percent'] as num?)?.toDouble() ?? 55.0;
          _progressValue = (progressPercent / 100.0).clamp(0.0, 1.0);
        });
      }
    } catch (_) {
      try {
        final req = await _requestRepo.getRequestById(reqIdInt);
        if (mounted) {
          setState(() {
            _hospitalName = req.hospitalName ?? 'RSUD Dr. Soegiri';
            if (req.latitudeFaskes != 0.0 && req.longitudeFaskes != 0.0) {
              _hospitalLocation = LatLng(req.latitudeFaskes, req.longitudeFaskes);
            }
          });
        }
      } catch (_) {}
    }

    // 3. Ambil rute jalan riil Lamongan
    await _fetchRoadRoute();

    // 4. Inisialisasi pelacakan GPS nyata (dengan fallback simulasi jika di desktop)
    await _initGpsTracking();
  }

  Future<void> _initGpsTracking() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
      } catch (_) {
        pos = null;
      }

      if (pos != null && mounted) {
        setState(() {
          _donorLocation = LatLng(pos!.latitude, pos.longitude);
          _updateMetricsFromLocation(_donorLocation, pos.speed);
        });
        _fetchRoadRoute();
        _trackingRepo.updateLocation(pos.latitude, pos.longitude);
      }

      _gpsStreamSubscription?.cancel();
      _gpsStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 3,
        ),
      ).listen((Position p) {
        if (!_isRealGps || !mounted) return;
        setState(() {
          _donorLocation = LatLng(p.latitude, p.longitude);
          _updateMetricsFromLocation(_donorLocation, p.speed);
          if (_isAutoCenter) {
            _mapController.move(_donorLocation, _mapController.camera.zoom);
          }
        });
        _trackingRepo.updateLocation(p.latitude, p.longitude);
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isRealGps = false);
        _startSimulatedRide();
      }
    }
  }

  void _updateMetricsFromLocation(LatLng loc, double speedMps) {
    final distMeters = const Distance().as(LengthUnit.Meter, loc, _hospitalLocation);
    final distKm = distMeters / 1000.0;
    _distanceDisplay = '${distKm.toStringAsFixed(1)} km';

    final speedKmh = speedMps > 0.5 ? (speedMps * 3.6).round() : 32;
    _speedDisplay = '$speedKmh km/h';

    final remEta = (distKm / (speedKmh > 0 ? speedKmh : 30) * 60).ceil().clamp(1, 45);
    _etaDisplay = '$remEta mnt';

    _progressValue = (1.0 - (distKm / 2.5)).clamp(0.15, 0.98);
  }

  void _toggleGpsMode() {
    setState(() {
      _isRealGps = !_isRealGps;
    });
    if (_isRealGps) {
      _simulationTimer?.cancel();
      _initGpsTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode GPS Riil Aktif: Melacak posisi fisik HP/perangkat Anda'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _gpsStreamSubscription?.cancel();
      _startSimulatedRide();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mode Simulasi Demo Aktif: Pergerakan otomatis ke faskes'),
          backgroundColor: Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _fetchRoadRoute() async {
    try {
      final route = await _routingService.getRoadRoute(_donorLocation, _hospitalLocation);
      if (mounted && route.points.isNotEmpty) {
        setState(() {
          _routePoints = route.points;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _routePoints = RoutingService.defaultLamonganRoad;
        });
      }
    }
  }

  void _startSimulatedRide() {
    _simulationTimer?.cancel();
    _simProgress = 0.0;

    // Hitung total jarak rute agar kecepatan simulasi realistis
    final totalRouteDistM = _routingService.calculateTotalRoadDistance(_routePoints);
    final totalRouteDistKm = totalRouteDistM / 1000.0;
    const simSpeedKmh = 30.0; // Kecepatan simulasi: 30 km/h
    final totalTimeSec = totalRouteDistKm / simSpeedKmh * 3600; // Detik tempuh total
    const tickIntervalSec = 2; // Update tiap 2 detik
    final progressPerTick = totalTimeSec > 0 ? (tickIntervalSec / totalTimeSec) : 0.02;

    _simulationTimer = Timer.periodic(const Duration(seconds: tickIntervalSec), (timer) {
      if (!mounted || _routePoints.length < 2) return;

      _simProgress += progressPerTick;
      if (_simProgress >= 0.98) {
        _simProgress = 0.98;
        timer.cancel();
      }

      // Gunakan getPointAlongRoute agar mengikuti jalanan, bukan lurus
      final currentPos = _routingService.getPointAlongRoute(_routePoints, _simProgress);

      // Hitung metrik dinamis
      final remainingDistM = const Distance().as(LengthUnit.Meter, currentPos, _hospitalLocation);
      final remainingDistKm = remainingDistM / 1000.0;
      final remEta = (remainingDistKm / simSpeedKmh * 60).ceil().clamp(1, 60);

      setState(() {
        _donorLocation = currentPos;
        _progressValue = _simProgress.clamp(0.05, 0.98);
        _distanceDisplay = '${remainingDistKm.toStringAsFixed(1)} km';
        _etaDisplay = '$remEta mnt';
        _speedDisplay = '${simSpeedKmh.round()} km/h';

        if (_isAutoCenter) {
          _mapController.move(_donorLocation, _mapController.camera.zoom);
        }
      });

      _trackingRepo.updateLocation(currentPos.latitude, currentPos.longitude);
    });
  }

  Future<void> _handleArrive() async {
    setState(() => _isArriving = true);
    final reqIdInt = int.tryParse(widget.requestId) ?? 1;

    try {
      // 1. Panggil API konfirmasi kedatangan di backend
      await _donorRepo.confirmArrival(reqIdInt);

      // 2. Beri kabar lewat websocket bahwa donor sudah sampai
      _trackingRepo.sendEvent({
        'type': 'donor_arrived',
        'status': 'sampai',
        'request_id': widget.requestId,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (_) {
      // Tetap lanjutkan UX sekalipun koneksi backend tertahan
    }

    if (!mounted) return;
    setState(() => _isArriving = false);

    // Navigasi ke Halaman "Donasi Berhasil!"
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => DonationSuccessScreen(
          hospitalName: _hospitalName,
          volume: '400 mL',
          donationDate: 'Hari ini, ${TimeOfDay.now().format(context)}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cari titik tengah rute untuk meletakkan badge ETA "8 mnt"
    LatLng midRoutePoint = LatLng(
      (_donorLocation.latitude + _hospitalLocation.latitude) / 2,
      (_donorLocation.longitude + _hospitalLocation.longitude) / 2,
    );
    if (_routePoints.length >= 3) {
      midRoutePoint = _routePoints[_routePoints.length ~/ 2];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── 1. HEADER MERAH (STATUS PERJALANAN & STATS METRICS) ───
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB91C1C),
                    Color(0xFFDC2626),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Label STATUS PERJALANAN
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'STATUS PERJALANAN',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Judul Tujuan: Menuju RSUD Dr. Soegiri
                  Text(
                    'Menuju $_hospitalName',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),
                  // Baris 3 Metrik: Sisa Jarak | ETA Tiba | Kecepatan
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Sisa Jarak
                        _buildHeaderMetric(
                          value: _distanceDisplay,
                          label: 'Sisa Jarak',
                        ),
                        const SizedBox(width: 18),
                        _buildVerticalDivider(),
                        const SizedBox(width: 18),
                        // ETA Tiba
                        _buildHeaderMetric(
                          value: _etaDisplay,
                          label: 'ETA Tiba',
                        ),
                        const SizedBox(width: 18),
                        _buildVerticalDivider(),
                        const SizedBox(width: 18),
                        // Kecepatan
                        _buildHeaderMetric(
                          value: _speedDisplay,
                          label: 'Kecepatan',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── 2. AREA PETA INTERAKTIF ───
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: midRoutePoint,
                      initialZoom: 15.0,
                      minZoom: 12.0,
                      maxZoom: 18.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all,
                      ),
                    ),
                    children: [
                      // OpenStreetMap Tiles
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'id.pmi.donordarah.lamongan',
                      ),

                      // Polyline Jalur Merah
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5.0,
                              color: const Color(0xFFDC2626),
                            ),
                          ],
                        ),

                      // Marker Layer
                      MarkerLayer(
                        markers: [
                          // ── Marker Badge Floating ETA di Tengah Rute ("8 mnt") ──
                          Marker(
                            point: midRoutePoint,
                            width: 65,
                            height: 28,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                _etaDisplay,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ),

                          // ── Marker Posisi Donor (Lingkaran Target Merah Berdenyut) ──
                          Marker(
                            point: _donorLocation,
                            width: 48,
                            height: 48,
                            child: AnimatedBuilder(
                              animation: _pulseAnimation,
                              builder: (context, child) {
                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Ring Luar Pulse
                                    Container(
                                      width: 44 * _pulseAnimation.value,
                                      height: 44 * _pulseAnimation.value,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFFDC2626).withValues(
                                          alpha: (0.35 / _pulseAnimation.value).clamp(0.0, 0.4),
                                        ),
                                      ),
                                    ),
                                    // Ring Tengah Putih
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.25),
                                            blurRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        // Titik Merah Inti
                                        child: Container(
                                          width: 13,
                                          height: 13,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),

                          // ── Marker Rumah Sakit (Pin Biru + Label Badge Hijau) ──
                          Marker(
                            point: _hospitalLocation,
                            width: 140,
                            height: 48,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Pin Lingkaran Biru dengan icon (+)
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2563EB),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.25),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                // Callout Badge Faskes Hijau
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFF86EFAC)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    _hospitalName,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF15803D),
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

                  // ── Overlay: Kotak Legenda (Top Left) ──
                  Positioned(
                    top: 14,
                    left: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendRow(
                            color: const Color(0xFFDC2626),
                            label: 'Posisi Anda',
                          ),
                          const SizedBox(height: 5),
                          _buildLegendRow(
                            color: const Color(0xFF2563EB),
                            label: 'Rumah Sakit',
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Overlay: Kontrol Zoom & GPS Target (Top Right) ──
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Zoom In (+)
                          InkWell(
                            onTap: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.add, size: 20, color: Color(0xFF475569)),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                          // Zoom Out (−)
                          InkWell(
                            onTap: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1,
                              );
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.remove, size: 20, color: Color(0xFF475569)),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                          // Recenter ke Posisi Donor (🎯)
                          InkWell(
                            onTap: () {
                              setState(() => _isAutoCenter = true);
                              _mapController.move(_donorLocation, 15.5);
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.gps_fixed_rounded, size: 18, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Overlay: Badge Mode GPS / Simulasi (Bottom Left) ──
                  Positioned(
                    bottom: 14,
                    left: 14,
                    child: GestureDetector(
                      onTap: _toggleGpsMode,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isRealGps
                              ? const Color(0xFF16A34A).withValues(alpha: 0.9)
                              : const Color(0xFF2563EB).withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRealGps ? Icons.gps_fixed_rounded : Icons.route_rounded,
                              color: Colors.white,
                              size: 13,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isRealGps ? 'GPS Riil' : 'Simulasi',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10.5,
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
            ),

            // ─── 3. BOTTOM CARD (PROGRESS BAR & TOMBOL SAYA SUDAH SAMPAI) ───
            SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(22),
                        topRight: Radius.circular(22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Progress Bar & Angka Persen
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: _progressValue,
                                  minHeight: 6,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF15803D)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${(_progressValue * 100).round()}%',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Tombol Besar: "✓ Saya Sudah Sampai"
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isArriving ? null : _handleArrive,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF15803D),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isArriving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.check, size: 20, color: Colors.white),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Saya Sudah Sampai',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Widget Kolom Metrik Header
  Widget _buildHeaderMetric({required String value, required String label}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 17.5,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.8),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Helper: Garis Pemisah Vertikal Header
  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.white.withValues(alpha: 0.25),
    );
  }

  // Helper: Item Baris Legenda
  Widget _buildLegendRow({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
