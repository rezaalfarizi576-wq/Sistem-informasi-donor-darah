import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../data/repositories/tracking_repository.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String requestId;

  const LiveTrackingScreen({super.key, required this.requestId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen>
    with SingleTickerProviderStateMixin {
  final _trackingRepo = TrackingRepository();
  final _requestRepo = BloodRequestRepository();
  final MapController _mapController = MapController();

  Map<String, dynamic>? _lastLocationData;
  BloodRequestModel? _request;
  bool _isLoading = true;
  bool _autoFollow = true;

  // Koordinat default Lamongan (RSUD Dr. Soegiri)
  static const LatLng _defaultHospitalLocation = LatLng(-7.111812, 112.413155);
  // Titik awal donor default
  static const LatLng _defaultDonorLocation = LatLng(-7.126500, 112.418200);

  LatLng? _donorLocation;
  LatLng _hospitalLocation = _defaultHospitalLocation;

  StreamSubscription? _locationSubscription;
  Timer? _simulationTimer;
  bool _isSimulating = false;
  double _simProgress = 0.0;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _loadRequestDetails();
    _initTracking();
  }

  Future<void> _loadRequestDetails() async {
    try {
      final reqId = int.tryParse(widget.requestId);
      if (reqId != null) {
        final req = await _requestRepo.getRequestById(reqId);
        if (mounted) {
          setState(() {
            _request = req;
            if (req.latitudeFaskes != 0.0 && req.longitudeFaskes != 0.0) {
              _hospitalLocation = LatLng(req.latitudeFaskes, req.longitudeFaskes);
            }
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _initTracking() {
    _trackingRepo.startTracking(widget.requestId);
    _locationSubscription = _trackingRepo.locationStream?.listen((data) {
      if (mounted && data is Map<String, dynamic>) {
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();

        if (lat != null && lng != null) {
          setState(() {
            _lastLocationData = data;
            _donorLocation = LatLng(lat, lng);
          });

          if (_autoFollow) {
            try {
              _mapController.move(_donorLocation!, _mapController.camera.zoom);
            } catch (_) {}
          }
        }
      }
    });
  }

  /// Simulasi gerakan pendonor di peta ala Gojek dari titik awal ke RS
  void _toggleSimulation() {
    if (_isSimulating) {
      _simulationTimer?.cancel();
      setState(() => _isSimulating = false);
      return;
    }

    setState(() {
      _isSimulating = true;
      _simProgress = 0.0;
    });

    const start = _defaultDonorLocation;
    final end = _hospitalLocation;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _simProgress += 0.08;
        if (_simProgress >= 1.0) {
          _simProgress = 1.0;
          timer.cancel();
          _isSimulating = false;
        }

        final curLat = start.latitude + (end.latitude - start.latitude) * _simProgress;
        final curLng = start.longitude + (end.longitude - start.longitude) * _simProgress;
        _donorLocation = LatLng(curLat, curLng);
        _lastLocationData = {
          'latitude': curLat,
          'longitude': curLng,
          'timestamp': DateTime.now().toIso8601String(),
        };

        // Kirim juga ke WebSocket agar synchronized jika ada screen lain terbuka
        _trackingRepo.updateLocation(curLat, curLng);
      });

      if (_autoFollow && _donorLocation != null) {
        _mapController.move(_donorLocation!, 15.5);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _simulationTimer?.cancel();
    _locationSubscription?.cancel();
    _trackingRepo.stopTracking();
    super.dispose();
  }

  // Hitung jarak dan ETA ala Gojek
  Map<String, String> _calculateDistanceAndEta() {
    if (_donorLocation == null) {
      return {'distance': 'Mencari GPS...', 'eta': '--'};
    }

    const Distance distanceCalc = Distance();
    final double meter = distanceCalc.as(
      LengthUnit.Meter,
      _donorLocation!,
      _hospitalLocation,
    );

    String distStr;
    if (meter >= 1000) {
      distStr = '${(meter / 1000).toStringAsFixed(1)} km';
    } else {
      distStr = '${meter.round()} m';
    }

    // Asumsi kecepatan rata-rata sepeda motor di Lamongan = 30 km/jam (~500 meter/menit)
    final int minutes = (meter / 500).ceil();
    final String etaStr = minutes <= 1 ? 'Tiba di lokasi' : '± $minutes menit';

    return {'distance': distStr, 'eta': etaStr};
  }

  @override
  Widget build(BuildContext context) {
    final activeDonorPos = _donorLocation ?? _defaultDonorLocation;
    final hasRealLocation = _donorLocation != null;
    final metrics = _calculateDistanceAndEta();
    final timestamp = _lastLocationData?['timestamp']?.toString();
    final timeFormatted = timestamp != null && timestamp.length >= 19
        ? timestamp.substring(11, 19)
        : 'Menunggu sinyal';

    return Scaffold(
      body: Stack(
        children: [
          // 1. PETA INTERAKTIF OPENSTREETMAP (Leaflet via flutter_map)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: activeDonorPos,
              initialZoom: 15.0,
              minZoom: 11.0,
              maxZoom: 18.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'id.pmi.donordarah.lamongan',
              ),

              // Rute garis penghubung dari Pendonor ke Rumah Sakit
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [activeDonorPos, _hospitalLocation],
                    strokeWidth: 4.5,
                    color: const Color(0xFFD32F2F).withValues(alpha: 0.85),
                  ),
                ],
              ),

              // Marker Layer (Pendonor & Rumah Sakit)
              MarkerLayer(
                markers: [
                  // Marker Rumah Sakit / Lokasi Tujuan
                  Marker(
                    point: _hospitalLocation,
                    width: 70,
                    height: 70,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Text(
                            'RS Tujuan',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1976D2),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: const Icon(Icons.local_hospital, color: Colors.white, size: 22),
                        ),
                      ],
                    ),
                  ),

                  // Marker Pendonor (Bergerak dengan efek animasi Gojek)
                  Marker(
                    point: activeDonorPos,
                    width: 80,
                    height: 80,
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            // Efek Radar / Pulse
                            Container(
                              width: 60 * _pulseAnimation.value,
                              height: 60 * _pulseAnimation.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFD32F2F).withValues(
                                  alpha: (0.35 / _pulseAnimation.value).clamp(0.0, 1.0),
                                ),
                              ),
                            ),
                            // Marker Ikon Motor / Donor
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD32F2F),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 3),
                                    ],
                                  ),
                                  child: const Text(
                                    'Pendonor',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: const Color(0xFFD32F2F), width: 3),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.two_wheeler,
                                    color: Color(0xFFD32F2F),
                                    size: 24,
                                  ),
                                ),
                              ],
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

          // 2. HEADER TOP BAR ALA GOJEK
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Tombol Back
                Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Icon(Icons.arrow_back, color: Colors.black87),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Badge Live Tracking & ID
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasRealLocation || _isSimulating ? Colors.green : Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'LIVE TRACKING #${widget.requestId}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                hasRealLocation || _isSimulating
                                    ? 'GPS Aktif • Terhubung'
                                    : 'Menunggu Transmisi GPS',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: hasRealLocation || _isSimulating ? Colors.green.shade700 : Colors.grey,
                                ),
                              ),
                              if (_isLoading)
                                const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: LinearProgressIndicator(minHeight: 2),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. FLOATING MAP ACTION BUTTONS (Recenter, Zoom, Simulasi)
          Positioned(
            right: 16,
            bottom: 300,
            child: Column(
              children: [
                // Tombol Simulasi Perjalanan
                FloatingActionButton.small(
                  heroTag: 'fab_sim',
                  backgroundColor: _isSimulating ? Colors.orange : Colors.white,
                  foregroundColor: _isSimulating ? Colors.white : Colors.black87,
                  tooltip: _isSimulating ? 'Stop Simulasi' : 'Mulai Simulasi Gerakan GPS',
                  onPressed: _toggleSimulation,
                  child: Icon(_isSimulating ? Icons.stop : Icons.play_arrow),
                ),
                const SizedBox(height: 8),

                // Tombol Pusatkan ke Pendonor
                FloatingActionButton.small(
                  heroTag: 'fab_donor',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFD32F2F),
                  tooltip: 'Pusatkan ke Pendonor',
                  onPressed: () {
                    setState(() => _autoFollow = true);
                    _mapController.move(activeDonorPos, 16.0);
                  },
                  child: const Icon(Icons.two_wheeler),
                ),
                const SizedBox(height: 8),

                // Tombol Pusatkan ke Rumah Sakit
                FloatingActionButton.small(
                  heroTag: 'fab_hospital',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1976D2),
                  tooltip: 'Pusatkan ke RS Tujuan',
                  onPressed: () {
                    setState(() => _autoFollow = false);
                    _mapController.move(_hospitalLocation, 16.0);
                  },
                  child: const Icon(Icons.local_hospital),
                ),
              ],
            ),
          ),

          // 4. BOTTOM PANEL / CARD ALA GOJEK
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle Bar
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ETA & Status Perjalanan (Highlight Banner)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFFD32F2F), Colors.red.shade800],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.timer, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Pendonor Sedang Menuju Lokasi',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Estimasi Tiba: ${metrics['eta']}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Jarak',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              Text(
                                metrics['distance']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detail Pendonor & Pemohon
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.red.shade50,
                          child: const Icon(Icons.bloodtype, color: Color(0xFFD32F2F), size: 26),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Pendonor Sukarela Siaga',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                'Kebutuhan: ${_request?.bloodType ?? "B"}${_request?.rhesus ?? "+"} (${_request?.bagsNeeded ?? 1} Kantong)',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            'Update: $timeFormatted',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade800, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Info Tujuan Rumah Sakit & Pasien
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFF1976D2), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _request?.hospitalName ?? 'RSUD Dr. Soegiri Lamongan',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              Text(
                                'Pasien: ${_request?.patientName ?? "Satriatama Bisma Yodha"}',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
