Laporan Fitur 2 (PB-03 - Dashboard Admin)

Dokumen ini disusun tanpa simbol markdown heading (seperti #, ##) agar Anda bisa langsung menyalin dan menempelkannya (copy-paste) ke Microsoft Word atau Google Docs dengan rapi.

========================================================================

b) Fitur 2: Dashboard Admin (Halaman Utama Admin untuk Memantau Ringkasan Data Penjualan)

1. Deskripsi Fitur
Fitur Dashboard Admin bertindak sebagai pusat pemantauan aktivitas bisnis bagi admin aplikasi Roti 515. Dashboard ini memvisualisasikan ringkasan data vital seperti total penjualan (dalam format Rupiah), total jumlah pesanan yang masuk, serta jumlah pertumbuhan pengguna baru. Selain itu, dashboard ini menampilkan grafik penjualan interaktif serta daftar aktivitas transaksi atau pendaftaran akun terkini.

2. Implementasi Teknis & Alur Kerja
* Polling Otomatis (Real-time Simulation): Menggunakan Timer.periodic di dalam AdminStatsProvider untuk menyinkronkan data statistik dari API server setiap 30 detik secara berkala agar dashboard selalu menampilkan data terkini.
* Manajemen Tema (Dark Mode): Terintegrasi dengan ThemeProvider untuk mendukung transisi tampilan gelap dan terang yang nyaman di mata admin.
* Formatting Data Penjualan: Memformat angka desimal/bulat dari database menjadi representasi mata uang Rupiah secara langsung di sisi frontend.

3. Kode Sumber Lengkap (Full Source Code)

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../auth/providers/auth_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/animated_sales_chart.dart';
import '../../profile/screens/admin_profile_screen.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import 'package:roti_515/core/network/api_service.dart';

class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final statsProvider = Provider.of<AdminStatsProvider>(context, listen: false);
    Future.microtask(() => statsProvider.startPolling(auth.token));
  }

  @override
  void dispose() {
    // Memastikan polling berhenti saat admin meninggalkan dashboard
    Provider.of<AdminStatsProvider>(context, listen: false).stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<AdminStatsProvider>(context);
    final stats = statsProvider.stats;

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(),
      body: statsProvider.isLoading 
          ? Center(child: CircularProgressIndicator(color: context.colors.primaryOrange))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- STATS ROW ---
                  Row(
                    children: [
                      Expanded(child: _buildStatCard("Total Penjualan", _formatRupiah(stats['total_sales']), stats['sales_growth'], Icons.payments_rounded)),
                      SizedBox(width: 12),
                      Expanded(child: _buildStatCard("Total Pesanan", "${stats['total_orders']}", stats['orders_growth'], Icons.shopping_basket_rounded)),
                    ],
                  ),
                  SizedBox(height: 16),
                  _buildStatCard("Pengguna Baru", "${stats['total_users']} orang", stats['users_growth'], Icons.person_add_rounded, isFullWidth: true),

            SizedBox(height: 24),

            // --- SALES CHART ---
            _buildSalesChart(),

            SizedBox(height: 32),

            // --- RECENT ACTIVITIES ---
            Text(
              "Aktivitas Terkini",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18, 
                fontWeight: FontWeight.bold, 
                color: context.colors.textDark
              ),
            ),
            SizedBox(height: 16),
            
            if ((stats['activities'] as List).isEmpty)
              _buildEmptyActivity()
            else
              ... (stats['activities'] as List).map((act) {
                final createdAt = DateTime.parse(act['created_at']).toLocal();
                return _buildActivityItem(
                  act['title'],
                  "${_getTimeAgo(createdAt)} • ${act['subtitle']}",
                  act['type'] == 'order' ? Icons.receipt_long_rounded : Icons.person_add_alt_1_rounded,
                );
              }).toList(),
            
            SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
                  ],
                ),
              ),
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded, color: context.colors.textHint, size: 32),
          SizedBox(height: 8),
          Text("Belum ada aktivitas hari ini", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey, fontSize: 13)),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} mnt lalu';
    return 'Baru saja';
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.bgColor,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Transform.scale(
            scale: 1.5,
            child: Image.asset(
              'assets/images/app_icon-removebg-preview.png',
              height: 40,
              fit: BoxFit.contain,
            ),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("roti515", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textDark)),
              Text("Portal Admin", style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.primaryOrange)),
            ],
          ),
        ],
      ),
      actions: [
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.colors.textDark,
            ),
            onPressed: () => theme.toggleTheme(!theme.isDarkMode),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => AdminProfileScreen()),
              );
            },
            child: Consumer<AuthProvider>(
              builder: (context, auth, _) {
                final photoUrl = auth.photoUrl;
                final resolvedUrl = ApiService.getDisplayImage(photoUrl);

                Widget imageChild;
                if (resolvedUrl.isEmpty) {
                  imageChild = Icon(
                    Icons.account_circle_outlined,
                    color: context.colors.primaryOrange,
                    size: 22,
                  );
                } else if (resolvedUrl.startsWith('data:image')) {
                  try {
                    final base64Str = resolvedUrl.split(',').last;
                    final decodedBytes = base64Decode(base64Str);
                    imageChild = Image.memory(
                      decodedBytes,
                      fit: BoxFit.cover,
                      width: 36,
                      height: 36,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_circle_outlined,
                        color: context.colors.primaryOrange,
                        size: 22,
                      ),
                    );
                  } catch (_) {
                    imageChild = Icon(
                      Icons.account_circle_outlined,
                      color: context.colors.primaryOrange,
                      size: 22,
                    );
                  }
                } else {
                  imageChild = Image.network(
                    resolvedUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.account_circle_outlined,
                      color: context.colors.primaryOrange,
                      size: 22,
                    ),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.colors.primaryOrange,
                          ),
                        ),
                      );
                    },
                  );
                }

                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.colors.primaryOrange.withValues(alpha: 0.1),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: imageChild,
                );
              },
            ),
          ),
        )
      ],
    );
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

  Widget _buildStatCard(String title, String value, String percent, IconData icon, {bool isFullWidth = false}) {
    final bool isPositive = !percent.startsWith('-');
    final Color growthColor = isPositive ? context.colors.success : Colors.redAccent;
    final IconData growthIcon = isPositive
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32), 
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: Offset(0, 1))],
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: context.colors.primaryOrange, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title, 
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: context.colors.textGrey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: context.colors.textDark)),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(growthIcon, color: growthColor, size: 14),
              SizedBox(width: 4),
              Flexible(
                child: Text(
                  '$percent vs minggu lalu',
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: growthColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart() {
    return AnimatedSalesChart();
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: context.colors.primaryOrange.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: context.colors.primaryOrange, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: context.colors.textDark)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: context.colors.textGrey)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: context.colors.textHint),
        ],
      ),
    );
  }
}
```

```dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/network/api_service.dart';

class AdminStatsProvider extends ChangeNotifier {
  Map<String, dynamic> _stats = {
    "total_sales": 0,
    "total_orders": 0,
    "total_users": 0,
    "sales_growth": "0%",
    "orders_growth": "0%",
    "users_growth": "0%",
    "daily_stats": <Map<String, dynamic>>[],
    "activities": <Map<String, dynamic>>[],
  };
  bool _isLoading = true;
  Timer? _pollingTimer;

  // Token disimpan agar refreshNow() bisa digunakan tanpa passing token
  String? _cachedToken;

  Map<String, dynamic> get stats => _stats;
  bool get isLoading => _isLoading;

  void startPolling(String? token) {
    _cachedToken = token;
    fetchStats(token);
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(Duration(seconds: 30), (_) {
      fetchStats(token, silent: true);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Refresh statistik secara langsung (dipanggil setelah admin selesaikan order)
  Future<void> refreshNow([String? token]) async {
    if (token != null) {
      _cachedToken = token;
    }
    await fetchStats(_cachedToken, silent: true);
  }

  Future<void> fetchStats(String? token, {bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final response = await http.get(
        Uri.parse(ApiService.adminStats),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String salesGrowth = _parseGrowth(
          data['sales_growth'] ?? data['revenue_growth'] ?? data['income_growth'],
        );
        final String ordersGrowth = _parseGrowth(
          data['orders_growth'] ?? data['order_growth'] ?? data['total_orders_growth'],
        );
        final String usersGrowth = _parseGrowth(
          data['users_growth'] ?? data['user_growth'] ?? data['new_users_growth'],
        );

        final dynamic rawSales = data['revenue']
            ?? data['total_revenue']
            ?? data['total_sales']
            ?? data['sales']
            ?? data['income']
            ?? 0;

        final dynamic rawOrders = data['total_order']
            ?? data['total_orders']
            ?? data['orders_count']
            ?? data['order_count']
            ?? data['completed_orders']
            ?? 0;

        final dynamic rawUsers = data['new_users']
            ?? data['total_users']
            ?? data['user_count']
            ?? data['users_count']
            ?? 0;

        _stats = {
          "total_sales": rawSales,
          "total_orders": rawOrders,
          "total_users": rawUsers,
          "sales_growth": salesGrowth,
          "orders_growth": ordersGrowth,
          "users_growth": usersGrowth,
          "daily_stats": data['daily_stats'] ?? [],
          "activities": data['activities'] ?? [],
        };
      } else {
        debugPrint("Stats API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _parseGrowth(dynamic raw) {
    if (raw == null) return '+0%';
    if (raw is String) {
      if (raw.startsWith('+') || raw.startsWith('-')) return raw;
      return '+$raw';
    }
    if (raw is num) {
      final sign = raw >= 0 ? '+' : '';
      return '$sign${raw.toStringAsFixed(0)}%';
    }
    return '+0%';
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
```
