import 'package:flutter/material.dart';
import '../../../data/models/blood_request_model.dart';

/// Panel detail kanan yang menampilkan info permintaan, surat keterangan dokter,
/// dan tombol aksi setujui/tolak.
class VerificationDetailPanel extends StatelessWidget {
  final BloodRequestModel request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const VerificationDetailPanel({
    super.key,
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F6FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── INFO SUMMARY CARDS ─────────────────
            _buildInfoSummary(),
            const SizedBox(height: 20),
            // ─── SURAT KETERANGAN DOKTER ────────────
            _buildSuratKeterangan(),
            const SizedBox(height: 24),
            // ─── ACTION BUTTONS ─────────────────────
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Left: Hospital & blood type info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RUMAH SAKIT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.hospitalName ?? 'Faskes belum terdaftar',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'GOLONGAN DARAH',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.bloodLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFE53935),
                  ),
                ),
              ],
            ),
          ),
          // Right: Time & status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'WAKTU PERMINTAAN',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request.timeAgo,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1D2E),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'STATUS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _statusLabel(request.status),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: request.isPending
                        ? const Color(0xFFFF6D00)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuratKeterangan() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              children: [
                const Text(
                  'SURAT KETERANGAN DOKTER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2E),
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: DOK-${DateTime.now().year}-${request.id.toString().padLeft(5, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ─── DOCUMENT PREVIEW ──────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hospital header with QR and CAP RSUD
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              (request.hospitalName ?? 'RUMAH SAKIT UMUM DAERAH\nDR. SOEGIRI LAMONGAN').toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1D2E),
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 180,
                              height: 2,
                              color: const Color(0xFF1A1D2E),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'SURAT KETERANGAN KEBUTUHAN DARAH',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D2E),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // QR Code
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 1.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.qr_code_2_rounded,
                          size: 38,
                          color: Color(0xFF1A1D2E),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Stempel Bulat CAP RSUD
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF3F8CFF),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            'CAP\nRSUD',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF3F8CFF),
                              height: 1.0,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Divider(color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  // Document fields
                  _buildDocField('Nomor', '045/RSUD-SGR/IX/2025'),
                  _buildDocField('Nama Pasien', request.requesterName ?? 'Dewi Rahayu'),
                  _buildDocField('No. RM', 'RM-2025-08691'),
                  _buildDocFieldHighlighted('Golongan Darah', '${request.bloodType} Rhesus ${request.rhesus == '+' ? 'Positif' : 'Negatif'} (${request.bloodLabel})'),
                  _buildDocField('Kebutuhan', '${request.bagsNeeded} kantong darah'),
                  _buildDocField('Dokter', 'dr. Andri Kusuma, Sp.PD'),
                  if (request.notes != null && request.notes!.isNotEmpty)
                    _buildDocField('Catatan', request.notes!),
                  const SizedBox(height: 20),
                  // Date and signature area
                  Align(
                    alignment: Alignment.centerRight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'Lamongan, ${_formatDate(request.createdAt ?? DateTime(2025, 9, 8))}',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Signature
                        CustomPaint(
                          size: const Size(120, 36),
                          painter: _SignaturePainter(),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'dr. Andri Kusuma, Sp.PD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            decoration: TextDecoration.underline,
                            color: Color(0xFF1A1D2E),
                          ),
                        ),
                        Text(
                          'NIP. 197205162002121001',
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey.shade500,
                          ),
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
    );
  }

  Widget _buildDocField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 11)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocFieldHighlighted(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 11)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        // ─── APPROVE BUTTON ──────────
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: onApprove,
            icon: const Icon(Icons.check_circle_outline, size: 20),
            label: const Text('Setujui Permintaan (Kirim Notifikasi)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // ─── REJECT BUTTON ───────────
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: onReject,
            icon: const Icon(Icons.block_rounded, size: 18),
            label: const Text('Tolak / Hubungi Faskes'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFE53935),
              side: const BorderSide(color: Color(0xFFE53935), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── HELPER METHODS ──────────────────────────────

  String _statusLabel(String status) {
    switch (status) {
      case 'menunggu':
      case 'pending':
        return 'Menunggu Verifikasi';
      case 'diproses':
      case 'in_progress':
        return 'Sedang Diproses';
      case 'terpenuhi':
      case 'completed':
        return 'Terpenuhi';
      case 'kedaluwarsa':
      case 'cancelled':
        return 'Ditolak / Kedaluwarsa';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }
}

/// Simple signature-like painter for the document preview
class _SignaturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF1A1D2E)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.cubicTo(
      size.width * 0.15, size.height * 0.2,
      size.width * 0.3, size.height * 0.9,
      size.width * 0.45, size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.55, size.height * 0.1,
      size.width * 0.7, size.height * 0.8,
      size.width * 0.85, size.height * 0.3,
    );
    path.lineTo(size.width, size.height * 0.5);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
