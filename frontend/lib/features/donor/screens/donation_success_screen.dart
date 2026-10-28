import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_router.dart';

class DonationSuccessScreen extends StatefulWidget {
  final String? donorName;
  final String? bloodType;
  final String volume;
  final String hospitalName;
  final String certificateNo;
  final String donationDate;
  final int totalDonations;
  final String totalVolume;
  final String livesSaved;
  final String nextDonationDate;
  final int nextDonationDays;
  final VoidCallback? onBackToDashboard;

  const DonationSuccessScreen({
    super.key,
    this.donorName,
    this.bloodType,
    this.volume = '400 mL',
    this.hospitalName = 'RSUD Dr. Soegiri',
    this.certificateNo = 'PMI-2025-0847',
    this.donationDate = '8 Sep 2025, 10:23',
    this.totalDonations = 9,
    this.totalVolume = '3.6 L',
    this.livesSaved = '27+',
    this.nextDonationDate = '3 November 2025',
    this.nextDonationDays = 56,
    this.onBackToDashboard,
  });

  @override
  State<DonationSuccessScreen> createState() => _DonationSuccessScreenState();
}

class _DonationSuccessScreenState extends State<DonationSuccessScreen> {
  late String _donorName;
  late String _bloodType;

  @override
  void initState() {
    super.initState();
    _donorName = widget.donorName ?? '';
    _bloodType = widget.bloodType ?? '';
    // Jika nama/golongan darah belum dioper, ambil dari akun yang sedang login
    if (_donorName.isEmpty || _bloodType.isEmpty) {
      _loadCurrentUser();
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await AuthRepository().getCurrentUser();
      if (user != null && mounted) {
        setState(() {
          if (_donorName.isEmpty) {
            _donorName = user.name.isNotEmpty ? user.name : 'Pendonor';
          }
          if (_bloodType.isEmpty) {
            final bt = user.bloodType ?? 'O';
            final rh = user.rhesus ?? '+';
            final rhLabel = rh == '-' ? 'Rhesus -' : 'Rhesus +';
            _bloodType = '$bt$rh ($rhLabel)';
          }
        });
      }
    } catch (_) {
      // Fallback jika gagal mengambil data user
      if (mounted) {
        setState(() {
          if (_donorName.isEmpty) _donorName = 'Pendonor';
          if (_bloodType.isEmpty) _bloodType = 'O+ (Rhesus +)';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final donorName = _donorName.isNotEmpty ? _donorName : 'Pendonor';
    final bloodType = _bloodType.isNotEmpty ? _bloodType : 'O+ (Rhesus +)';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── 1. HEADER MERAH GRADIENT DENGAN SELEBRASI 🎉 ──
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB91C1C),
                    Color(0xFFDC2626),
                    Color(0xFFE11D48),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                  child: Column(
                    children: [
                      // Ilustrasi Party Popper / Confetti
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          '🎉',
                          style: TextStyle(fontSize: 32),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Teks Judul Donasi Berhasil
                      Text(
                        'Donasi Berhasil!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Subtitle Nama Pendonor
                      Text(
                        'Terima kasih, $donorName',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 2. CARD UTAMA REKAM DONASI TERSIMPAN ──
            Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Badge Tetes Darah Tengah
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFECDD3), width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.water_drop_rounded,
                          color: Color(0xFFDC2626),
                          size: 26,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Judul & Tanggal
                      Text(
                        'Rekam Donasi Tersimpan',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Data dikirim ke PMI Lamongan • ${widget.donationDate}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 2x2 Grid Informasi Donasi
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoBox(
                              label: 'Golongan Darah',
                              value: bloodType,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoBox(
                              label: 'Volume',
                              value: widget.volume,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoBox(
                              label: 'Rumah Sakit',
                              value: widget.hospitalName,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildInfoBox(
                              label: 'No. Sertifikat',
                              value: widget.certificateNo,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Strip Metrik Dampak Sosial (Pinkish Container)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFECDD3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildImpactColumn(
                                value: '${widget.totalDonations}x',
                                label: 'Total\nDonor',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: const Color(0xFFFECDD3),
                            ),
                            Expanded(
                              child: _buildImpactColumn(
                                value: widget.totalVolume,
                                label: 'Total\nVolume',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: const Color(0xFFFECDD3),
                            ),
                            Expanded(
                              child: _buildImpactColumn(
                                value: widget.livesSaved,
                                label: 'Nyawa\nTerbantu',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 3. CARD DONOR BERIKUTNYA ──
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
                    Row(
                      children: [
                        Text(
                          'Donor Berikutnya',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Minimal ${widget.nextDonationDays} hari',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress bar regenerasi (awal)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(
                        value: 0.15,
                        backgroundColor: Color(0xFFF1F5F9),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        const Text('📅', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          widget.nextDonationDate,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Anda akan mendapat notifikasi pengingat',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── 4. SECTION PENCAPAIAN ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'PENCAPAIAN',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF64748B),
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 3 Card Pencapaian (Badges)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAchievementCard(
                      icon: '🥈',
                      title: 'Silver\nDonor',
                      subtitle: '${widget.totalDonations} kali donor',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAchievementCard(
                      icon: '⚡',
                      title: 'Responder',
                      subtitle: 'Notif urgent',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildAchievementCard(
                      icon: '❤️',
                      title: 'Life Saver',
                      subtitle: '${widget.livesSaved} terbantu',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ── 5. TOMBOL KEMBALI KE DASHBOARD ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (widget.onBackToDashboard != null) {
                      widget.onBackToDashboard!();
                    } else {
                      final role = await AuthRepository().getSavedRole() ?? 'donor';
                      if (context.mounted) {
                        AppRouter.navigateByRole(context, role);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Kembali ke Dashboard',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ─── Helper: Info Tile Box ───
  Widget _buildInfoBox({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─── Helper: Kolom Metrik Dampak Sosial ───
  Widget _buildImpactColumn({
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: const Color(0xFFDC2626),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
            height: 1.15,
          ),
        ),
      ],
    );
  }

  // ─── Helper: Card Badge Pencapaian ───
  Widget _buildAchievementCard({
    required String icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 9,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
