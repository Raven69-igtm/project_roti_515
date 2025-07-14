import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../providers/admin_stats_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class AnimatedSalesChart extends StatefulWidget {
  const AnimatedSalesChart({super.key});

  @override
  State<AnimatedSalesChart> createState() => _AnimatedSalesChartState();
}

class _AnimatedSalesChartState extends State<AnimatedSalesChart> {
  String _formatMonth(int month) {
    final months = ["Jan", "Feb", "Mar", "Apr", "Mei", "Jun", "Jul", "Agu", "Sep", "Okt", "Nov", "Des"];
    return months[month - 1];
  }

  String _formatFullDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day} ${_formatMonth(dt.month)} 2026";
    } catch (_) {
      return dateStr;
    }
  }

  String _formatShortDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day} ${_formatMonth(dt.month)}";
    } catch (_) {
      return dateStr;
    }
  }

  String _formatRupiah(dynamic value) {
    final num amount = (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    final int intAmount = amount.toInt();
    final String s = intAmount.toString();
    final buf = StringBuffer('Rp ');
    final mod = s.length % 3;
    buf.write(s.substring(0, mod == 0 ? 3 : mod));
    for (int i = (mod == 0 ? 3 : mod); i < s.length; i += 3) {
      buf.write('.');
      buf.write(s.substring(i, i + 3));
    }
    return buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<AdminStatsProvider>(context);
    final rawDailyStats = statsProvider.stats['daily_stats'] as List<dynamic>;
    
    final List<FlSpot> spots = [];
    final List<String> days = [];
    double highestRevenue = 0;

    if (rawDailyStats.isEmpty) {
      for (int i = 0; i < 7; i++) {
        spots.add(FlSpot(i.toDouble(), 0));
        days.add("-");
      }
    } else {
      // Find highest revenue for scaling
      for (var item in rawDailyStats) {
        final double r = (item['revenue'] as num).toDouble();
        if (r > highestRevenue) highestRevenue = r;
      }

      for (int i = 0; i < rawDailyStats.length; i++) {
        final double rev = (rawDailyStats[i]['revenue'] as num).toDouble();
        spots.add(FlSpot(i.toDouble(), rev)); 
        days.add(_formatShortDate(rawDailyStats[i]['date']));
      }
    }

    // Set maxY to highest + 25% cushion, minimum 1000 for empty state
    final chartMaxY = (highestRevenue > 0 ? highestRevenue * 1.25 : 1000.0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, statsProvider),
          const SizedBox(height: 32),
          SizedBox(
            height: 220, // Increased height for better visibility
            width: double.infinity,
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse, PointerDeviceKind.trackpad},
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                reverse: true,
                child: SizedBox(
                  // Dynamic width based on days, but at least full width
                  width: (days.length * 50).toDouble().clamp(MediaQuery.of(context).size.width - 80, 2000),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 1200),
                    curve: Curves.easeOutQuart,
                    builder: (context, animValue, child) {
                      final animatedSpots = spots.map((spot) => FlSpot(spot.x, spot.y * animValue)).toList();
                      return LineChart(
                        LineChartData(
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              getTooltipColor: (_) => context.colors.primaryOrange,
                              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                                final rawDate = rawDailyStats.isNotEmpty ? rawDailyStats[spot.x.toInt()]['date'] : "-";
                                return LineTooltipItem(
                                  '${_formatRupiah(spot.y)}\n',
                                  GoogleFonts.plusJakartaSans(
                                    color: Colors.white, 
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _formatFullDate(rawDate), 
                                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.normal)
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: chartMaxY > 0 ? chartMaxY / 4 : 250,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: context.colors.textHint.withOpacity(0.05),
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 3, 
                                getTitlesWidget: (value, meta) {
                                  final int index = value.toInt();
                                  if (index >= 0 && index < days.length) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 12.0),
                                      child: Text(
                                        days[index],
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 10, 
                                          color: context.colors.textHint, 
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: animatedSpots,
                              isCurved: true,
                              curveSmoothness: 0.35,
                              color: context.colors.primaryOrange,
                              barWidth: 4,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  // Only show dots for significant points or at the end
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: Colors.white,
                                    strokeWidth: 3,
                                    strokeColor: context.colors.primaryOrange,
                                  );
                                },
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    context.colors.primaryOrange.withOpacity(0.2),
                                    context.colors.primaryOrange.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          minX: 0,
                          maxX: (days.length - 1).toDouble().clamp(0, double.infinity),
                          minY: 0,
                          maxY: chartMaxY,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AdminStatsProvider statsProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Grafik Penjualan Harian 2026", style: TextStyle(fontSize: 12, color: context.colors.textGrey)),
            Text(
              _formatRupiah(statsProvider.stats['total_sales'] ?? 0),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.textDark),
            ),
          ],
        ),
        _buildGrowthBadge(context, statsProvider.stats['sales_growth'] ?? "0%"),
      ],
    );
  }

  Widget _buildGrowthBadge(BuildContext context, String growth) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: context.colors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(growth, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.colors.success)),
    );
  }
}
