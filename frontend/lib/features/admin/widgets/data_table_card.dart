import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class DataTableCard extends StatelessWidget {
  final String title;
  final List<String> columns;
  final List<List<Widget>> rows;
  final String? searchHint;
  final VoidCallback? onSearchChanged;
  final Widget? trailing;

  const DataTableCard({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    this.searchHint,
    this.onSearchChanged,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),
          // Column Headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppTheme.surfaceLight,
            child: Row(
              children: columns.map((col) {
                return Expanded(
                  child: Text(
                    col,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Rows
          ...rows.map((row) {
            final index = rows.indexOf(row);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: index.isEven ? Colors.white : AppTheme.surfaceLight.withValues(alpha: 0.5),
                border: const Border(
                  bottom: BorderSide(color: AppTheme.dividerLight, width: 1),
                ),
              ),
              child: Row(
                children: row.map((cell) {
                  return Expanded(child: cell);
                }).toList(),
              ),
            );
          }),
          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Menampilkan ${rows.length} data',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                Row(
                  children: [
                    _buildPageButton('‹', false),
                    _buildPageButton('1', true),
                    _buildPageButton('2', false),
                    _buildPageButton('3', false),
                    _buildPageButton('›', false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageButton(String label, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primaryRed : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: isActive ? null : Border.all(color: AppTheme.cardBorder),
      ),
      child: Center(
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
