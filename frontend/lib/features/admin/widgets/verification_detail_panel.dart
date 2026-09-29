import 'dart:convert';
import 'dart:typed_data';
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
            // ─── DATA PERMOHONAN DARI FORM ──────────
            _buildDataPermohonan(),
            const SizedBox(height: 20),
            // ─── LAMPIRAN SURAT DOKTER (foto) ───────
            _buildLampiranSuratDokter(context),
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

  /// Menampilkan data permohonan yang SEBENARNYA di-submit dari form requester
  Widget _buildDataPermohonan() {
    final urgencyLabel = _urgencyLabel(request.urgencyLevel);
    final urgencyColor = _urgencyColor(request.urgencyLevel);

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
                const Icon(Icons.assignment_outlined, size: 18, color: Color(0xFF1A1D2E)),
                const SizedBox(width: 8),
                const Text(
                  'DATA PERMOHONAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2E),
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Text(
                  'ID: REQ-${request.id.toString().padLeft(5, '0')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.person_outline,
                  'Nama Pasien',
                  request.patientName,
                ),
                _buildInfoRow(
                  Icons.local_hospital_outlined,
                  'Rumah Sakit',
                  request.hospitalName ?? 'Tidak disebutkan',
                ),
                _buildInfoRowHighlighted(
                  Icons.bloodtype_outlined,
                  'Golongan Darah',
                  '${request.bloodType} Rhesus ${request.rhesus == '+' ? 'Positif' : 'Negatif'} (${request.bloodLabel})',
                ),
                _buildInfoRow(
                  Icons.shopping_bag_outlined,
                  'Jumlah Kantong',
                  '${request.bagsNeeded} kantong darah',
                ),
                _buildInfoRowWithBadge(
                  Icons.priority_high_rounded,
                  'Tingkat Urgensi',
                  urgencyLabel,
                  urgencyColor,
                ),
                if (request.notes != null && request.notes!.isNotEmpty)
                  _buildInfoRow(
                    Icons.notes_outlined,
                    'Catatan Tambahan',
                    request.notes!,
                  ),
                _buildInfoRow(
                  Icons.access_time_outlined,
                  'Waktu Pengajuan',
                  request.createdAt != null
                      ? _formatDateTime(request.createdAt!)
                      : '-',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Menampilkan lampiran foto surat dokter yang diupload requester
  Widget _buildLampiranSuratDokter(BuildContext context) {
    final hasSuratDokter = request.suratDokter != null && request.suratDokter!.isNotEmpty;

    // Cek apakah surat dokter berupa base64 image data
    final isBase64Image = hasSuratDokter && _isBase64ImageData(request.suratDokter!);

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
                Icon(
                  hasSuratDokter ? Icons.verified_outlined : Icons.warning_amber_rounded,
                  size: 18,
                  color: hasSuratDokter ? const Color(0xFF2E7D32) : const Color(0xFFFF6D00),
                ),
                const SizedBox(width: 8),
                const Text(
                  'LAMPIRAN SURAT DOKTER',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1D2E),
                    letterSpacing: 0.6,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasSuratDokter
                        ? const Color(0xFFE8F5E9)
                        : const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasSuratDokter ? 'Terlampir' : 'Tidak Ada',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: hasSuratDokter
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFFF6D00),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: hasSuratDokter
                ? _buildSuratDokterContent(context, isBase64Image)
                : _buildNoSuratDokter(),
          ),
        ],
      ),
    );
  }

  Widget _buildSuratDokterContent(BuildContext context, bool isBase64Image) {
    if (isBase64Image) {
      // Decode dan tampilkan gambar dari base64
      final base64Str = _extractBase64Data(request.suratDokter!);
      final Uint8List imageBytes = base64Decode(base64Str);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info bar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Foto surat dokter berhasil dilampirkan oleh pemohon',
                    style: TextStyle(fontSize: 12, color: Color(0xFF14532D)),
                  ),
                ),
                Text(
                  '${(imageBytes.length / 1024).toStringAsFixed(1)} KB',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Preview gambar surat dokter
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 400),
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () => _showFullScreenImage(context, imageBytes),
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _buildImageError(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Klik gambar untuk melihat ukuran penuh',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      );
    }

    // Jika bukan base64, tampilkan sebagai nama file/teks
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_rounded, color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.suratDokter!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF14532D),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Lampiran surat keterangan dokter tersedia',
                  style: TextStyle(fontSize: 12, color: Color(0xFF166534)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSuratDokter() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        children: [
          Icon(Icons.warning_amber_rounded, size: 40, color: Colors.amber.shade700),
          const SizedBox(height: 12),
          const Text(
            'Surat Dokter Tidak Dilampirkan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF92400E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Pemohon tidak melampirkan foto surat keterangan dokter.\n'
            'Pertimbangkan untuk menghubungi faskes terkait untuk verifikasi manual.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      height: 120,
      color: const Color(0xFFF5F5F5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 32, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Gagal menampilkan gambar',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          children: [
            // Full screen image
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  maxScale: 5.0,
                  child: Image.memory(
                    imageBytes,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(ctx),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1D2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowHighlighted(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE53935)),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFE53935),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowWithBadge(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 12)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
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

  String _urgencyLabel(String level) {
    switch (level.toLowerCase()) {
      case 'kritis':
      case 'critical':
        return 'KRITIS';
      case 'tinggi':
      case 'urgent':
        return 'MENDESAK';
      case 'sedang':
      case 'normal':
      default:
        return 'NORMAL';
    }
  }

  Color _urgencyColor(String level) {
    switch (level.toLowerCase()) {
      case 'kritis':
      case 'critical':
        return const Color(0xFFE53935);
      case 'tinggi':
      case 'urgent':
        return const Color(0xFFFF6D00);
      case 'sedang':
      case 'normal':
      default:
        return const Color(0xFF2E7D32);
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = [
      '', 'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month]} ${dt.year}, $h:$m WIB';
  }

  bool _isBase64ImageData(String data) {
    // Cek apakah data dimulai dengan prefix data:image atau berupa base64 murni
    if (data.startsWith('data:image')) return true;
    // Cek apakah string cukup panjang dan terlihat seperti base64
    if (data.length > 100) {
      try {
        base64Decode(_extractBase64Data(data));
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  String _extractBase64Data(String data) {
    // Hapus prefix data:image/...;base64, jika ada
    if (data.contains(',')) {
      return data.split(',').last;
    }
    return data;
  }
}
