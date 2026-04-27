import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import '../providers/order_admin_provider.dart';
import 'order_card.dart';

// Widget kontainer untuk memuat daftar pesanan dan menangani berbagai status (Loading, Error, Empty)
class OrderListContent extends StatelessWidget {
  const OrderListContent({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderAdminProvider>();

    // 1. Tampilan saat data sedang diunduh (Loading)
    if (provider.loadState == OrderLoadState.loading) {
      return Center(
        child: CircularProgressIndicator(color: context.colors.primaryOrange),
      );
    }

    // 2. Tampilan saat terjadi kesalahan koneksi atau otentikasi (Error)
    if (provider.loadState == OrderLoadState.error) {
      final bool isAuthError = provider.errorMessage.contains('login');
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isAuthError ? Icons.lock_outline_rounded : Icons.cloud_off_rounded,
                color: context.colors.primaryOrange,
                size: 56,
              ),
              SizedBox(height: 16),
              Text(
                isAuthError ? 'Sesi Admin Habis' : 'Gagal Memuat Pesanan',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                provider.errorMessage,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: context.colors.textGrey,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 28),
              if (isAuthError)
                GestureDetector(
                  // Mengarahkan kembali ke halaman login jika token tidak valid
                  onTap: () {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/login',
                      (route) => false,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.colors.primaryOrange,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'Login Ulang',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              else
                GestureDetector(
                  // Mencoba memuat ulang data jika terjadi error jaringan
                  onTap: () => provider.fetchOrders(),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    decoration: BoxDecoration(
                      color: context.colors.primaryOrange,
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      'Coba Lagi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final orders = provider.filteredOrders;

    // 3. Tampilan jika tab pesanan kosong (Empty State)
    if (orders.isEmpty) {
      return _buildEmptyState(context, provider.activeTab);
    }

    // 4. Menampilkan daftar pesanan dalam bentuk ListView dengan fitur pull-to-refresh
    return RefreshIndicator(
      color: context.colors.primaryOrange,
      onRefresh: () => provider.fetchOrders(),
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: orders.length,
        separatorBuilder: (context, index) => SizedBox(height: 16),
        itemBuilder: (ctx, i) => OrderCard(order: orders[i]),
      ),
    );
  }

  // Fungsi pembantu untuk menggambar ilustrasi kosong jika pesanan tidak ada
  Widget _buildEmptyState(BuildContext context, int tab) {
    final messages = [
      'Tidak ada pesanan tertunda',
      'Tidak ada pesanan dalam pengolahan',
      'Belum ada pesanan selesai',
      'Tidak ada pesanan yang dibatalkan',
    ];
    final icons = [
      Icons.hourglass_empty_rounded,
      Icons.pending_actions_rounded,
      Icons.check_circle_outline_rounded,
      Icons.cancel_outlined,
    ];

    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[tab], color: context.colors.primaryOrange.withValues(alpha: 0.4), size: 64),
            SizedBox(height: 16),
            Text(
              messages[tab],
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.textGrey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Pesanan baru akan muncul di sini secara otomatis',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: context.colors.textHint,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
