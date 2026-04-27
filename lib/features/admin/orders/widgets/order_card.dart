import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';
import '../../../../core/utils/premium_snackbar.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../admin/dashboard/providers/admin_stats_provider.dart';
import '../models/order_model.dart';
import '../providers/order_admin_provider.dart';
import 'order_detail_sheet.dart';

// Widget kartu tampilan ringkasan pesanan di sisi Admin
class OrderCard extends StatefulWidget {
  final OrderModel order;
  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> with SingleTickerProviderStateMixin {
  bool _isUpdating = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // Konfigurasi animasi berdenyut (pulse)
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Jalankan animasi pulse berulang jika status pesanan adalah 'Tertunda' (Baru Masuk)
    if (widget.order.isPending) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // Fungsi untuk memproses aksi perubahan status pesanan (Menerima / Menyelesaikan)
  Future<void> _handleAction() async {
    final provider = context.read<OrderAdminProvider>();
    final statsProvider = context.read<AdminStatsProvider>();
    final authToken = context.read<AuthProvider>().token;
    String nextStatus;
    String actionLabel;

    if (widget.order.isPending) {
      nextStatus = 'processing';
      actionLabel = 'pesanan diterima dan diproses';
    } else if (widget.order.isProcessing) {
      nextStatus = 'completed';
      actionLabel = 'pesanan telah diselesaikan';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: context.colors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: context.colors.primaryOrange, size: 24),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Konfirmasi Selesai',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: context.colors.textDark,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah pelanggan sudah mengkonfirmasi pengambilan pesanan #${widget.order.orderId}?',
            style: GoogleFonts.plusJakartaSans(
              color: context.colors.textGrey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Belum Konfirmasi',
                style: GoogleFonts.plusJakartaSans(
                  color: context.colors.textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Sudah Konfirmasi',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

      if (confirmed == null) return; // Batalkan jika dialog ditutup tanpa memilih

      if (confirmed == true) {
        nextStatus = 'completed';
        actionLabel = 'pesanan telah diselesaikan (Sudah Konfirmasi)';
      } else {
        nextStatus = 'completed_unconfirmed';
        actionLabel = 'pesanan telah diselesaikan (Belum Konfirmasi)';
      }
    } else {
      return;
    }

    setState(() => _isUpdating = true);
    final success = await provider.updateOrderStatus(widget.order.id, nextStatus);

    if (!mounted) return;

    if (success) {
      PremiumSnackbar.showSuccess(null, "Berhasil, $actionLabel");
      if (nextStatus == 'completed' || nextStatus == 'completed_unconfirmed') {
        statsProvider.refreshNow(authToken); // Perbarui statistik penjualan dashboard jika pesanan selesai
      }
    } else {
      PremiumSnackbar.showError(null, "Gagal memperbarui status. Silakan coba lagi");
    }
    setState(() => _isUpdating = false);
  }

  // Fungsi untuk menghapus riwayat pesanan (Khusus pesanan Selesai / Dibatalkan)
  Future<void> _handleDelete() async {
    final provider = context.read<OrderAdminProvider>();
    final statsProvider = context.read<AdminStatsProvider>();
    final authToken = context.read<AuthProvider>().token;

    // Tampilkan dialog konfirmasi penghapusan
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Hapus Pesanan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: context.colors.textDark,
          ),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus riwayat pesanan #${widget.order.orderId} ini secara permanen?',
          style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', 
              style: GoogleFonts.plusJakartaSans(
                color: context.colors.textGrey,
                fontWeight: FontWeight.w600,
              )
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Hapus', 
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isUpdating = true);
    final success = await provider.deleteOrder(widget.order.id);

    if (!mounted) return;

    if (success) {
      PremiumSnackbar.showSuccess(null, "Pesanan berhasil dihapus");
      statsProvider.refreshNow(authToken); // Perbarui statistik dashboard setelah penghapusan
    } else {
      PremiumSnackbar.showError(null, "Gagal menghapus pesanan. Silakan coba lagi");
    }
    setState(() => _isUpdating = false);
  }

  // Fungsi untuk menampilkan lembar detail rincian pesanan (Bottom Sheet)
  void _showDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderDetailSheet(order: widget.order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final bool canAct = order.isPending || order.isProcessing;

    final String actionLabel = order.isPending
        ? 'Menerima'
        : order.isProcessing
            ? 'Selesaikan'
            : 'Selesai ✓';

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) {
        return Transform.scale(
          scale: order.isPending ? _pulseAnimation.value : 1.0,
          child: child,
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.surface, borderRadius: BorderRadius.circular(48),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
          border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Kiri: Info Pesanan ─────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusBadge(context, order.status),
                      Text(
                        order.timeAgo,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: context.colors.textHint,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),

                  Text(
                    'Order #${order.orderId}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textDark,
                      height: 22.5 / 18,
                    ),
                  ),

                  Text(
                    'Pelanggan : ${order.guestName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: context.colors.textGrey,
                    ),
                  ),
                  SizedBox(height: 8),

                  Row(
                    children: [
                      Icon(
                        Icons.bakery_dining_rounded,
                        color: context.colors.primaryOrange,
                        size: 14,
                      ),
                      SizedBox(width: 8),
                      Text(
                        order.formattedTotal,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: context.colors.textDark,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: canAct && !_isUpdating ? _handleAction : null,
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            height: 36,
                            decoration: BoxDecoration(
                              color: canAct
                                  ? context.colors.primaryOrange
                                  : order.isCancelled
                                      ? context.colors.error
                                      : Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: Center(
                              child: _isUpdating
                                  ? SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      actionLabel,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showDetail,
                        child: Container(
                          height: 36,
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: context.colors.divider,
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Center(
                            child: Text(
                              'Detail',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.colors.textGrey,
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (order.isCompleted || order.isCancelled) ...[
                        SizedBox(width: 8),
                        GestureDetector(
                          onTap: !_isUpdating ? _handleDelete : null,
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: context.colors.error.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.delete_outline_rounded,
                                color: context.colors.error,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),

            // ─── Kanan: Gambar Produk ─────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: OrderThumbnail(
                imageUrl: order.thumbnailImage,
                itemCount: order.items.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi pembantu untuk mewarnai label status pesanan secara dinamis
  Widget _buildStatusBadge(BuildContext context, String status) {
    Color badgeColor;
    String badgeText;

    switch (status) {
      case 'processing':
        badgeColor = Color(0xFFF59E0B);
        badgeText = 'Pengolahan';
        break;
      case 'completed':
      case 'done':
        badgeColor = context.colors.success;
        badgeText = 'Selesai';
        break;
      case 'completed_unconfirmed':
        badgeColor = Colors.orange;
        badgeText = 'Belum Konfirmasi';
        break;
      case 'cancelled':
        badgeColor = context.colors.textHint;
        badgeText = 'Dibatalkan';
        break;
      default: // pending
        badgeColor = context.colors.error;
        badgeText = 'Tertunda';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        badgeText.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// Widget untuk merender gambar kecil produk dengan efek loading/fallback
class OrderThumbnail extends StatelessWidget {
  final String imageUrl;
  final int itemCount;
  const OrderThumbnail({super.key, required this.imageUrl, required this.itemCount});

  @override
  Widget build(BuildContext context) {
    final bool hasImage = imageUrl.isNotEmpty;

    return Container(
      width: 100,
      height: 130,
      decoration: BoxDecoration(
        color: context.colors.primaryOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(32),
      ),
      child: hasImage
          ? Stack(
              fit: StackFit.expand,
              children: [
                // Render gambar lewat jaringan internet
                Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        color: context.colors.primaryOrange,
                        strokeWidth: 2,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => _buildFallback(context),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        '$itemCount Item',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : _buildFallback(context),
    );
  }

  // Fungsi jika gagal memuat gambar/gambar kosong (fallback ke ikon default)
  Widget _buildFallback(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bakery_dining_rounded, color: context.colors.primaryOrange, size: 40),
        SizedBox(height: 8),
        Text(
          '$itemCount Item',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.primaryOrange,
          ),
        ),
      ],
    );
  }
}
