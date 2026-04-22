import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

import '../providers/admin_stats_provider.dart';

/// Halaman Rekap Bulanan — menampilkan ringkasan penjualan per bulan
/// dengan filter kategori produk dan data harian.
class MonthlyRecapScreen extends StatefulWidget {
  const MonthlyRecapScreen({super.key});

  @override
  State<MonthlyRecapScreen> createState() => _MonthlyRecapScreenState();
}

class _MonthlyRecapScreenState extends State<MonthlyRecapScreen> {
  // Daftar nama bulan dalam Bahasa Indonesia
  static const List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];

  static const List<String> _categories = [
    'Semua', 'Roti Manis', 'Roti Tawar', 'Pastry', 'Kue', 'Lainnya',
  ];

  late int _selectedMonth;
  late int _selectedYear;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
    _loadData();
  }

  void _loadData() {
    final provider = Provider.of<AdminStatsProvider>(context, listen: false);
    provider.fetchMonthlyStats(
      _selectedMonth,
      _selectedYear,
      category: _selectedCategory == 'Semua' ? null : _selectedCategory,
    );
  }

  String _formatRupiah(dynamic value) {
    final num amount = (value is num) ? value : num.tryParse(value.toString()) ?? 0;
    final int intAmount = amount.toInt();
    if (intAmount == 0) return 'Rp 0';
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

  String _formatShortDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      return "${dt.day} ${_monthNames[dt.month - 1].substring(0, 3)}";
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        backgroundColor: context.colors.bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: context.colors.textDark),
        title: Text(
          "Rekap Bulanan",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.textDark,
          ),
        ),
      ),
      body: Consumer<AdminStatsProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── FILTER BULAN & KATEGORI ──────────────────────────
                _buildFilters(context),

                SizedBox(height: 20),

                // ── LOADING / KONTEN ─────────────────────────────────
                if (provider.isLoadingMonthly)
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(color: context.colors.primaryOrange),
                    ),
                  )
                else ...[
                  // ── RINGKASAN STATISTIK ─────────────────────────────
                  _buildSummaryCards(context, provider.monthlyStats),

                  SizedBox(height: 20),

                  // ── TABEL DATA HARIAN ───────────────────────────────
                  _buildDailyBreakdown(context, provider.monthlyStats),
                ],

                SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Filter Data",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.colors.textDark,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              // Dropdown Bulan
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: context.colors.bgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonth,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.primaryOrange),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.colors.textDark,
                      ),
                      items: List.generate(12, (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(_monthNames[i]),
                      )),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedMonth = val);
                          _loadData();
                        }
                      },
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              // Dropdown Tahun
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: context.colors.bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: context.colors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    icon: Icon(Icons.keyboard_arrow_down_rounded, color: context.colors.primaryOrange),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.textDark,
                    ),
                    items: [2025, 2026, 2027].map((y) => DropdownMenuItem(
                      value: y,
                      child: Text("$y"),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedYear = val);
                        _loadData();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          // Kategori Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _loadData();
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? context.colors.primaryOrange
                            : context.colors.bgColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? context.colors.primaryOrange
                              : context.colors.divider,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : context.colors.textGrey,
                        ),
                      ),
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

  Widget _buildSummaryCards(BuildContext context, Map<String, dynamic> data) {
    final totalRevenue = data['total_revenue'] ?? 0;
    final totalOrders = data['total_orders'] ?? 0;
    final avgDailyOrders = data['avg_daily_orders'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Ringkasan ${_monthNames[_selectedMonth - 1]} $_selectedYear",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: context.colors.textDark,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard(
              context,
              "Total Pendapatan",
              _formatRupiah(totalRevenue),
              Icons.payments_rounded,
              context.colors.primaryOrange,
            )),
            SizedBox(width: 12),
            Expanded(child: _buildStatCard(
              context,
              "Total Pesanan",
              "$totalOrders",
              Icons.shopping_basket_rounded,
              context.colors.success,
            )),
          ],
        ),
        SizedBox(height: 12),
        _buildStatCard(
          context,
          "Rata-rata Pesanan/Hari",
          "$avgDailyOrders pesanan",
          Icons.bar_chart_rounded,
          Color(0xFF6366F1),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textGrey,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.colors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdown(BuildContext context, Map<String, dynamic> data) {
    final dailyStats = (data['daily_stats'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Data Harian",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.colors.textDark,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.colors.primaryOrange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${dailyStats.length} hari",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.primaryOrange,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),

        if (dailyStats.isEmpty)
          Container(
            padding: EdgeInsets.all(32),
            width: double.infinity,
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.divider),
            ),
            child: Column(
              children: [
                Icon(Icons.calendar_today_rounded, color: context.colors.textHint, size: 40),
                SizedBox(height: 12),
                Text(
                  "Belum ada data untuk bulan ini",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: context.colors.textGrey,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: context.colors.primaryOrange.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text("Tanggal",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textGrey,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text("Pendapatan",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textGrey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text("Pesanan",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.w700, color: context.colors.textGrey,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
                // Rows
                ...dailyStats.asMap().entries.map((entry) {
                  final d = entry.value;
                  final isLast = entry.key == dailyStats.length - 1;
                  return Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      border: isLast ? null : Border(bottom: BorderSide(color: context.colors.divider.withValues(alpha: 0.5))),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatShortDate(d['date'] ?? ''),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w500, color: context.colors.textDark,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _formatRupiah(d['revenue'] ?? 0),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.primaryOrange,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${d['orders'] ?? 0}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, fontWeight: FontWeight.w600, color: context.colors.textDark,
                            ),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}
