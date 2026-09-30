import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class BarChartWidget extends StatelessWidget {
  final String title;
  final List<BarChartData> data;
  final double maxHeight;

  const BarChartWidget({
    super.key,
    required this.title,
    required this.data,
    this.maxHeight = 160,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<double>(
      0,
      (max, item) => item.values.fold<double>(max, (m, v) => v > m ? v : m),
    );

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
              // Legend
              Row(
                children: [
                  _buildLegendItem('Masuk', AppTheme.primaryRed),
                  const SizedBox(width: 16),
                  _buildLegendItem('Terpenuhi', AppTheme.accentTeal),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: maxHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildBar(
                                item.values[0],
                                maxValue,
                                AppTheme.primaryRed,
                              ),
                              const SizedBox(width: 3),
                              if (item.values.length > 1)
                                _buildBar(
                                  item.values[1],
                                  maxValue,
                                  AppTheme.accentTeal,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.label,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double value, double maxValue, Color color) {
    final heightPercent = maxValue > 0 ? (value / maxValue) : 0.0;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      width: 14,
      height: (maxHeight - 30) * heightPercent,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          topRight: Radius.circular(4),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class BarChartData {
  final String label;
  final List<double> values;

  const BarChartData({required this.label, required this.values});
}
