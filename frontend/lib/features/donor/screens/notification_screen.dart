import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../routes/app_router.dart';

class NotificationScreen extends StatefulWidget {
  final BloodRequestModel? initialRequest;

  const NotificationScreen({super.key, this.initialRequest});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with TickerProviderStateMixin {
  final _requestRepo = BloodRequestRepository();
  BloodRequestModel? _currentRequest;
  List<BloodRequestModel> _allActiveRequests = [];

  // Countdown timer 10 menit (600 detik)
  late int _remainingSeconds;
  Timer? _countdownTimer;

  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _radarController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _radarAnimation;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = 600;

    // Pulse animation pada badge golongan darah
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Slide-up animation untuk card notifikasi
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Radar pulse animation pada header icon
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
    _radarAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _radarController, curve: Curves.easeOut),
    );

    _startCountdown();
    _loadRequests();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _slideController.forward();
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (widget.initialRequest != null) {
      setState(() {
        _currentRequest = widget.initialRequest;
      });
      return;
    }

    try {
      final diproses = await _requestRepo.getRequests(status: 'diproses');
      final menunggu = await _requestRepo.getRequests(status: 'menunggu');
      final all = [...diproses, ...menunggu];

      all.sort((a, b) {
        const order = {
          'kritis': 0,
          'critical': 0,
          'tinggi': 1,
          'urgent': 1,
          'sedang': 2,
          'normal': 2,
        };
        final oA = order[a.urgencyLevel.toLowerCase()] ?? 2;
        final oB = order[b.urgencyLevel.toLowerCase()] ?? 2;
        return oA.compareTo(oB);
      });

      if (mounted) {
        setState(() {
          _allActiveRequests = all;
          _currentRequest = all.isNotEmpty ? all.first : null;
        });
      }
    } catch (_) {
      if (mounted) setState(() {});
    }
  }

  String _formatCountdown() {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    if (_remainingSeconds == 600) return '10 menit';
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get _countdownProgress => _remainingSeconds / 600.0;

  void _handleAccept() {
    final req = _currentRequest ??
        BloodRequestModel(
          id: 1,
          requesterId: 1,
          bloodType: 'O',
          rhesus: '+',
          bagsNeeded: 2,
          urgencyLevel: 'kritis',
          latitudeFaskes: -7.126500,
          longitudeFaskes: 112.418200,
          radiusKm: 3.2,
          hospitalName: 'RSUD Dr. Soegiri Lamongan',
          status: 'diproses',
          patientName: 'Pasien IGD Darurat',
        );

    Navigator.pushReplacementNamed(
      context,
      AppRouter.respondRequestRoute,
      arguments: req,
    );
  }

  void _handleReject() {
    if (_allActiveRequests.length > 1) {
      setState(() {
        _allActiveRequests.removeAt(0);
        _currentRequest = _allActiveRequests.first;
        _remainingSeconds = 600;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permintaan dilewati. Menampilkan permintaan berikutnya.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFF1C2438),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Permintaan donor ditolak.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFF1C2438),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final req = _currentRequest;
    final bloodLabel = req != null ? req.bloodLabel : 'O+';
    final hospitalName = req?.hospitalName ?? 'RSUD Dr. Soegiri Lamongan';
    final distance = req != null ? req.radiusKm.toStringAsFixed(1) : '3.2';
    final eta = req != null
        ? '${(req.radiusKm * 3.8).round().clamp(5, 30)}'
        : '12';
    final urgencyText = req != null
        ? (req.urgencyLevel == 'kritis' || req.urgencyLevel == 'critical'
            ? 'Kritis'
            : req.urgencyLevel == 'tinggi' || req.urgencyLevel == 'urgent'
                ? 'Urgent'
                : 'Normal')
        : 'Urgent';

    return Scaffold(
      backgroundColor: const Color(0xFF0F1623),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── STATUS BAR ──
            _buildStatusBar(),

            const SizedBox(height: 4),

            // ── TITLE ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Notifikasi Donor Darah',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
            ),

            const SizedBox(height: 18),

            // ── APP ICON GRID (decorative background) ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _buildAppGrid(),
            ),

            const Spacer(),

            // ── COUNTDOWN PROGRESS BAR ──
            _buildCountdownBar(),

            const SizedBox(height: 10),

            // ── NOTIFICATION CARD (slide-up) ──
            SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildNotificationCard(
                  bloodLabel: bloodLabel,
                  hospitalName: hospitalName,
                  distance: distance,
                  eta: eta,
                  urgencyText: urgencyText,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── EXPIRY HINT ──
            Center(
              child: Text(
                'Notifikasi akan kedaluwarsa dalam ${_formatCountdown()}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: Colors.white.withValues(alpha: 0.35),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── HOME INDICATOR ──
            Center(
              child: Container(
                width: 120,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────
  // STATUS BAR
  // ───────────────────────────────────────────
  Widget _buildStatusBar() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$hour:$minute',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          Row(
            children: [
              if (Navigator.canPop(context))
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white70,
                          size: 15,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          'Kembali',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const Icon(Icons.signal_cellular_alt, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              const Icon(Icons.wifi_rounded, color: Colors.white, size: 15),
              const SizedBox(width: 5),
              const Icon(Icons.battery_full_rounded, color: Colors.white, size: 18),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────
  // APP GRID (decorative background icons)
  // ───────────────────────────────────────────
  Widget _buildAppGrid() {
    final List<_AppIconData> icons = [
      const _AppIconData(Icons.local_hospital_rounded, Color(0xFF64748B)),
      const _AppIconData(Icons.water_drop_rounded, Color(0xFFE11D48)),
      const _AppIconData(Icons.favorite_rounded, Color(0xFFBE185D)),
      const _AppIconData(Icons.water_drop_outlined, Color(0xFFE11D48)),
      const _AppIconData(Icons.description_outlined, Color(0xFF64748B)),
      const _AppIconData(Icons.notifications_rounded, Color(0xFFD97706)),
      const _AppIconData(Icons.credit_card_rounded, Color(0xFF2563EB)),
      const _AppIconData(Icons.bolt_rounded, Color(0xFFD97706)),
    ];
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: icons.take(4).map(_buildAppIconTile).toList(),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: icons.skip(4).map(_buildAppIconTile).toList(),
        ),
      ],
    );
  }

  Widget _buildAppIconTile(_AppIconData d) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: const Color(0xFF1C2438),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
          width: 1,
        ),
      ),
      child: Icon(d.icon, color: d.color.withValues(alpha: 0.65), size: 26),
    );
  }

  // ───────────────────────────────────────────
  // COUNTDOWN PROGRESS BAR
  // ───────────────────────────────────────────
  Widget _buildCountdownBar() {
    final progress = _countdownProgress;
    final barColor = progress > 0.5
        ? const Color(0xFF22C55E)
        : progress > 0.25
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);
    final timerStr = _remainingSeconds == 600
        ? '10:00'
        : '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            timerStr,
            style: GoogleFonts.plusJakartaSans(
              color: barColor,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────
  // NOTIFICATION CARD
  // ───────────────────────────────────────────
  Widget _buildNotificationCard({
    required String bloodLabel,
    required String hospitalName,
    required String distance,
    required String eta,
    required String urgencyText,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 40,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: const Color(0xFFDC2626).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(urgencyText),
          const SizedBox(height: 16),
          _buildBloodRequestInfo(bloodLabel, hospitalName),
          const SizedBox(height: 14),
          _buildLocationBox(distance, eta),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildCardHeader(String urgencyText) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Radar icon with animated ring
        SizedBox(
          width: 38,
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _radarAnimation,
                builder: (context, child) => Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFDC2626)
                          .withValues(alpha: (1 - _radarAnimation.value) * 0.5),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: const Icon(
                  Icons.track_changes_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TANGGAP DONOR DARAH',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                'Sekarang • $urgencyText',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Live indicator dot
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: Color(0xFFDC2626),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  Widget _buildBloodRequestInfo(String bloodLabel, String hospitalName) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              bloodLabel,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Urgent: Golongan Darah $bloodLabel\nDiperlukan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(
                    Icons.local_hospital_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      hospitalName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationBox(String distance, String eta) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFDC2626).withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFFDC2626),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$distance km dari lokasi Anda',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Estimasi tiba: ~$eta menit',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _handleAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Terima',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: _handleReject,
              style: OutlinedButton.styleFrom(
                backgroundColor: const Color(0xFFF8FAFC),
                foregroundColor: const Color(0xFF64748B),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                padding: EdgeInsets.zero,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.close_rounded, size: 18, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text(
                    'Tolak',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Helper class
class _AppIconData {
  final IconData icon;
  final Color color;
  const _AppIconData(this.icon, this.color);
}
