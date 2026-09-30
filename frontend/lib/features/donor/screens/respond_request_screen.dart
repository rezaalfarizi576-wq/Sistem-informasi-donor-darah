import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../data/repositories/tracking_repository.dart';
import '../../../routes/app_router.dart';
import '../../../shared/widgets/custom_button.dart';

class RespondRequestScreen extends StatefulWidget {
  final BloodRequestModel request;

  const RespondRequestScreen({super.key, required this.request});

  @override
  State<RespondRequestScreen> createState() => _RespondRequestScreenState();
}

class _RespondRequestScreenState extends State<RespondRequestScreen> {
  final _requestRepo = BloodRequestRepository();
  final _trackingRepo = TrackingRepository();
  bool _isResponding = false;
  bool _hasAccepted = false;

  // Real GPS Tracking State
  bool _isGpsActive = false;
  Position? _currentGpsPosition;
  StreamSubscription<Position>? _gpsStreamSubscription;

  // Simulasi / Demo State
  Timer? _tripTimer;
  bool _isAutoMoving = false;
  double _tripProgress = 0.0;

  // Titik awal fallback Lamongan jika GPS perangkat belum aktif
  static const double _fallbackStartLat = -7.126500;
  static const double _fallbackStartLng = 112.418200;

  Future<void> _handleAccept() async {
    setState(() => _isResponding = true);
    try {
      await _requestRepo.respondToRequest(widget.request.id);
      _trackingRepo.startTracking(widget.request.id.toString());

      setState(() {
        _hasAccepted = true;
      });

      // Coba langsung aktifkan GPS fisik perangkat
      await _startRealGpsTracking();

      // Jika GPS fisik belum dapat posisi, kirim koordinat awal fallback
      if (_currentGpsPosition == null) {
        _trackingRepo.updateLocation(_fallbackStartLat, _fallbackStartLng);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terima kasih! Anda bersedia menjadi pendonor untuk permohonan ini.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _trackingRepo.startTracking(widget.request.id.toString());
        await _startRealGpsTracking();
        if (!mounted) return;
        if (_currentGpsPosition == null) {
          _trackingRepo.updateLocation(_fallbackStartLat, _fallbackStartLng);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status terkonfirmasi: ${e.toString().replaceAll("Exception: ", "")}'),
          ),
        );
        setState(() => _hasAccepted = true);
      }
    } finally {
      if (mounted) setState(() => _isResponding = false);
    }
  }

  /// Memulai pelacakan GPS fisik nyata dari perangkat/HP donor
  Future<void> _startRealGpsTracking() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('GPS perangkat tidak aktif. Mohon aktifkan GPS di pengaturan.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin GPS ditolak oleh pengguna.')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin GPS ditolak secara permanen. Mohon aktifkan lewat izin browser/aplikasi.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 1. Ambil koordinat awal
      final initialPos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _handleGpsUpdate(initialPos);

      // 2. Pasang stream GPS berkecepatan tinggi (tiap 5 meter perpindahan)
      _gpsStreamSubscription?.cancel();
      _gpsStreamSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((Position position) {
        _handleGpsUpdate(position);
      });

      setState(() => _isGpsActive = true);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📡 GPS Asli Aktif! Lokasi fisik Anda sekarang dipancarkan secara real-time.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Gps Error: $e');
    }
  }

  void _handleGpsUpdate(Position pos) {
    if (!mounted) return;
    setState(() {
      _currentGpsPosition = pos;
      _isGpsActive = true;
    });
    // Kirim koordinat GPS nyata ke WebSocket backend
    _trackingRepo.updateLocation(pos.latitude, pos.longitude);
  }

  void _stopRealGpsTracking() {
    _gpsStreamSubscription?.cancel();
    _gpsStreamSubscription = null;
    setState(() => _isGpsActive = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pelacakan GPS fisik dihentikan.')),
    );
  }

  /// Simulasi perjalanan demo (jika sedang tidak di jalan raya)
  void _toggleAutoTrip() {
    if (_isAutoMoving) {
      _tripTimer?.cancel();
      setState(() => _isAutoMoving = false);
      return;
    }

    setState(() {
      _isAutoMoving = true;
      _tripProgress = 0.0;
    });

    final targetLat = widget.request.latitudeFaskes != 0.0
        ? widget.request.latitudeFaskes
        : -7.111812;
    final targetLng = widget.request.longitudeFaskes != 0.0
        ? widget.request.longitudeFaskes
        : 112.413155;

    final startLat = _currentGpsPosition?.latitude ?? _fallbackStartLat;
    final startLng = _currentGpsPosition?.longitude ?? _fallbackStartLng;

    _tripTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _tripProgress += 0.1;
        if (_tripProgress >= 1.0) {
          _tripProgress = 1.0;
          timer.cancel();
          _isAutoMoving = false;
        }

        final currentLat = startLat + (targetLat - startLat) * _tripProgress;
        final currentLng = startLng + (targetLng - startLng) * _tripProgress;

        _trackingRepo.updateLocation(currentLat, currentLng);
      });
    });
  }

  @override
  void dispose() {
    _gpsStreamSubscription?.cancel();
    _tripTimer?.cancel();
    _trackingRepo.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konfirmasi Donor'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Permohonan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Divider(),
                    Text('Pasien: ${widget.request.patientName}'),
                    const SizedBox(height: 4),
                    Text('Rumah Sakit: ${widget.request.hospitalName}'),
                    const SizedBox(height: 4),
                    Text('Kebutuhan: ${widget.request.bloodType}${widget.request.rhesus} (${widget.request.bagsNeeded} Kantong)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!_hasAccepted) ...[
              const Text(
                'Apakah Anda bersedia mendonorkan darah Anda sekarang juga dan menuju lokasi rumah sakit?',
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Saya Bersedia Mendonor',
                isLoading: _isResponding,
                onPressed: _handleAccept,
              ),
            ] else ...[
              // Kartu Status Perjalanan
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Anda Sedang Dalam Perjalanan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Koordinat posisi Anda dipantau oleh pemohon darah secara live di peta (ala Gojek).',
                      textAlign: TextAlign.center,
                    ),
                    const Divider(height: 20),

                    // Indikator GPS Fisik Real-time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isGpsActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isGpsActive
                              ? '📡 GPS HP Aktif (${_currentGpsPosition?.latitude.toStringAsFixed(5)}, ${_currentGpsPosition?.longitude.toStringAsFixed(5)})'
                              : '📡 GPS HP Belum Aktif',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isGpsActive ? Colors.green.shade800 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tombol Buka Peta Live Tracking
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.liveTrackingRoute,
                    arguments: widget.request.id.toString(),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text('Buka Peta Live Tracking'),
              ),
              const SizedBox(height: 12),

              // Tombol Nyalakan / Matikan GPS Fisik
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(
                    color: _isGpsActive ? Colors.green : Colors.blue.shade700,
                    width: 1.5,
                  ),
                ),
                onPressed: _isGpsActive ? _stopRealGpsTracking : _startRealGpsTracking,
                icon: Icon(
                  _isGpsActive ? Icons.location_on : Icons.my_location,
                  color: _isGpsActive ? Colors.green : Colors.blue.shade700,
                ),
                label: Text(
                  _isGpsActive ? 'Hentikan Streaming GPS Fisik' : 'Aktifkan GPS HP Fisik Nyata',
                  style: TextStyle(
                    color: _isGpsActive ? Colors.green.shade800 : Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tombol Simulasi Pergerakan Demo
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: _isAutoMoving ? Colors.orange.shade800 : Colors.black87,
                ),
                onPressed: _toggleAutoTrip,
                icon: Icon(_isAutoMoving ? Icons.pause_circle : Icons.play_circle_outline),
                label: Text(
                  _isAutoMoving
                      ? 'Hentikan Simulasi Demo (${(_tripProgress * 100).toInt()}%)'
                      : 'Simulasikan Perjalanan (Mode Demo Tanpa Jalan)',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
