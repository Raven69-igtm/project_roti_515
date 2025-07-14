import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../../auth/providers/auth_provider.dart';
import '../providers/admin_stats_provider.dart';
import '../widgets/animated_sales_chart.dart';
import '../../profile/screens/admin_profile_screen.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import 'package:roti_515/core/network/api_service.dart';
import '../../product_admin/providers/admin_product_provider.dart';
import '../../orders/providers/order_admin_provider.dart';
import 'monthly_recap_screen.dart';
import 'admin_notification_screen.dart';
import 'all_activities_screen.dart';

// Halaman utama Dashboard Admin yang menampilkan grafik penjualan dan statistik ringkasan
class DashboardAdminScreen extends StatefulWidget {
  const DashboardAdminScreen({super.key});

  @override
  State<DashboardAdminScreen> createState() => _DashboardAdminScreenState();
}

class _DashboardAdminScreenState extends State<DashboardAdminScreen> {
  @override
  void initState() {
    super.initState();
    // Ambil token otentikasi admin untuk memicu request data statistik
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final statsProvider = Provider.of<AdminStatsProvider>(context, listen: false);
    final productProvider = Provider.of<AdminProductProvider>(context, listen: false);
    // Jalankan sinkronisasi data statistik secara berkala (polling) tepat setelah render UI awal
    Future.microtask(() {
      statsProvider.startPolling(auth.token);
      productProvider.fetchProducts(); // Refresh data produk untuk jumlah badge notifikasi
      Provider.of<OrderAdminProvider>(context, listen: false).startPolling(auth.token); // Polling pesanan masuk
      _checkLowStock(); // Cek stok menipis saat pertama kali masuk
    });
  }

  @override
  void dispose() {
    // Pastikan koneksi polling statistik berhenti ketika admin menutup/meninggalkan halaman dashboard
    Provider.of<AdminStatsProvider>(context, listen: false).stopPolling();
    Provider.of<OrderAdminProvider>(context, listen: false).stopPolling();
    super.dispose();
  }

  /// Mengecek produk dengan stok menipis (≤ 15) dan menampilkan pop-up peringatan
  Future<void> _checkLowStock() async {
    try {
      final response = await http.get(Uri.parse(ApiService.foods));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List products = data['data'] ?? [];
        final lowStock = products.where((p) => (p['stock'] ?? 0) <= 15).toList();

        if (lowStock.isNotEmpty && mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: context.colors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Stok Menipis!",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: context.colors.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${lowStock.length} produk memiliki stok ≤ 15 unit:",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: context.colors.textGrey,
                    ),
                  ),
                  SizedBox(height: 12),
                  ...lowStock.map((p) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.bakery_dining_rounded, size: 16, color: context.colors.primaryOrange),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            p['name'] ?? 'Produk',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textDark,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (p['stock'] ?? 0) == 0 ? context.colors.error.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Stok: ${p['stock'] ?? 0}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: (p['stock'] ?? 0) == 0 ? context.colors.error : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primaryOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text("Mengerti", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error checking low stock: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsProvider = Provider.of<AdminStatsProvider>(context);
    final stats = statsProvider.stats;

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(),
      // Tampilkan indikator loading jika data statistik sedang diunduh pertama kali
      body: statsProvider.isLoading 
          ? Center(child: CircularProgressIndicator(color: context.colors.primaryOrange))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- KARTU RINGKASAN STATISTIK (Total Penjualan, Total Pesanan, Pengguna Baru) ---
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

                  // --- GRAFIK ANALISIS PENJUALAN ---
                  _buildSalesChart(),

                  SizedBox(height: 16),

                  // --- TOMBOL REKAP BULANAN ---
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MonthlyRecapScreen()),
                    ),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.colors.primaryOrange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_month_rounded, color: context.colors.primaryOrange, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Lihat Rekap Bulanan",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: context.colors.primaryOrange,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_ios_rounded, color: context.colors.primaryOrange, size: 14),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 32),

                  // --- DAFTAR AKTIVITAS TERKINI ---
                  Text(
                    "Aktivitas Terkini",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18, 
                      fontWeight: FontWeight.bold, 
                      color: context.colors.textDark
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Tampilkan ilustrasi kosong jika belum ada aktivitas
                  if ((stats['activities'] as List).isEmpty)
                    _buildEmptyActivity()
                  else ...[
                    // Map daftar aktivitas terkini yang ditarik dari database backend (maksimal 5)
                    ... (stats['activities'] as List).take(5).map((act) {
                      final createdAt = DateTime.parse(act['created_at']).toLocal();
                      return _buildActivityItem(
                        act['title'],
                        "${_getTimeAgo(createdAt)} • ${act['subtitle']}",
                        act['type'] == 'order' ? Icons.receipt_long_rounded : Icons.person_add_alt_1_rounded,
                      );
                    }).toList(),

                    if ((stats['activities'] as List).length > 5) ...[
                      SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AllActivitiesScreen()),
                          );
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.colors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: context.colors.divider),
                          ),
                          child: Text(
                            "Lihat Semua Aktivitas",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.colors.primaryOrange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  
                  SizedBox(height: 80 + MediaQuery.of(context).padding.bottom),
                ],
              ),
            ),
    );
  }

  // Fungsi pembantu untuk membuat visualisasi riwayat aktivitas kosong
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

  // Fungsi pembantu untuk menghitung waktu lampau secara dinamis (time ago)
  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) return '${difference.inDays} hari lalu';
    if (difference.inHours > 0) return '${difference.inHours} jam lalu';
    if (difference.inMinutes > 0) return '${difference.inMinutes} mnt lalu';
    return 'Baru saja';
  }

  // Fungsi pembantu untuk menggambar header atas Portal Admin
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
        // Lonceng Notifikasi Admin
        Center(
          child: Consumer2<AdminProductProvider, OrderAdminProvider>(
            builder: (context, prodProvider, orderProvider, _) {
              final lowStockCount = prodProvider.allProducts.where((p) {
                final int stock = p['stock'] ?? 0;
                return stock <= 15;
              }).length;
              final pendingCount = orderProvider.pendingCount;
              final alertCount = lowStockCount + pendingCount;

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminNotificationScreen()),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: context.colors.divider),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.notifications_none_rounded,
                        color: alertCount > 0 ? context.colors.primaryOrange : context.colors.textDark,
                        size: 20,
                      ),
                      if (alertCount > 0)
                        Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              "$alertCount",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Pengubah Tema (Tema Terang/Gelap)
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.colors.textDark,
            ),
            onPressed: () => theme.toggleTheme(!theme.isDarkMode),
          ),
        ),
        // Foto profil admin yang mengarah ke edit profil
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(builder: (context) => const AdminProfileScreen()),
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

  // Fungsi pembantu format angka integer mentah menjadi rupiah (contoh: 15000 -> "Rp 15.000")
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

  // Fungsi pembantu untuk membangun widget kartu statistik
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

  // Menggambar Grafik Penjualan
  Widget _buildSalesChart() {
    return const AnimatedSalesChart();
  }

  // Fungsi pembantu untuk membangun item daftar aktivitas
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
