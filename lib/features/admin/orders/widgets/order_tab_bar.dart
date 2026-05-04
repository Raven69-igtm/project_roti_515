import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import '../providers/order_admin_provider.dart';

// Widget Tab Bar untuk menyaring daftar pesanan berdasarkan status (Tertunda, Pengolahan, Selesai, Dibatalkan)
class OrderTabBar extends StatelessWidget {
  const OrderTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan state pada OrderAdminProvider
    final provider = context.watch<OrderAdminProvider>();

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bgColor,
        border: Border(
          bottom: BorderSide(
            color: context.colors.primaryOrange.withValues(alpha: 0.10),
          ),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // Membangun masing-masing tab item dengan index dan status pesanan
            _buildTabItem(context, 0, 'Tertunda', provider.pendingCount, provider.activeTab),
            _buildTabItem(context, 1, 'Pengolahan', provider.processingCount, provider.activeTab),
            _buildTabItem(context, 2, 'Selesai', provider.completedCount, provider.activeTab),
            _buildTabItem(context, 3, 'Dibatalkan', provider.cancelledCount, provider.activeTab),
          ],
        ),
      ),
    );
  }

  // Fungsi pembantu untuk membuat item tab secara dinamis
  Widget _buildTabItem(BuildContext context,
    int index,
    String label,
    int count,
    int activeTab,
  ) {
    final isActive = index == activeTab;
    final activeColor = context.colors.primaryOrange;
    final inactiveColor = context.colors.textGrey;

    return Expanded(
      child: GestureDetector(
        // Pindah tab saat diketuk
        onTap: () => context.read<OrderAdminProvider>().setTab(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.only(top: 16, bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? activeColor : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isActive ? activeColor : inactiveColor,
                ),
              ),
              // Menampilkan lencana (badge) jumlah antrean jika ada pesanan masuk
              if (count > 0) ...[
                SizedBox(height: 4),
                AnimatedContainer(
                  duration: Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: context.colors.primaryOrange.withValues(alpha: isActive ? 0.20 : 0.10),
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      color: context.colors.primaryOrange,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
