import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_top_bar.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  int _selectedDonorIndex = 0;

  final List<Map<String, dynamic>> _pendingDonors = [
    {
      'name': 'Rizky Firmansyah',
      'nik': '3524012345670001',
      'email': 'rizky.f@email.com',
      'phone': '081234567890',
      'bloodType': 'A+',
      'address': 'Jl. Lamongan Raya No. 45, Lamongan',
      'submittedAt': '20 Sep 2026, 09:30',
      'status': 'pending',
    },
    {
      'name': 'Anisa Putri',
      'nik': '3524019876540002',
      'email': 'anisa.p@email.com',
      'phone': '082198765432',
      'bloodType': 'O+',
      'address': 'Jl. Veteran No. 12, Babat, Lamongan',
      'submittedAt': '19 Sep 2026, 14:15',
      'status': 'pending',
    },
    {
      'name': 'Dimas Adi Pratama',
      'nik': '3524015678900003',
      'email': 'dimas.adi@email.com',
      'phone': '085312345678',
      'bloodType': 'B-',
      'address': 'Jl. KH. Ahmad Dahlan No. 8, Paciran, Lamongan',
      'submittedAt': '18 Sep 2026, 11:45',
      'status': 'pending',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminTopBar(
          title: 'Verifikasi Pendonor',
          subtitle: 'VERIFIKASI',
        ),
        Expanded(
          child: Row(
            children: [
              // Left: Donor List
              Container(
                width: 340,
                decoration: const BoxDecoration(
                  color: AppTheme.cardWhite,
                  border: Border(
                    right: BorderSide(color: AppTheme.cardBorder, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    // Search
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari pendonor...',
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
                    // Pending count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Menunggu Verifikasi',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_pendingDonors.length}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Donor List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _pendingDonors.length,
                        itemBuilder: (context, index) {
                          final donor = _pendingDonors[index];
                          final isSelected = index == _selectedDonorIndex;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Material(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => setState(() => _selectedDonorIndex = index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppTheme.primaryRed.withValues(alpha: 0.05)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: isSelected
                                        ? Border.all(color: AppTheme.primaryRed.withValues(alpha: 0.2))
                                        : null,
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                                        child: Text(
                                          donor['name'][0],
                                          style: GoogleFonts.poppins(
                                            color: AppTheme.primaryRed,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
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
                                            const SizedBox(height: 2),
                                            Text(
                                              donor['submittedAt'],
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentOrange.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'Baru',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.accentOrange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              // Right: Detail View
              Expanded(
                child: _buildDetailView(_pendingDonors[_selectedDonorIndex]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailView(Map<String, dynamic> donor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
                child: Text(
                  donor['name'][0],
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    color: AppTheme.primaryRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      donor['name'],
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Diajukan: ${donor['submittedAt']}',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '⏳ Menunggu Verifikasi',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.accentOrange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Data Section
          _buildSectionTitle('Data Pribadi'),
          const SizedBox(height: 16),
          _buildInfoGrid([
            {'label': 'Nama Lengkap', 'value': donor['name']},
            {'label': 'NIK', 'value': donor['nik']},
            {'label': 'Email', 'value': donor['email']},
            {'label': 'No. Telepon', 'value': donor['phone']},
            {'label': 'Golongan Darah', 'value': donor['bloodType']},
            {'label': 'Alamat', 'value': donor['address']},
          ]),
          const SizedBox(height: 32),

          // KTP Photo placeholder
          _buildSectionTitle('Foto KTP / Identitas'),
          const SizedBox(height: 16),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder, style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.credit_card, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text(
                  'Foto KTP Pendonor',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Klik untuk memperbesar',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textMuted.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showConfirmDialog('Terima', 'Apakah Anda yakin ingin menerima pendonor ini?', true);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 20),
                    label: Text('Terima & Verifikasi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentTeal,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showConfirmDialog('Tolak', 'Apakah Anda yakin ingin menolak pendonor ini?', false);
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 20),
                    label: Text('Tolak Verifikasi', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.statusDanger,
                      side: const BorderSide(color: AppTheme.statusDanger),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoGrid(List<Map<String, String>> items) {
    return Wrap(
      spacing: 24,
      runSpacing: 20,
      children: items.map((item) {
        return SizedBox(
          width: 280,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item['label']!,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['value']!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showConfirmDialog(String action, String message, bool isApprove) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi $action',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isApprove ? 'Pendonor berhasil diverifikasi!' : 'Pendonor ditolak.',
                  ),
                  backgroundColor: isApprove ? AppTheme.statusSuccess : AppTheme.statusDanger,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppTheme.accentTeal : AppTheme.statusDanger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(action, style: GoogleFonts.poppins(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
