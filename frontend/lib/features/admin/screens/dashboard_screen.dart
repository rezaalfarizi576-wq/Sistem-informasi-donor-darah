import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../routes/app_router.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _apiClient = ApiClient();
  final _authRepo = AuthRepository();
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiClient.get('/admin/stats');
      if (mounted) {
        setState(() {
          _stats = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin PMI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authRepo.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, AppRouter.loginRoute);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ringkasan Sistem PMI Lamongan',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          'Total Pendonor',
                          _stats?['total_donors']?.toString() ?? '0',
                          Icons.people,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Permohonan Aktif',
                          _stats?['active_blood_requests']?.toString() ?? '0',
                          Icons.emergency,
                          Colors.orange,
                        ),
                        _buildStatCard(
                          'Pemohon Terdaftar',
                          _stats?['total_requesters']?.toString() ?? '0',
                          Icons.personal_injury,
                          Colors.blue,
                        ),
                        _buildStatCard(
                          'Lokasi Donor Aktif',
                          _stats?['active_donor_locations']?.toString() ?? '0',
                          Icons.location_city,
                          Colors.green,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Menu Manajemen Cepat',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.bloodtype, color: Colors.red),
                            title: const Text('Kelola Permohonan Darah'),
                            subtitle: const Text('Lihat semua permohonan masuk & verifikasi'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(context, AppRouter.requestStatusRoute);
                            },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: const Icon(Icons.notifications_active, color: Colors.blue),
                            title: const Text('Daftar Kebutuhan Darah Aktif'),
                            subtitle: const Text('Lihat antrian permohonan yang butuh pendonor'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pushNamed(context, AppRouter.donorNotificationRoute);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
