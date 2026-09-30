import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_top_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Settings state
  double _notifRadius = 10.0;
  double _broadcastInterval = 30.0;
  bool _autoAssign = true;
  bool _urgentNotif = true;
  bool _emailNotif = false;
  bool _smsNotif = true;
  bool _maintenanceMode = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminTopBar(
          title: 'Pengaturan & Konfigurasi Sistem',
          subtitle: 'PENGATURAN',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    children: [
                      _buildSettingsSection(
                        icon: Icons.notifications_active_rounded,
                        title: 'Parameter Notifikasi Darurat',
                        description: 'Konfigurasi radius dan interval pengiriman notifikasi kepada pendonor terdekat.',
                        children: [
                          _buildSliderSetting(
                            'Radius Notifikasi Darurat',
                            'Jarak maksimum pendonor dari lokasi rumah sakit yang akan menerima notifikasi.',
                            _notifRadius,
                            1,
                            50,
                            'km',
                            (v) => setState(() => _notifRadius = v),
                          ),
                          const SizedBox(height: 20),
                          _buildSliderSetting(
                            'Interval Broadcast Lokasi',
                            'Seberapa sering lokasi pendonor dikirim ke pemohon saat perjalanan.',
                            _broadcastInterval,
                            5,
                            120,
                            'detik',
                            (v) => setState(() => _broadcastInterval = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSettingsSection(
                        icon: Icons.tune_rounded,
                        title: 'Pengaturan Konfirmasi Donor',
                        description: 'Atur bagaimana sistem mengelola pencocokan dan konfirmasi pendonor.',
                        children: [
                          _buildToggleSetting(
                            'Auto-Assign Pendonor Terdekat',
                            'Sistem otomatis menugaskan pendonor terdekat yang cocok.',
                            _autoAssign,
                            (v) => setState(() => _autoAssign = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right Column
                Expanded(
                  child: Column(
                    children: [
                      _buildSettingsSection(
                        icon: Icons.campaign_rounded,
                        title: 'Kanal Notifikasi',
                        description: 'Pilih kanal yang digunakan untuk mengirim notifikasi kepada pendonor.',
                        children: [
                          _buildToggleSetting(
                            'Push Notification (Urgent)',
                            'Kirim notifikasi push untuk permintaan darurat & kritis.',
                            _urgentNotif,
                            (v) => setState(() => _urgentNotif = v),
                          ),
                          const SizedBox(height: 12),
                          _buildToggleSetting(
                            'Email Notification',
                            'Kirim email notifikasi untuk ringkasan harian.',
                            _emailNotif,
                            (v) => setState(() => _emailNotif = v),
                          ),
                          const SizedBox(height: 12),
                          _buildToggleSetting(
                            'SMS Gateway',
                            'Kirim SMS ke pendonor yang tidak memiliki akses internet.',
                            _smsNotif,
                            (v) => setState(() => _smsNotif = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildSettingsSection(
                        icon: Icons.build_circle_rounded,
                        title: 'Pengaturan Sistem',
                        description: 'Kontrol status dan mode operasional sistem.',
                        children: [
                          _buildToggleSetting(
                            'Mode Pemeliharaan (Maintenance)',
                            'Menonaktifkan akses publik sementara untuk pemeliharaan sistem.',
                            _maintenanceMode,
                            (v) => setState(() => _maintenanceMode = v),
                            isDanger: true,
                          ),
                          const SizedBox(height: 20),
                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Pengaturan berhasil disimpan!'),
                                    backgroundColor: AppTheme.statusSuccess,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: Text(
                                'Simpan Pengaturan',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentTeal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection({
    required IconData icon,
    required String title,
    required String description,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primaryRed, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppTheme.dividerLight),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSliderSetting(
    String label,
    String description,
    double value,
    double min,
    double max,
    String unit,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.round()} $unit',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryRed,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppTheme.primaryRed,
            inactiveTrackColor: AppTheme.primaryRed.withValues(alpha: 0.15),
            thumbColor: AppTheme.primaryRed,
            overlayColor: AppTheme.primaryRed.withValues(alpha: 0.1),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    String label,
    String description,
    bool value,
    ValueChanged<bool> onChanged, {
    bool isDanger = false,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDanger && value ? AppTheme.statusDanger : AppTheme.textPrimary,
                ),
              ),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: isDanger ? AppTheme.statusDanger : AppTheme.accentTeal,
        ),
      ],
    );
  }
}
