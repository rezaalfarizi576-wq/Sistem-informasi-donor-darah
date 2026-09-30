import 'package:flutter/material.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_router.dart';
import '../widgets/admin_sidebar.dart';
import 'dashboard_screen.dart';
import 'verification_screen.dart';
import 'donor_management_screen.dart';
import 'settings_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  final _authRepo = AuthRepository();

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    VerificationScreen(),
    DonorManagementScreen(),
    SettingsScreen(),
  ];

  void _onItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleLogout() async {
    await _authRepo.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRouter.loginRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: _onItemSelected,
            onLogout: _handleLogout,
          ),
          // Main Content Area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _screens[_selectedIndex],
            ),
          ),
        ],
      ),
    );
  }
}
