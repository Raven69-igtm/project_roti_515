import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../auth/providers/auth_provider.dart';
import '../providers/order_admin_provider.dart';
import '../../profile/screens/admin_profile_screen.dart';
import '../../product_admin/providers/admin_product_provider.dart';
import '../../dashboard/screens/admin_notification_screen.dart';
import 'package:roti_515/core/theme/theme_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import 'package:roti_515/core/network/api_service.dart';

// Mengimpor sub-widget modular dari folder widgets
import '../widgets/order_tab_bar.dart';
import '../widgets/order_list_content.dart';

// ============================================================
// HALAMAN UTAMA ORDER ADMIN (PORTAL KELOLA PESANAN)
// ============================================================
class OrderAdminScreen extends StatefulWidget {
  const OrderAdminScreen({super.key});

  @override
  State<OrderAdminScreen> createState() => _OrderAdminScreenState();
}

class _OrderAdminScreenState extends State<OrderAdminScreen> {
  @override
  void initState() {
    super.initState();
    // Menjalankan polling otomatis setelah UI awal selesai dirender
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final token = context.read<AuthProvider>().token;
        context.read<OrderAdminProvider>().startPolling(token); // Mulai sinkronisasi realtime
      }
    });
  }

  @override
  void dispose() {
    // Menghentikan koneksi polling ketika admin berpindah halaman
    context.read<OrderAdminProvider>().stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(), // Memanggil widget App Bar kustom
      body: Column(
        children: [
          const OrderTabBar(), // Menampilkan bar tab kategori status
          const Expanded(child: OrderListContent()), // Menampilkan daftar pesanan aktif
        ],
      ),
    );
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
        // Widget untuk beralih mode terang/gelap (Dark/Light Mode)
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => IconButton(
            icon: Icon(
              theme.isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: context.colors.textDark,
            ),
            onPressed: () {
              theme.toggleTheme(!theme.isDarkMode);
            },
          ),
        ),
        // Tombol foto profil admin yang mengarah ke pengaturan profil
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
                final fullImageUrl = ApiService.getDisplayImage(photoUrl);
                
                Widget imageChild;
                if (fullImageUrl.isEmpty) {
                  imageChild = Icon(
                    Icons.account_circle_outlined,
                    color: context.colors.primaryOrange,
                    size: 22,
                  );
                } else if (fullImageUrl.startsWith('data:image')) {
                  try {
                    final base64Str = fullImageUrl.split(',').last;
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
                    fullImageUrl,
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
        ),
      ],
    );
  }
}
