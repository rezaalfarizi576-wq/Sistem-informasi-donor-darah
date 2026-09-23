import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_router.dart';
import 'admin_verification_screen.dart';
import 'dashboard_screen.dart';

/// Sidebar navigation item model
class _SidebarItem {
  final IconData icon;
  final String label;
  final int? badgeCount;

  const _SidebarItem({
    required this.icon,
    required this.label,
    this.badgeCount,
  });
}

class AdminShellScreen extends StatefulWidget {
  final int initialIndex;

  const AdminShellScreen({super.key, this.initialIndex = 1});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  late int _selectedIndex;
  final _authRepo = AuthRepository();

  // Sidebar navigation items
  final List<_SidebarItem> _menuItems = const [
    _SidebarItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _SidebarItem(icon: Icons.description_rounded, label: 'Permintaan', badgeCount: 4),
    _SidebarItem(icon: Icons.volunteer_activism_rounded, label: 'Relawan'),
    _SidebarItem(icon: Icons.local_hospital_rounded, label: 'Faskes'),
    _SidebarItem(icon: Icons.bar_chart_rounded, label: 'Laporan'),
    _SidebarItem(icon: Icons.settings_rounded, label: 'Pengaturan'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Row(
        children: [
          // ─── SIDEBAR ─────────────────────────────────
          _buildSidebar(),
          // ─── CONTENT AREA ────────────────────────────
          Expanded(
            child: _buildContentForIndex(_selectedIndex),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1D2E),
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // ─── LOGO ──────────────────────────────
          _buildLogo(),
          const SizedBox(height: 36),
          // ─── MENU ITEMS ────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItem(index);
              },
            ),
          ),
          // ─── USER INFO ─────────────────────────
          _buildUserInfo(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Logo icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFFF7043)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.bloodtype_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TANGGAP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'PMI Lamongan',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _selectedIndex = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2D8CFF).withOpacity(0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: const Color(0xFF2D8CFF).withOpacity(0.3), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  color: isSelected ? const Color(0xFF5CA8FF) : Colors.white.withOpacity(0.5),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (item.badgeCount != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${item.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF4CAF50),
              child: const Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin PMI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Lamongan',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            // Logout button
            IconButton(
              icon: Icon(
                Icons.logout_rounded,
                color: Colors.white.withOpacity(0.4),
                size: 18,
              ),
              onPressed: () async {
                await _authRepo.logout();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, AppRouter.loginRoute);
                }
              },
              tooltip: 'Logout',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentForIndex(int index) {
    switch (index) {
      case 0:
        return const AdminDashboardScreen();
      case 1:
        // Permintaan / Antrian Verifikasi
        return const AdminVerificationScreen();
      case 2:
        return _buildPlaceholderPage('Relawan', Icons.volunteer_activism_rounded);
      case 3:
        return _buildPlaceholderPage('Faskes', Icons.local_hospital_rounded);
      case 4:
        return _buildPlaceholderPage('Laporan', Icons.bar_chart_rounded);
      case 5:
        return _buildPlaceholderPage('Pengaturan', Icons.settings_rounded);
      default:
        return const AdminVerificationScreen();
    }
  }

  Widget _buildPlaceholderPage(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Halaman ini sedang dalam pengembangan',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
