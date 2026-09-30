import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../widgets/admin_top_bar.dart';
import '../widgets/stat_card.dart';
import '../widgets/bar_chart_widget.dart';
import '../widgets/data_table_card.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AdminTopBar(
          title: 'Laporan & Rekapitulasi Darah',
          subtitle: 'DASHBOARD',
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stat Cards Row
                _buildStatCards(),
                const SizedBox(height: 28),
                // Charts & Tables Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Bar Chart
                    Expanded(
                      flex: 3,
                      child: _buildBarChart(),
                    ),
                    const SizedBox(width: 24),
                    // Right: Blood Stock
                    Expanded(
                      flex: 2,
                      child: _buildBloodStockCard(),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                // Recent Requests Table
                _buildRecentRequestsTable(),
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
              label: 'Total Permintaan',
              value: '156',
              icon: Icons.description_rounded,
              color: AppTheme.primaryRed,
              trend: '+12%',
              isPositiveTrend: true,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Terpenuhi',
              value: '84.2%',
              icon: Icons.check_circle_rounded,
              color: AppTheme.accentTeal,
              trend: '+5.4%',
              isPositiveTrend: true,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Pending',
              value: '23',
              icon: Icons.pending_actions_rounded,
              color: AppTheme.accentOrange,
              trend: '-8%',
              isPositiveTrend: true,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: StatCard(
              label: 'Ditolak',
              value: '7',
              icon: Icons.cancel_rounded,
              color: AppTheme.statusDanger,
              trend: '-2',
              isPositiveTrend: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    return const BarChartWidget(
      title: 'Grafik Permintaan Bulanan',
      data: [
        BarChartData(label: 'Jan', values: [45, 38]),
        BarChartData(label: 'Feb', values: [52, 42]),
        BarChartData(label: 'Mar', values: [38, 35]),
        BarChartData(label: 'Apr', values: [65, 55]),
        BarChartData(label: 'Mei', values: [48, 40]),
        BarChartData(label: 'Jun', values: [72, 60]),
        BarChartData(label: 'Jul', values: [55, 48]),
        BarChartData(label: 'Agu', values: [60, 52]),
      ],
    );
  }

  Widget _buildBloodStockCard() {
    final bloodStocks = [
      {'type': 'A+', 'stock': 45, 'color': AppTheme.primaryRed},
      {'type': 'A-', 'stock': 12, 'color': AppTheme.accentOrange},
      {'type': 'B+', 'stock': 38, 'color': AppTheme.accentBlue},
      {'type': 'B-', 'stock': 8, 'color': AppTheme.accentPurple},
      {'type': 'O+', 'stock': 52, 'color': AppTheme.accentTeal},
      {'type': 'O-', 'stock': 15, 'color': AppTheme.statusWarning},
      {'type': 'AB+', 'stock': 22, 'color': AppTheme.statusSuccess},
      {'type': 'AB-', 'stock': 5, 'color': AppTheme.statusDanger},
    ];

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
          Text(
            'Stok Darah Tersedia',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'UDD PMI Lamongan',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 20),
          ...bloodStocks.map((stock) {
            const maxStock = 60;
            final percentage = (stock['stock'] as int) / maxStock;
            final color = stock['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Text(
                        stock['type'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: AppTheme.surfaceLight,
                        color: color,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${stock['stock']}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentRequestsTable() {
    return DataTableCard(
      title: 'Riwayat Permohonan Terbaru',
      columns: const ['PEMOHON', 'GOLONGAN', 'RUMAH SAKIT', 'STATUS', 'TANGGAL'],
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.filter_list, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      rows: [
        _buildRequestRow('Ahmad Fadli', 'A+', 'RSUD Lamongan', 'Terpenuhi', '20 Sep 2026'),
        _buildRequestRow('Siti Nurhaliza', 'O+', 'RS Muhammadiyah', 'Pending', '19 Sep 2026'),
        _buildRequestRow('Budi Santoso', 'B-', 'RSUD Dr. Soegiri', 'Proses', '18 Sep 2026'),
        _buildRequestRow('Dewi Lestari', 'AB+', 'RS Islam Lamongan', 'Terpenuhi', '17 Sep 2026'),
        _buildRequestRow('Eko Prasetyo', 'O-', 'RSUD Lamongan', 'Ditolak', '16 Sep 2026'),
      ],
    );
  }

  List<Widget> _buildRequestRow(String name, String bloodType, String hospital, String status, String date) {
    Color statusColor;
    switch (status) {
      case 'Terpenuhi':
        statusColor = AppTheme.statusSuccess;
        break;
      case 'Pending':
        statusColor = AppTheme.statusWarning;
        break;
      case 'Proses':
        statusColor = AppTheme.statusInfo;
        break;
      case 'Ditolak':
        statusColor = AppTheme.statusDanger;
        break;
      default:
        statusColor = AppTheme.textMuted;
    }

    return [
      Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primaryRed.withValues(alpha: 0.1),
            child: Text(
              name[0],
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryRed,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              name,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.primaryRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          bloodType,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryRed,
          ),
        ),
      ),
      Text(
        hospital,
        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: statusColor,
          ),
        ),
      ),
      Text(
        date,
        style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
      ),
    ];
  }
}
