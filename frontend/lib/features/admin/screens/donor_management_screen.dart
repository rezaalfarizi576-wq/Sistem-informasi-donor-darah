import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/stat_card.dart';

class DonorManagementScreen extends StatefulWidget {
  const DonorManagementScreen({super.key});

  @override
  State<DonorManagementScreen> createState() => _DonorManagementScreenState();
}

class _DonorManagementScreenState extends State<DonorManagementScreen> {
  int? _selectedDonorIndex;
  String _searchQuery = '';
  String _filterStatus = 'Semua';

  final List<Map<String, dynamic>> _donors = [
    {
      'name': 'Budi Santoso',
      'nik': '3524011234560001',
      'bloodType': 'O+',
      'phone': '081234567890',
      'address': 'Jl. Raya Lamongan No. 10',
      'totalDonations': 8,
      'lastDonation': '12 Mar 2026',
      'status': 'Aktif',
      'statusPMI': 'Relawan A',
      'verified': true,
    },
    {
      'name': 'Siti Aminah',
      'nik': '3524019876540002',
      'bloodType': 'A+',
      'phone': '082198765432',
      'address': 'Jl. KH. Hasyim Asyari No. 25, Babat',
      'totalDonations': 12,
      'lastDonation': '5 Jul 2026',
      'status': 'Aktif',
      'statusPMI': 'Relawan B',
      'verified': true,
    },
    {
      'name': 'Ahmad Fauzi',
      'nik': '3524015678900003',
      'bloodType': 'B+',
      'phone': '085312345678',
      'address': 'Jl. Veteran No. 8, Paciran',
      'totalDonations': 3,
      'lastDonation': '20 Jan 2026',
      'status': 'Tidak Aktif',
      'statusPMI': 'Relawan C',
      'verified': true,
    },
    {
      'name': 'Dewi Sartika',
      'nik': '3524011122330004',
      'bloodType': 'AB-',
      'phone': '087812345678',
      'address': 'Jl. Sunan Drajat No. 15, Brondong',
      'totalDonations': 5,
      'lastDonation': '8 Aug 2026',
      'status': 'Aktif',
      'statusPMI': 'Relawan A',
      'verified': true,
    },
    {
      'name': 'Eko Wijaya',
      'nik': '3524014455660005',
      'bloodType': 'O-',
      'phone': '089912345678',
      'address': 'Jl. Basuki Rahmat No. 32, Sukodadi',
      'totalDonations': 1,
      'lastDonation': '15 Sep 2026',
      'status': 'Aktif',
      'statusPMI': 'Baru',
      'verified': false,
    },
  ];

  List<Map<String, dynamic>> get _filteredDonors {
    return _donors.where((d) {
      final matchesSearch = _searchQuery.isEmpty ||
          (d['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _filterStatus == 'Semua' || d['status'] == _filterStatus;
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminTopBar(
          title: 'Manajemen Relawan/Donor',
          subtitle: 'MANAJEMEN DONOR',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat Cards
                _buildStatCards(),
                const SizedBox(height: 28),
                // Main Content
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Donor List
                    Expanded(
                      flex: 3,
                      child: _buildDonorList(),
                    ),
                    const SizedBox(width: 24),
                    // Right: Donor Detail
                    Expanded(
                      flex: 2,
                      child: _selectedDonorIndex != null
                          ? _buildDonorDetail(_filteredDonors[_selectedDonorIndex!])
                          : _buildEmptyDetail(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    return const SizedBox(
      height: 140,
      child: Row(
        children: [
          Expanded(
            child: StatCard(
              label: 'Total Pendonor',
              value: '1,248',
              icon: Icons.people_rounded,
              color: AppTheme.accentBlue,
              trend: '+24',
              isPositiveTrend: true,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Aktif',
              value: '84',
              icon: Icons.verified_rounded,
              color: AppTheme.accentTeal,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Cadangan',
              value: '12',
              icon: Icons.hourglass_bottom_rounded,
              color: AppTheme.accentOrange,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Terverifikasi',
              value: '1,460',
              icon: Icons.task_alt_rounded,
              color: AppTheme.statusSuccess,
              trend: 'Kumulatif',
              isPositiveTrend: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDonorList() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          // Header with search and filter
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Cari nama pendonor...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Filter dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _filterStatus,
                      items: ['Semua', 'Aktif', 'Tidak Aktif']
                          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 13))))
                          .toList(),
                      onChanged: (v) => setState(() => _filterStatus = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          // List
          ..._filteredDonors.asMap().entries.map((entry) {
            final index = entry.key;
            final donor = entry.value;
            final isSelected = _selectedDonorIndex == index;
            final isActive = donor['status'] == 'Aktif';

            return InkWell(
              onTap: () => setState(() => _selectedDonorIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryRed.withValues(alpha: 0.04) : Colors.transparent,
                  border: Border(
                    left: BorderSide(
                      color: isSelected ? AppTheme.primaryRed : Colors.transparent,
                      width: 3,
                    ),
                    bottom: const BorderSide(color: AppTheme.dividerLight),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: isActive
                          ? AppTheme.accentTeal.withValues(alpha: 0.1)
                          : AppTheme.textMuted.withValues(alpha: 0.1),
                      child: Text(
                        donor['name'][0],
                        style: GoogleFonts.poppins(
                          color: isActive ? AppTheme.accentTeal : AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            donor['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          Text(
                            '${donor['bloodType']} • ${donor['totalDonations']}x donor',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.statusSuccess.withValues(alpha: 0.1)
                            : AppTheme.textMuted.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        donor['status'],
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? AppTheme.statusSuccess : AppTheme.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDonorDetail(Map<String, dynamic> donor) {
    final isActive = donor['status'] == 'Aktif';
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
          // Header
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                  child: Text(
                    donor['name'][0],
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      color: AppTheme.primaryRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  donor['name'],
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppTheme.statusSuccess.withValues(alpha: 0.1)
                        : AppTheme.textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    donor['status'],
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppTheme.statusSuccess : AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.dividerLight),
          const SizedBox(height: 16),

          // Stats Row
          Row(
            children: [
              _buildMiniStat('Total Donor', '${donor['totalDonations']}x', AppTheme.primaryRed),
              const SizedBox(width: 12),
              _buildMiniStat('Gol. Darah', donor['bloodType'], AppTheme.accentBlue),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniStat('Terakhir', donor['lastDonation'], AppTheme.accentTeal),
              const SizedBox(width: 12),
              _buildMiniStat('Status PMI', donor['statusPMI'], AppTheme.accentPurple),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppTheme.dividerLight),
          const SizedBox(height: 16),

          // Info
          _buildInfoRow(Icons.credit_card, 'NIK', donor['nik']),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'Telepon', donor['phone']),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.location_on, 'Alamat', donor['address']),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 16),
                    label: Text('Edit', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      isActive ? Icons.block : Icons.check_circle,
                      size: 16,
                    ),
                    label: Text(
                      isActive ? 'Nonaktifkan' : 'Aktifkan',
                      style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isActive ? AppTheme.statusDanger : AppTheme.statusSuccess,
                      side: BorderSide(color: isActive ? AppTheme.statusDanger : AppTheme.statusSuccess),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetail() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_search, size: 64, color: AppTheme.textMuted.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          Text(
            'Pilih pendonor untuk melihat detail',
            style: GoogleFonts.poppins(
              color: AppTheme.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.textMuted),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textPrimary),
            ),
          ],
        ),
      ],
    );
  }
}
