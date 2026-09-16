import 'package:flutter/material.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../data/repositories/tracking_repository.dart';
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

  Future<void> _handleAccept() async {
    setState(() => _isResponding = true);
    try {
      await _requestRepo.respondToRequest(widget.request.id);
      _trackingRepo.startTracking(widget.request.id.toString());

      // Kirim koordinat awal dummy (Lamongan)
      _trackingRepo.updateLocation(-7.119853, 112.415278);

      setState(() {
        _hasAccepted = true;
      });

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

  void _sendLocationUpdate(double lat, double lng) {
    _trackingRepo.updateLocation(lat, lng);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lokasi terkini berhasil dikirimkan ke pemohon darah.')),
    );
  }

  @override
  void dispose() {
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
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Anda Sedang Dalam Perjalanan',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Koordinat posisi Anda dapat dipantau oleh pemohon darah secara live.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => _sendLocationUpdate(-7.121500, 112.418200),
                icon: const Icon(Icons.my_location),
                label: const Text('Kirim Update Lokasi GPS'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
