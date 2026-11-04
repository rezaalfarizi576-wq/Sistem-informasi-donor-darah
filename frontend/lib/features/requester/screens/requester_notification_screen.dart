import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/models/blood_request_model.dart';
import '../../../data/repositories/blood_request_repository.dart';
import '../../../routes/app_router.dart';

class RequesterNotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final String badgeText;
  final Color badgeColor;
  final Color badgeTextColor;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final BloodRequestModel? request;

  RequesterNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.badgeText,
    required this.badgeColor,
    required this.badgeTextColor,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    this.request,
  });
}

class RequesterNotificationScreen extends StatefulWidget {
  const RequesterNotificationScreen({super.key});

  @override
  State<RequesterNotificationScreen> createState() => _RequesterNotificationScreenState();
}

class _RequesterNotificationScreenState extends State<RequesterNotificationScreen> {
  final _requestRepo = BloodRequestRepository();
  bool _isLoading = true;
  List<RequesterNotificationItem> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadRequesterNotifications();
  }

  Future<void> _loadRequesterNotifications() async {
    setState(() => _isLoading = true);
    try {
      final myReqs = await _requestRepo.getMyRequests();
      final items = <RequesterNotificationItem>[];

      for (int i = 0; i < myReqs.length; i++) {
        final req = myReqs[i];
        final status = req.status.toLowerCase();
        final hospital = req.hospitalName ?? 'RSUD Dr. Soegiri Lamongan';
        final hasDonor = req.hasAcceptedDonor || req.acceptedDonorsCount > 0;

        if (status == 'menunggu') {
          items.add(
            RequesterNotificationItem(
              id: 'req_wait_${req.id}',
              title: 'Permohonan Dalam Verifikasi',
              message:
                  'Permohonan darah ${req.bagsNeeded} kantong (${req.bloodType}${req.rhesus}) untuk pasien ${req.patientName} di $hospital berhasil dicatat dan sedang dalam antrean verifikasi Posko UDD PMI Lamongan.',
              time: 'Baru saja',
              badgeText: 'MENUNGGU VERIFIKASI',
              badgeColor: const Color(0xFFFEF3C7),
              badgeTextColor: const Color(0xFFB45309),
              icon: Icons.hourglass_top_rounded,
              iconColor: const Color(0xFFD97706),
              iconBgColor: const Color(0xFFFFFBEB),
              request: req,
            ),
          );
        } else if (status == 'diproses') {
          if (hasDonor) {
            items.add(
              RequesterNotificationItem(
                id: 'req_moving_${req.id}',
                title: 'Relawan Siaga Menuju RS! 🏍️',
                message:
                    'Relawan pendonor darah telah mengonfirmasi dan sedang bergerak menuju $hospital untuk pasien ${req.patientName}. Pantau live pergerakannya di peta.',
                time: 'Sedang berlangsung',
                badgeText: 'RELAWAN MENUJU RS',
                badgeColor: const Color(0xFFDCFCE7),
                badgeTextColor: const Color(0xFF15803D),
                icon: Icons.two_wheeler_rounded,
                iconColor: const Color(0xFF16A34A),
                iconBgColor: const Color(0xFFF0FDF4),
                request: req,
              ),
            );
          } else {
            items.add(
              RequesterNotificationItem(
                id: 'req_proc_${req.id}',
                title: 'Permohonan Disetujui & Disiarkan 📡',
                message:
                    'Permohonan darah ${req.bagsNeeded} kantong (${req.bloodType}${req.rhesus}) telah diverifikasi admin dan sinyal siaga darurat sedang dipancarkan ke relawan donor siaga terdekat.',
                time: 'Diproses',
                badgeText: 'MEMINDAI RELAWAN',
                badgeColor: const Color(0xFFEFF6FF),
                badgeTextColor: const Color(0xFF1D4ED8),
                icon: Icons.radar_rounded,
                iconColor: const Color(0xFF2563EB),
                iconBgColor: const Color(0xFFEFF6FF),
                request: req,
              ),
            );
          }
        } else if (status == 'selesai') {
          items.add(
            RequesterNotificationItem(
              id: 'req_done_${req.id}',
              title: 'Permohonan Selesai Terpenuhi 🎉',
              message:
                  'Kebutuhan darah darurat untuk pasien ${req.patientName} di $hospital telah berhasil terpenuhi. Terima kasih atas kerja sama Anda dengan PMI Lamongan.',
              time: 'Selesai',
              badgeText: 'SELESAI',
              badgeColor: const Color(0xFFF1F5F9),
              badgeTextColor: const Color(0xFF475569),
              icon: Icons.check_circle_rounded,
              iconColor: const Color(0xFF16A34A),
              iconBgColor: const Color(0xFFF0FDF4),
              request: req,
            ),
          );
        }
      }

      // Notifikasi Bantuan Posko Resmi
      items.add(
        RequesterNotificationItem(
          id: 'posko_info',
          title: 'Posko Siaga UDD PMI Lamongan (24 Jam)',
          message:
              'Jika kondisi pasien darurat kritis atau butuh penanganan percepatan transfusi, hubungi call center siaga di (0322) 321118.',
          time: 'Informasi Resmi',
          badgeText: 'LAYANAN POSKO',
          badgeColor: const Color(0xFFFEE2E2),
          badgeTextColor: const Color(0xFFDC2626),
          icon: Icons.support_agent_rounded,
          iconColor: const Color(0xFFDC2626),
          iconBgColor: const Color(0xFFFEF2F2),
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

  void _onNotificationTap(RequesterNotificationItem item) {
    if (item.request != null) {
      Navigator.pushNamed(
        context,
        AppRouter.requesterPantauRoute,
        arguments: item.request!.id.toString(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notifikasi Pemohon',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Update Status Permohonan & Posko PMI',
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
            tooltip: 'Segarkan Notifikasi',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
            onPressed: _loadRequesterNotifications,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFF1F5F9), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFDC2626)),
            )
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  color: const Color(0xFFDC2626),
                  onRefresh: _loadRequesterNotifications,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    itemCount: _notifications.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return _buildNotificationCard(item);
                    },
                  ),
                ),
    );
  }

  Widget _buildNotificationCard(RequesterNotificationItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onNotificationTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Baris Badge & Waktu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.badgeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: item.badgeTextColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Text(
                    item.time,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Baris Ikon & Konten Teks
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
                        Text(
                          item.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.message,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (item.request != null) ...[
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Buka Detail & Pantau',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFFDC2626)),
                  ],
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF94A3B8),
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Notifikasi',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Saat Anda mengajukan permohonan darah, update verifikasi dari posko dan respon relawan akan muncul di sini.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

