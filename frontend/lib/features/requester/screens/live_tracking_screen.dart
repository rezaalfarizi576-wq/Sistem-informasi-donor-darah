import 'package:flutter/material.dart';
import '../../../data/repositories/tracking_repository.dart';

class LiveTrackingScreen extends StatefulWidget {
  final String requestId;

  const LiveTrackingScreen({super.key, required this.requestId});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  final _trackingRepo = TrackingRepository();
  Map<String, dynamic>? _lastLocationData;

  @override
  void initState() {
    super.initState();
    _trackingRepo.startTracking(widget.requestId);
    _trackingRepo.locationStream?.listen((data) {
      if (mounted && data is Map<String, dynamic>) {
        setState(() {
          _lastLocationData = data;
        });
      }
    });
  }

  @override
  void dispose() {
    _trackingRepo.stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lat = _lastLocationData?['latitude'];
    final lng = _lastLocationData?['longitude'];
    final timestamp = _lastLocationData?['timestamp'];

    return Scaffold(
      appBar: AppBar(
        title: Text('Live Tracking #${widget.requestId}'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 64,
                    color: Color(0xFFD32F2F),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pelacakan Posisi Pendonor',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pendonor sedang menuju ke lokasi permohonan darah.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const Divider(height: 32),
                  if (_lastLocationData != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Latitude:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('$lat'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Longitude:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text('$lng'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Update Terakhir:', style: TextStyle(fontWeight: FontWeight.w600)),
                        Text(timestamp != null ? timestamp.toString().substring(11, 19) : '-'),
                      ],
                    ),
                  ] else ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Menunggu transmisi GPS dari pendonor...'),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
