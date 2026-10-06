import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_router.dart';
import 'admin_verification_screen.dart';
import 'admin_relawan_screen.dart';
import 'admin_faskes_screen.dart';
import 'admin_laporan_screen.dart';
import 'admin_pengaturan_screen.dart';
import 'dashboard_screen.dart';

/// Sidebar navigation item model
class _SidebarItem {
  final IconData icon;
  final String label;
  final String? badgeText;
  final Color? badgeColor;
  final bool hasDotIndicator;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.badgeText,
    this.badgeColor,
    this.hasDotIndicator = false,
  });
}

class AdminShellScreen extends StatefulWidget {
  final int initialIndex;

  const AdminShellScreen({super.key, this.initialIndex = 0});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late int _selectedIndex;
  final _authRepo = AuthRepository();

  // Sidebar navigation items matching mockup
  final List<_SidebarItem> _menuItems = const [
    _SidebarItem(
      icon: Icons.dashboard_customize_rounded,
      label: 'Dashboard',
      hasDotIndicator: true,
    ),
    _SidebarItem(
      icon: Icons.description_outlined,
      label: 'Permintaan',
      badgeText: '4',
      badgeColor: Color(0xFFEF4444),
    ),
    _SidebarItem(
      icon: Icons.groups_2_outlined,
      label: 'Relawan',
      badgeText: '1.482',
      badgeColor: Color(0xFF059669),
    ),
    _SidebarItem(
      icon: Icons.local_hospital_outlined,
      label: 'Faskes',
      hasDotIndicator: true,
    ),
    _SidebarItem(
      icon: Icons.bar_chart_rounded,
      label: 'Laporan',
      hasDotIndicator: true,
    ),
    _SidebarItem(
      icon: Icons.settings_outlined,
      label: 'Pengaturan',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101423),
      body: Column(
        children: [
          // ─── TOP WEB DESKTOP COMMAND CENTER BREADCRUMB / BROWSER BAR ───
          _buildTopWindowHeader(),

          // ─── MAIN BODY (SIDEBAR + CONTENT) ───
          Expanded(
            child: Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: _buildContentForIndex(_selectedIndex),
                ),
              ],
            ),
          ),

          // ─── BOTTOM COMMAND CENTER FOOTER STATUS BAR ───
          _buildBottomStatusBar(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // TOP WINDOW BROWSER HEADER
  // ─────────────────────────────────────────────────────────
  Widget _buildTopWindowHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Window action dots (Red, Yellow, Green)
          Row(
            children: [
              _windowDot(const Color(0xFFEF4444)),
              const SizedBox(width: 7),
              _windowDot(const Color(0xFFF59E0B)),
              const SizedBox(width: 7),
              _windowDot(const Color(0xFF10B981)),
            ],
          ),
          const SizedBox(width: 20),

          // Mock Address Bar
          Expanded(
            child: Center(
              child: Container(
                height: 30,
                constraints: const BoxConstraints(maxWidth: 580),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 8),
                    Text(
                      _selectedIndex == 5
                          ? 'tanggap-donor.lamongan.go.id/admin/pengaturan'
                          : _selectedIndex == 4
                              ? 'tanggap-donor.lamongan.go.id/admin/laporan'
                              : _selectedIndex == 3
                                  ? 'tanggap-donor.lamongan.go.id/admin/faskes'
                                  : _selectedIndex == 2
                                      ? 'tanggap-donor.lamongan.go.id/admin/relawan'
                                      : _selectedIndex == 1
                                          ? 'tanggap-donor.lamongan.go.id/admin/permintaan'
                                          : 'tanggap-donor.lamongan.go.id/admin/beranda-posko',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF334155),
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Status tags (LIVE GIS & v2.4-prod)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_selectedIndex != 2 && _selectedIndex != 3 && _selectedIndex != 4) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'LIVE GIS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'v2.4-prod',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _windowDot(Color color) {
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  // ─────────────────────────────────────────────────────────
  // SIDEBAR
  // ─────────────────────────────────────────────────────────
  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        color: Color(0xFF161A29),
        border: Border(right: BorderSide(color: Color(0xFF22283A))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // ─── LOGO ───
          _buildLogo(),
          const SizedBox(height: 28),

          // ─── MENU ITEMS ───
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItem(index);
              },
            ),
          ),

          // ─── USER PROFILE BOTTOM CARD ───
          _buildUserInfo(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // Red Logo Badge with blood drop
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFDC2626),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.bloodtype_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TANGGAP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'PMI Kab. Lamongan',
                style: TextStyle(
                  color: Color(0xFFF87171),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(int index) {
    final item = _menuItems[index];
    final isSelected = _selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            setState(() => _selectedIndex = index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF4C1D24) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: const Color(0xFFEF4444).withOpacity(0.4), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? const Color(0xFFFCA5A5) : const Color(0xFF94A3B8),
                  size: 19,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (item.hasDotIndicator && isSelected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  )
                else if (item.badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: item.badgeColor ?? const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.badgeText!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2337),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF282F48)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: Color(0xFFDC2626),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Posko PMI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Markas Kab. Lamongan',
                    style: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.logout_rounded,
                color: Color(0xFF94A3B8),
                size: 17,
              ),
              onPressed: () async {
                await _authRepo.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, AppRouter.loginRoute);
                }
              },
              tooltip: 'Keluar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // BOTTOM STATUS BAR FOOTER
  // ─────────────────────────────────────────────────────────
  Widget _buildBottomStatusBar() {
    return Container(
      width: double.infinity,
      height: 30,
      color: const Color(0xFF0F1322),
      child: Center(
        child: Text(
          _selectedIndex == 5
              ? 'SCREEN H — ADMIN PMI DASHBOARD PENGATURAN & KONFIGURASI SISTEM • SISTEM TANGGAP DONOR KABUPATEN LAMONGAN'
              : _selectedIndex == 4
                  ? 'SCREEN G — ADMIN PMI DASHBOARD LAPORAN & ANALITIK DISTRIBUSI • SISTEM TANGGAP DONOR KABUPATEN LAMONGAN'
                  : _selectedIndex == 3
                      ? 'SCREEN F — ADMIN PMI DASHBOARD MANAJEMEN FASKES & STOK DARAH • SISTEM TANGGAP DONOR KABUPATEN LAMONGAN'
                      : _selectedIndex == 2
                          ? 'SCREEN E — ADMIN PMI DASHBOARD • SISTEM TANGGAP DONOR KABUPATEN LAMONGAN'
                          : 'ADMIN PMI DASHBOARD — BERANDA UTAMA & KENDALI POSKO • SISTEM TANGGAP DONOR KABUPATEN LAMONGAN',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // CONTENT SWITCHER
  // ─────────────────────────────────────────────────────────
  Widget _buildContentForIndex(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardScreen();
      case 1:
        return const AdminVerificationScreen();
      case 2:
        return const AdminRelawanScreen();
      case 3:
        return const AdminFaskesScreen();
      case 4:
        return const AdminLaporanScreen();
      case 5:
        return const AdminPengaturanScreen();
      default:
        return const AdminDashboardScreen();
    }
  }
}

