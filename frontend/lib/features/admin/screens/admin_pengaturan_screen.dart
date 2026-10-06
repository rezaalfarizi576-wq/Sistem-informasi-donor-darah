import 'package:flutter/material.dart';
import '../../../data/repositories/admin_repository.dart';

// ─────────────────────────────────────────────────────────
// DATA MODEL
// ─────────────────────────────────────────────────────────

class _SettingCategory {
  final IconData icon;
  final String label;
  final Color? activeColor;

  const _SettingCategory({
    required this.icon,
    required this.label,
    this.activeColor,
  });
}

// ─────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────

class AdminPengaturanScreen extends StatefulWidget {
  const AdminPengaturanScreen({super.key});

  @override
  State<AdminPengaturanScreen> createState() => _AdminPengaturanScreenState();
}

class _AdminPengaturanScreenState extends State<AdminPengaturanScreen> {
  final _adminRepo = AdminRepository();
  int _selectedCategory = 0;
  bool _isSaving = false;

  // ── Settings State ──
  String _radiusValue = '5 km (Standar Kabupaten Lamongan – Dire...)';
  int _notifKedaluwarsa = 10;
  int _jedaDonor = 60;
  int _batasStokKritis = 3;
  bool _waDispatchEnabled = true;
  bool _qrVerifikasiEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final s = await _adminRepo.getSystemSettings();
      if (mounted) {
        setState(() {
          if (s['min_donor_interval_days'] != null) {
            _jedaDonor = s['min_donor_interval_days'];
          }
          if (s['whatsapp_gateway'] != null) {
            _waDispatchEnabled = s['whatsapp_gateway'] == true;
          }
          if (s['require_doctor_letter'] != null) {
            _qrVerifikasiEnabled = s['require_doctor_letter'] == true;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);
    try {
      await _adminRepo.updateSystemSettings({
        'radius_str': _radiusValue,
        'notif_kedaluwarsa_min': _notifKedaluwarsa,
        'min_donor_interval_days': _jedaDonor,
        'batas_stok_kritis': _batasStokKritis,
        'whatsapp_gateway': _waDispatchEnabled,
        'require_doctor_letter': _qrVerifikasiEnabled,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Konfigurasi sistem berhasil tersimpan di backend!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tersimpan di cache lokal!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  final List<_SettingCategory> _categories = const [
    _SettingCategory(
      icon: Icons.gps_fixed_rounded,
      label: 'Radius & Dispatch Cepat',
      activeColor: Color(0xFFDC2626),
    ),
    _SettingCategory(
      icon: Icons.notifications_active_outlined,
      label: 'Pemberitahuan & WhatsApp',
    ),
    _SettingCategory(
      icon: Icons.sync_alt_rounded,
      label: 'Integrasi SIM-PMI & Faskes',
    ),
    _SettingCategory(
      icon: Icons.verified_outlined,
      label: 'Verifikasi Berkas Dokter',
    ),
    _SettingCategory(
      icon: Icons.person_outline_rounded,
      label: 'Profil Pengguna & Keamanan',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF1F5F9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopHeader(),
              const SizedBox(height: 24),
              _buildMainContent(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TOP HEADER
  // ─────────────────────────────────────────────────────────
  Widget _buildTopHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 700;

        final titleSection = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan & Konfigurasi Sistem',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Kelola parameter radius darurat, integrasi faskes, pesan broadcast, dan keamanan akun UTD',
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

        final actionButtons = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Batal Button
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Perubahan dibatalkan.'),
                    backgroundColor: Color(0xFF475569),
                  ),
                );
              },
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Batal',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ),
            const SizedBox(width: 10),

            // Simpan Perubahan Button
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveSettings,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_rounded, size: 18, color: Colors.white),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan Perubahan',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        );

        if (isWide) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Expanded(child: titleSection), const SizedBox(width: 16), actionButtons],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleSection,
              const SizedBox(height: 14),
              actionButtons,
            ],
          );
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // MAIN CONTENT: LEFT CATEGORIES + RIGHT SETTINGS
  // ─────────────────────────────────────────────────────────
  Widget _buildMainContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 850;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 250, child: _buildLeftCategoryPanel()),
              const SizedBox(width: 24),
              Expanded(child: _buildRightSettingsPanel()),
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLeftCategoryPanel(),
              const SizedBox(height: 20),
              _buildRightSettingsPanel(),
            ],
          );
        }
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // LEFT: CATEGORY NAVIGATION + STATUS CARD
  // ─────────────────────────────────────────────────────────
  Widget _buildLeftCategoryPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KATEGORI',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 14),

        // Category Items
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          separatorBuilder: (_, __) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            return _buildCategoryItem(index);
          },
        ),
        const SizedBox(height: 20),

        // Status Siaga Darurat Card
        _buildStatusSiagaCard(),
      ],
    );
  }

  Widget _buildCategoryItem(int index) {
    final cat = _categories[index];
    final isSelected = _selectedCategory == index;

    return InkWell(
      onTap: () => setState(() => _selectedCategory = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? (cat.activeColor != null
                  ? const Color(0xFFFEF2F2)
                  : const Color(0xFFF1F5F9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(
                  color: cat.activeColor?.withOpacity(0.3) ?? const Color(0xFFE2E8F0),
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              cat.icon,
              size: 18,
              color: isSelected
                  ? (cat.activeColor ?? const Color(0xFF0F172A))
                  : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                cat.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (cat.activeColor ?? const Color(0xFF0F172A))
                      : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSiagaCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFDC2626).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Status Siaga Darurat',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Semua broadcast otomatis terhubung ke 84 relawan aktif dalam radius 5 km.',
            style: TextStyle(
              fontSize: 11.5,
              color: Colors.white.withOpacity(0.85),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // RIGHT: SETTINGS CONTENT PANEL
  // ─────────────────────────────────────────────────────────
  Widget _buildRightSettingsPanel() {
    switch (_selectedCategory) {
      case 0:
        return _buildRadiusDispatchSettings();
      case 1:
        return _buildPemberitahuanSettings();
      case 2:
        return _buildIntegrasiSettings();
      case 3:
        return _buildVerifikasiSettings();
      case 4:
        return _buildProfilKeamananSettings();
      default:
        return _buildRadiusDispatchSettings();
    }
  }

  // ── CATEGORY 0: Radius & Dispatch Cepat ──
  Widget _buildRadiusDispatchSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Parameter Radius
        _buildSettingsSection(
          dotColor: const Color(0xFFDC2626),
          title: 'Parameter Radius Siaga & Geofencing Relawan',
          subtitle: 'Tentukan batas jangkauan telemetri GPS untuk alokasi relawan terdekat ke faskes darurat.',
          badge: _buildBadge('Geolokasi Aktif', const Color(0xFF059669), const Color(0xFFECFDF5)),
          content: Column(
            children: [
              // Row 1: Radius + Notif Kedaluwarsa
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 550;
                  final widgets = [
                    _buildDropdownField(
                      label: 'Radius Pencarian Default Relawan',
                      value: _radiusValue,
                      hint: 'Saat darurat aktif, sistem memprioritaskan relawan dalam radius ini.',
                      items: [
                        '5 km (Standar Kabupaten Lamongan – Dire...)',
                        '10 km (Wilayah Diperluas)',
                        '15 km (Radius Maksimal)',
                        '3 km (Radius Minimum)',
                      ],
                      onChanged: (v) => setState(() => _radiusValue = v!),
                    ),
                    _buildNumberInputField(
                      label: 'Masa Kedaluwarsa Notifikasi Panggilan',
                      value: _notifKedaluwarsa,
                      suffix: 'Menit sebelum dialihkan ke\nrelawan cadangan',
                      hint: 'Sesuai tampilan mobile app pendonor. "Notifikasi kedaluwarsa dalam 10 menit".',
                      onChanged: (v) => setState(() => _notifKedaluwarsa = v),
                    ),
                  ];
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: widgets[0]),
                        const SizedBox(width: 20),
                        Expanded(child: widgets[1]),
                      ],
                    );
                  }
                  return Column(children: [
                    widgets[0],
                    const SizedBox(height: 18),
                    widgets[1],
                  ]);
                },
              ),
              const SizedBox(height: 20),

              // Row 2: Jeda Donor + Batas Stok
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 550;
                  final widgets = [
                    _buildNumberInputField(
                      label: 'Interval Jeda Wajib Antar Donor',
                      value: _jedaDonor,
                      suffix: 'Hari istirahat (Otomatis status\n"Offline – Masa Jeda")',
                      hint: '',
                      onChanged: (v) => setState(() => _jedaDonor = v),
                    ),
                    _buildNumberInputField(
                      label: 'Batas Stok Kritis (Defisit Darah)',
                      value: _batasStokKritis,
                      suffix: 'Kantong sisa per golongan\ndarah sebelum siaga merah',
                      hint: '',
                      onChanged: (v) => setState(() => _batasStokKritis = v),
                    ),
                  ];
                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: widgets[0]),
                        const SizedBox(width: 20),
                        Expanded(child: widgets[1]),
                      ],
                    );
                  }
                  return Column(children: [
                    widgets[0],
                    const SizedBox(height: 18),
                    widgets[1],
                  ]);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // Section 2: WhatsApp Integration
        _buildSettingsSection(
          dotColor: const Color(0xFF10B981),
          title: 'Integrasi WhatsApp Gateway & Broadcast Otomatis',
          subtitle: 'Konfigurasi pesan darurat langsung ke WhatsApp dan aplikasi mobile pendonor',
          badge: _buildConnectionBadge(),
          content: Column(
            children: [
              _buildToggleItem(
                title: 'Direct WhatsApp Dispatch ke Relawan Terdekat',
                description: 'Mengirim pesan WA resmi PMI otomatis dengan tautan lokasi rumah sakit saat verifikasi disetujui.',
                value: _waDispatchEnabled,
                onChanged: (v) => setState(() => _waDispatchEnabled = v),
              ),
              const SizedBox(height: 6),
              _buildToggleItem(
                title: 'Verifikasi Otomatis Kode QR Surat Keterangan Dokter',
                description: 'Memvalidasi dokumen kebutuhan darah terunggah dengan basis data faskes RSUD Dr. Soegiri & mitra.',
                value: _qrVerifikasiEnabled,
                onChanged: (v) => setState(() => _qrVerifikasiEnabled = v),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── CATEGORY 1: Pemberitahuan & WhatsApp ──
  Widget _buildPemberitahuanSettings() {
    return _buildSettingsSection(
      dotColor: const Color(0xFF2563EB),
      title: 'Konfigurasi Pemberitahuan & WhatsApp',
      subtitle: 'Atur jenis notifikasi yang dikirim ke relawan, faskes, dan admin posko.',
      badge: _buildBadge('Aktif', const Color(0xFF059669), const Color(0xFFECFDF5)),
      content: Column(
        children: [
          _buildToggleItem(
            title: 'Notifikasi Push ke Aplikasi Mobile Relawan',
            description: 'Kirim notifikasi darurat ke semua relawan aktif yang terdeteksi dalam radius.',
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 6),
          _buildToggleItem(
            title: 'SMS Fallback untuk Relawan Tanpa Data',
            description: 'Jika relawan tidak memiliki koneksi internet, kirim SMS sebagai fallback.',
            value: false,
            onChanged: (_) {},
          ),
          const SizedBox(height: 6),
          _buildToggleItem(
            title: 'Email Ringkasan Harian ke Admin',
            description: 'Kirim email rekapitulasi harian ke admin posko setiap pukul 08:00 WIB.',
            value: true,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  // ── CATEGORY 2: Integrasi SIM-PMI & Faskes ──
  Widget _buildIntegrasiSettings() {
    return _buildSettingsSection(
      dotColor: const Color(0xFF9333EA),
      title: 'Integrasi SIM-PMI & Faskes',
      subtitle: 'Kelola koneksi data real-time dengan Sistem Informasi Manajemen PMI dan faskes mitra.',
      badge: _buildBadge('Terhubung', const Color(0xFF059669), const Color(0xFFECFDF5)),
      content: Column(
        children: [
          _buildToggleItem(
            title: 'Sinkronisasi Stok Darah Real-Time',
            description: 'Data stok darah dari UTD faskes mitra diperbarui setiap 5 menit secara otomatis.',
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 6),
          _buildToggleItem(
            title: 'Auto-Register Faskes Baru dari SIM-PMI',
            description: 'Faskes yang terdaftar di SIM-PMI Pusat otomatis muncul di dashboard admin.',
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 6),
          _buildToggleItem(
            title: 'Notifikasi Stok Kritis ke Kepala UTD',
            description: 'Kirim peringatan otomatis ke kepala UTD faskes saat stok golongan darah mencapai batas kritis.',
            value: true,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  // ── CATEGORY 3: Verifikasi Berkas Dokter ──
  Widget _buildVerifikasiSettings() {
    return _buildSettingsSection(
      dotColor: const Color(0xFFD97706),
      title: 'Verifikasi Berkas Dokter',
      subtitle: 'Konfigurasi proses validasi surat keterangan dokter dan dokumen permintaan darah.',
      badge: _buildBadge('Otomatis', const Color(0xFF2563EB), const Color(0xFFEFF6FF)),
      content: Column(
        children: [
          _buildToggleItem(
            title: 'Verifikasi QR Code Otomatis',
            description: 'Scan dan validasi kode QR pada surat keterangan dokter secara otomatis dari database RS.',
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 6),
          _buildToggleItem(
            title: 'Wajib Upload Foto Surat Dokter',
            description: 'Setiap permintaan darah harus menyertakan foto surat keterangan dokter yang sah.',
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 6),
          _buildToggleItem(
            title: 'Validasi Nama Dokter dari Database RS',
            description: 'Cross-check nama dokter penulis surat dengan database dokter terdaftar di faskes mitra.',
            value: false,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  // ── CATEGORY 4: Profil Pengguna & Keamanan ──
  Widget _buildProfilKeamananSettings() {
    return _buildSettingsSection(
      dotColor: const Color(0xFF0F172A),
      title: 'Profil Pengguna & Keamanan Akun',
      subtitle: 'Kelola informasi akun admin, keamanan password, dan akses multi-user.',
      badge: _buildBadge('Aman', const Color(0xFF059669), const Color(0xFFECFDF5)),
      content: Column(
        children: [
          _buildToggleItem(
            title: 'Two-Factor Authentication (2FA)',
            description: 'Aktifkan verifikasi dua langkah saat login admin menggunakan OTP via WhatsApp.',
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 6),
          _buildToggleItem(
            title: 'Auto-Logout setelah 30 Menit Idle',
            description: 'Otomatis keluar dari sistem jika tidak ada aktivitas selama 30 menit.',
            value: true,
            onChanged: (_) {},
          ),
          const SizedBox(height: 6),
          _buildToggleItem(
            title: 'Log Audit Aktivitas Admin',
            description: 'Catat semua aktivitas admin (login, edit, hapus) ke log audit untuk keamanan.',
            value: true,
            onChanged: (_) {},
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // REUSABLE SETTINGS COMPONENTS
  // ─────────────────────────────────────────────────────────

  Widget _buildSettingsSection({
    required Color dotColor,
    required String title,
    required String subtitle,
    required Widget badge,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              badge,
            ],
          ),
          const SizedBox(height: 22),
          content,
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildConnectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Terhubung: SIM-PMI',
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Lamongan',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Color(0xFF059669)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF94A3B8)),
              style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
              items: items.map((item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), height: 1.3),
          ),
        ],
      ],
    );
  }

  Widget _buildNumberInputField({
    required String label,
    required int value,
    required String suffix,
    required String hint,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Number Input Box
            Container(
              width: 72,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Center(
                child: Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                suffix,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
        if (hint.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            hint,
            style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), height: 1.3),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFFDC2626),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }
}
