import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/models/dispatch_ticket_model.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../data/repositories/tracking_repository.dart';
import '../../../routes/app_router.dart';

enum NotificationCategory {
  all,
  emergency,
  reminder,
  pmi,
  system,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationCategory category;
  final DateTime timestamp;
  bool isRead;
  final BloodRequestModel? bloodRequest;
  final String? hospitalName;
  final String? bloodLabel;
  final String? urgency;
  final String? distance;
  final String? eta;
  final String? badgeText;
  final Color? badgeColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.timestamp,
    this.isRead = false,
    this.bloodRequest,
    this.hospitalName,
    this.bloodLabel,
    this.urgency,
    this.distance,
    this.eta,
    this.badgeText,
    this.badgeColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mnt lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    return '${diff.inDays} hari lalu';
  }
}

class NotificationScreen extends StatefulWidget {
  final BloodRequestModel? initialRequest;

  const NotificationScreen({super.key, this.initialRequest});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _requestRepo = BloodRequestRepository();
  bool _isLoading = true;
  NotificationCategory _selectedCategory = NotificationCategory.all;
  List<NotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      double donorLat = -7.126500;
      double donorLng = 112.418200;
      try {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          donorLat = pos.latitude;
          donorLng = pos.longitude;
        }
      } catch (_) {}

      // Ambil permohonan aktif dari backend
      List<BloodRequestModel> requests = [];
      try {
        requests = await _requestRepo.getNearbyRequests(
          lat: donorLat,
          lng: donorLng,
          maxRadius: 10.0,
        );
      } catch (_) {}

      if (requests.isEmpty) {
        try {
          final diproses = await _requestRepo.getRequests(status: 'diproses');
          final menunggu = await _requestRepo.getRequests(status: 'menunggu');
          requests = [...diproses, ...menunggu];
        } catch (_) {}
      }

      // Gabungkan initialRequest jika ada
      if (widget.initialRequest != null) {
        if (!requests.any((r) => r.id == widget.initialRequest!.id)) {
          requests.insert(0, widget.initialRequest!);
        }
      }

      final items = <NotificationItem>[];

      // 1. Notifikasi Permintaan Darah Darurat
      for (int i = 0; i < requests.length; i++) {
        final req = requests[i];
        final dist = req.distanceDisplay ?? '${req.radiusKm.toStringAsFixed(1)} km';
        final etaMinutes = ((req.distanceKm ?? req.radiusKm) * 2.5).round().clamp(3, 30);
        final isCrit = req.urgencyLevel.toLowerCase() == 'kritis' ||
            req.urgencyLevel.toLowerCase() == 'critical';

        items.add(
          NotificationItem(
            id: 'req_${req.id}',
            title: 'Panggilan Darurat: Golongan ${req.bloodLabel}',
            message:
                '${req.hospitalName ?? "RSUD Dr. Soegiri Lamongan"} butuh ${req.bagsNeeded} kantong darah segera untuk ${req.patientName}. Estimasi tiba ~$etaMinutes menit ($dist).',
            category: NotificationCategory.emergency,
            timestamp: DateTime.now().subtract(Duration(minutes: (i * 12) + 5)),
            isRead: i > 0, // Item pertama belum dibaca
            bloodRequest: req,
            hospitalName: req.hospitalName ?? 'RSUD Dr. Soegiri Lamongan',
            bloodLabel: req.bloodLabel,
            urgency: isCrit ? 'Kritis' : 'Mendesak',
            distance: dist,
            eta: '$etaMinutes menit',
            badgeText: isCrit ? 'KRITIS' : 'URGENT',
            badgeColor: isCrit ? const Color(0xFFDC2626) : const Color(0xFFEA580C),
            icon: Icons.emergency_rounded,
            iconColor: const Color(0xFFDC2626),
            iconBgColor: const Color(0xFFFEE2E2),
          ),
        );
      }

      // 2. Notifikasi Tiket & Jadwal Donor
      items.add(
        NotificationItem(
          id: 'schedule_1',
          title: 'Waktunya Donor Darah Kembali! 🩸',
          message:
              'Masa jeda donor 60 hari Anda telah selesai. Tubuh Anda sudah prima untuk berbagi kehidupan kembali di UTD PMI Lamongan.',
          category: NotificationCategory.reminder,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          isRead: false,
          badgeText: 'PENGINGAT',
          badgeColor: const Color(0xFF2563EB),
          icon: Icons.water_drop_rounded,
          iconColor: const Color(0xFF2563EB),
          iconBgColor: const Color(0xFFDBEAFE),
        ),
      );

      items.add(
        NotificationItem(
          id: 'ticket_completed_1',
          title: 'Donasi Darah Berhasil Tercatat ✅',
          message:
              'Terima kasih! Donasi 1 kantong darah Anda di UTD PMI Cabang Lamongan telah tersimpan dan siap disalurkan ke pasien yang membutuhkan.',
          category: NotificationCategory.reminder,
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
          isRead: true,
          badgeText: 'SELESAI',
          badgeColor: const Color(0xFF16A34A),
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF16A34A),
          iconBgColor: const Color(0xFFDCFCE7),
        ),
      );

      // 3. Notifikasi Info Stok & PMI
      items.add(
        NotificationItem(
          id: 'pmi_stock_warning',
          title: 'Peringatan Stok Darah UTD PMI Lamongan',
          message:
              'Persediaan darah golongan O+ dan B- menipis di UTD PMI Lamongan. Relawan dengan golongan darah tersebut dimohon kesediaannya berdonor.',
          category: NotificationCategory.pmi,
          timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
          isRead: true,
          badgeText: 'STOK MENIPIS',
          badgeColor: const Color(0xFFD97706),
          icon: Icons.bloodtype_rounded,
          iconColor: const Color(0xFFD97706),
          iconBgColor: const Color(0xFFFEF3C7),
        ),
      );

      // 4. Notifikasi Sistem & Radar
      items.add(
        NotificationItem(
          id: 'system_radar_active',
          title: 'Radar Relawan Siaga Aktif 🛰️',
          message:
              'Sistem GPS otomatis memantau kebutuhan donor darurat dalam radius 10 KM dari lokasi Anda secara real-time.',
          category: NotificationCategory.system,
          timestamp: DateTime.now().subtract(const Duration(days: 3)),
          isRead: true,
          badgeText: 'SISTEM',
          badgeColor: const Color(0xFF64748B),
          icon: Icons.radar_rounded,
          iconColor: const Color(0xFF475569),
          iconBgColor: const Color(0xFFF1F5F9),
        ),
      );

      if (mounted) {
        setState(() {
          _notifications = items;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;

  List<NotificationItem> get _filteredNotifications {
    if (_selectedCategory == NotificationCategory.all) {
      return _notifications;
    }
    return _notifications.where((n) => n.category == _selectedCategory).toList();
  }

  void _markAllAsRead() {
    setState(() {
      for (var n in _notifications) {
        n.isRead = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semua notifikasi ditandai telah dibaca',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _clearAllNotifications() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Bersihkan Notifikasi',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus semua riwayat notifikasi ini?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _notifications.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Riwayat notifikasi berhasil dibersihkan',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: const Color(0xFF0F172A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Hapus Semua',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept(BloodRequestModel req) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'Menghubungkan ke UTD PMI & Menerbitkan Tiket Triase...',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      final response = await _requestRepo.respondToRequest(req.id);
      TrackingRepository().startTracking(req.id.toString());

      DispatchTicketModel dispatch;
      if (response['dispatch'] != null) {
        dispatch = DispatchTicketModel.fromJson(response['dispatch']);
      } else {
        final todayStr = DateTime.now().year.toString() +
            DateTime.now().month.toString().padLeft(2, '0') +
            DateTime.now().day.toString().padLeft(2, '0');
        dispatch = DispatchTicketModel(
          ticketCode: response['ticket_code'] ??
              'TGP-$todayStr-${req.id.toString().padLeft(4, '0')}',
          dispatchId: '#DSP-$todayStr-${req.id.toString().padLeft(4, '0')}',
          requestId: req.id,
          donorId: 1,
          patientName: req.patientName,
          hospitalName: req.hospitalName ?? 'RSUD Dr. Soegiri Lamongan',
          bloodType: req.bloodType,
          rhesus: req.rhesus,
          bagsNeeded: req.bagsNeeded,
          urgencyLevel: req.urgencyLevel,
          notes: req.notes ?? 'Donor Darurat Fast-Track',
          hospitalLat: req.latitudeFaskes,
          hospitalLng: req.longitudeFaskes,
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.donorDispatchRoute,
          arguments: dispatch,
        );
      }
    } catch (_) {
      final todayStr = DateTime.now().year.toString() +
          DateTime.now().month.toString().padLeft(2, '0') +
          DateTime.now().day.toString().padLeft(2, '0');
      final fallbackDispatch = DispatchTicketModel(
        ticketCode: 'TGP-$todayStr-${req.id.toString().padLeft(4, '0')}',
        dispatchId: '#DSP-$todayStr-${req.id.toString().padLeft(4, '0')}',
        requestId: req.id,
        donorId: 1,
        patientName: req.patientName,
        hospitalName: req.hospitalName ?? 'RSUD Dr. Soegiri Lamongan',
        bloodType: req.bloodType,
        rhesus: req.rhesus,
        bagsNeeded: req.bagsNeeded,
        urgencyLevel: req.urgencyLevel,
        notes: req.notes ?? 'Donor Darurat Fast-Track',
        hospitalLat: req.latitudeFaskes,
        hospitalLng: req.longitudeFaskes,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.donorDispatchRoute,
          arguments: fallbackDispatch,
        );
      }
    }
  }

  void _showNotificationDetail(NotificationItem item) {
    setState(() => item.isRead = true);

    if (item.category == NotificationCategory.emergency && item.bloodRequest != null) {
      final req = item.bloodRequest!;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emergency_rounded,
                            size: 15, color: Color(0xFFDC2626)),
                        const SizedBox(width: 4),
                        Text(
                          'PANGGILAN DARURAT',
                          style: GoogleFonts.plusJakartaSans(
                            color: const Color(0xFFDC2626),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    item.timeAgo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Pasien Membutuhkan Donor Darah Segera',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      Icons.person_rounded,
                      'Nama Pasien',
                      req.patientName,
                    ),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    _buildDetailRow(
                      Icons.bloodtype_rounded,
                      'Golongan & Kebutuhan',
                      '${req.bloodLabel} (${req.bagsNeeded} Kantong)',
                      highlight: true,
                    ),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    _buildDetailRow(
                      Icons.local_hospital_rounded,
                      'Rumah Sakit',
                      req.hospitalName ?? 'RSUD Dr. Soegiri Lamongan',
                    ),
                    const Divider(height: 20, color: Color(0xFFE2E8F0)),
                    _buildDetailRow(
                      Icons.near_me_rounded,
                      'Jarak & Estimasi',
                      '${item.distance ?? "1.7 km"} • ~${item.eta ?? "8 menit"}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      child: Text(
                        'Tutup',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _handleAccept(req);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flash_on_rounded, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Terima & Respon',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  height: 1.5,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded,
                      size: 14, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(
                    item.timeAgo,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Mengerti',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value,
      {bool highlight = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              color: highlight ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredNotifications;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(Icons.arrow_back_rounded, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Notifikasi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (_unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$_unreadCount baru',
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            Text(
              'Pusat pemberitahuan siaga & riwayat info',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tandai Semua Dibaca',
            onPressed: _notifications.isEmpty ? null : _markAllAsRead,
            icon: const Icon(Icons.done_all_rounded, size: 22, color: Color(0xFF2563EB)),
          ),
          IconButton(
            tooltip: 'Bersihkan Riwayat',
            onPressed: _notifications.isEmpty ? null : _clearAllNotifications,
            icon: const Icon(Icons.delete_outline_rounded,
                size: 22, color: Color(0xFF64748B)),
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: _buildCategoryTabs(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFDC2626),
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              color: const Color(0xFFDC2626),
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildNotificationCard(item);
                      },
                    ),
            ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = [
      {'cat': NotificationCategory.all, 'label': 'Semua', 'icon': Icons.all_inbox_rounded},
      {'cat': NotificationCategory.emergency, 'label': '🚨 Darurat', 'icon': null},
      {'cat': NotificationCategory.reminder, 'label': '🩸 Jadwal & Tiket', 'icon': null},
      {'cat': NotificationCategory.pmi, 'label': '📢 Info PMI', 'icon': null},
      {'cat': NotificationCategory.system, 'label': '⚙️ Sistem', 'icon': null},
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: categories.map((c) {
            final cat = c['cat'] as NotificationCategory;
            final isSelected = _selectedCategory == cat;

            int count = 0;
            if (cat == NotificationCategory.all) {
              count = _notifications.length;
            } else {
              count = _notifications.where((n) => n.category == cat).length;
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  setState(() => _selectedCategory = cat);
                },
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Text(
                        c['label'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF475569),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.2)
                                : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem item) {
    final isEmergency = item.category == NotificationCategory.emergency;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white, size: 24),
      ),
      onDismissed: (_) {
        setState(() {
          _notifications.removeWhere((n) => n.id == item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notifikasi dihapus',
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      },
      child: InkWell(
        onTap: () => _showNotificationDetail(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: item.isRead ? Colors.white : const Color(0xFFFAFBFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? const Color(0xFFE2E8F0)
                  : (isEmergency
                      ? const Color(0xFFFCA5A5)
                      : const Color(0xFF93C5FD)),
              width: item.isRead ? 1 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row Header: Icon + Title + Time + Unread indicator
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.iconColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (item.badgeText != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (item.badgeColor ?? const Color(0xFFDC2626))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.badgeText!,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: item.badgeColor ??
                                        const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: item.isRead
                                      ? FontWeight.w600
                                      : FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.timeAgo,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!item.isRead) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isEmergency
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              // Body Message
              Padding(
                padding: const EdgeInsets.only(left: 52),
                child: Text(
                  item.message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.45,
                    color: const Color(0xFF475569),
                  ),
                ),
              ),

              // Emergency Action Buttons
              if (isEmergency && item.bloodRequest != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: () => _handleAccept(item.bloodRequest!),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.flash_on_rounded, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Respon & Donor',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _showNotificationDetail(item),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF475569),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Lihat Detail',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Notifikasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pemberitahuan darurat atau pengingat jadwal donor akan muncul di sini secara otomatis.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Perbarui',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
