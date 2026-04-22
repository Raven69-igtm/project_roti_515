import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../product_admin/providers/admin_product_provider.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../../core/utils/premium_snackbar.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/staggered_fade_animation.dart';
import '../../orders/providers/order_admin_provider.dart';
import '../../orders/widgets/order_detail_sheet.dart';
import '../../orders/models/order_model.dart';

/// Halaman Notifikasi Admin khusus memantau produk stok menipis (<= 15), habis (0), serta pesanan baru masuk (pending)
class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  int _selectedNotificationTab = 0; // 0 = Semua, 1 = Stok Kritis, 2 = Pesanan Baru

  @override
  void initState() {
    super.initState();
    // Pastikan produk dan pesanan ter-refresh saat masuk ke halaman ini
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AdminProductProvider>(context, listen: false).fetchProducts();
      Provider.of<OrderAdminProvider>(context, listen: false).fetchOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AdminProductProvider>(context);
    final orderProvider = Provider.of<OrderAdminProvider>(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Filter produk: stok <= 15
    final alertProducts = provider.allProducts.where((p) {
      final int stock = p['stock'] ?? 0;
      return stock <= 15;
    }).toList();

    // Urutkan produk: stok habis (0) dahulu, baru stok menipis (1-15)
    alertProducts.sort((a, b) {
      final int stockA = a['stock'] ?? 0;
      final int stockB = b['stock'] ?? 0;
      return stockA.compareTo(stockB);
    });

    // Filter pesanan: status pending
    final pendingOrders = orderProvider.allOrders.where((o) => o.isPending).toList();
    pendingOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Gabungkan notifikasi sesuai tab aktif
    final List<dynamic> unifiedNotifications = [];
    if (_selectedNotificationTab == 0) {
      unifiedNotifications.addAll(pendingOrders);
      unifiedNotifications.addAll(alertProducts);
    } else if (_selectedNotificationTab == 1) {
      unifiedNotifications.addAll(alertProducts);
    } else if (_selectedNotificationTab == 2) {
      unifiedNotifications.addAll(pendingOrders);
    }

    final bool isLoading = provider.isLoading || orderProvider.loadState == OrderLoadState.loading;

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: AppBar(
        backgroundColor: context.colors.bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colors.surface,
                border: Border.all(color: context.colors.divider),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: context.colors.textDark,
                size: 18,
              ),
            ),
          ),
        ),
        title: Text(
          "Notifikasi Dashboard",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.textDark,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          _buildFilterTabs(alertProducts.length, pendingOrders.length),
          
          Expanded(
            child: RefreshIndicator(
              color: context.colors.primaryOrange,
              onRefresh: () async {
                await provider.fetchProducts();
                await orderProvider.fetchOrders();
              },
              child: isLoading && unifiedNotifications.isEmpty
                  ? Center(child: CircularProgressIndicator(color: context.colors.primaryOrange))
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        if (unifiedNotifications.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final item = unifiedNotifications[index];
                                  if (item is OrderModel) {
                                    return Column(
                                      children: [
                                        StaggeredFadeAnimation(
                                          index: index,
                                          child: _buildOrderAlertCard(context, item),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  } else {
                                    return Column(
                                      children: [
                                        StaggeredFadeAnimation(
                                          index: index,
                                          child: _buildAlertCard(context, item, provider, auth.token ?? ''),
                                        ),
                                        const SizedBox(height: 16),
                                      ],
                                    );
                                  }
                                },
                                childCount: unifiedNotifications.length,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(int criticalStockCount, int newOrdersCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: context.colors.bgColor,
        border: Border(bottom: BorderSide(color: context.colors.divider, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildTabButton("Semua", 0, criticalStockCount + newOrdersCount),
          _buildTabButton("Stok Kritis", 1, criticalStockCount),
          _buildTabButton("Pesanan Baru", 2, newOrdersCount),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, int index, int count) {
    final bool isActive = _selectedNotificationTab == index;
    final Color activeColor = context.colors.primaryOrange;
    final Color inactiveColor = context.colors.textGrey;

    return GestureDetector(
      onTap: () => setState(() => _selectedNotificationTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? activeColor.withValues(alpha: 0.2) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive ? activeColor : inactiveColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "$count",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : context.colors.textDark,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      context.colors.success.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    )
                  ],
                ),
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 40,
                  color: context.colors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "Semua Aman!",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedNotificationTab == 1
                ? "Tidak ada produk dengan stok menipis\natau habis saat ini."
                : _selectedNotificationTab == 2
                    ? "Tidak ada pesanan baru masuk\nsaat ini."
                    : "Tidak ada notifikasi penting saat ini.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: context.colors.textGrey,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderAlertCard(BuildContext context, OrderModel order) {
    final Color tintColor = const Color(0xFF4F46E5); // Indigo/Purple untuk Pesanan Baru
    final Color bgTileColor = const Color(0xFFE0E7FF);
    final Color borderTileColor = const Color(0xFFC7D2FE);
    final String name = order.guestName;
    final String ref = order.orderId;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => OrderDetailSheet(order: order),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderTileColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: tintColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Stack(
          children: [
            // Left Accent Bar
            Positioned(
              left: 0,
              top: 20,
              bottom: 20,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: tintColor,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [tintColor, tintColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tintColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Pesanan Baru Masuk!",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tintColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: bgTileColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Tertunda",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: tintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "Pesanan baru #$ref dari $name sebesar ${order.formattedTotal} telah diterima. Harap segera konfirmasi dan proses.",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: context.colors.textDark,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.arrow_forward_rounded, size: 14, color: tintColor),
                            const SizedBox(width: 6),
                            Text(
                              "Ketuk untuk Detail & Terima",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: tintColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, Map<String, dynamic> product, AdminProductProvider provider, String token) {
    final int stock = product['stock'] ?? 0;
    final bool isOutOfStock = stock == 0;
    final String name = product['name'] ?? 'Produk';

    // Perbedaan Desain Warna & Ikon
    final Color tintColor = isOutOfStock ? context.colors.error : Colors.orange;
    final Color bgTileColor = isOutOfStock 
        ? context.colors.error.withValues(alpha: 0.05) 
        : Colors.orange.withValues(alpha: 0.05);
    final Color borderTileColor = isOutOfStock 
        ? context.colors.error.withValues(alpha: 0.2) 
        : Colors.orange.withValues(alpha: 0.2);
    final IconData statusIcon = isOutOfStock ? Icons.cancel_outlined : Icons.warning_amber_rounded;
    final String alertTitle = isOutOfStock ? "Stok Habis!" : "Stok Menipis";
    final String alertMessage = isOutOfStock
        ? "Produk $name telah habis. Segera tambahkan stok agar pelanggan dapat memesan kembali."
        : "Produk $name hanya tersisa $stock unit. Harap segera restock untuk mencegah kehabisan.";

    return InkWell(
      onTap: () => _showQuickRestockDialog(context, product, provider, token),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderTileColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: tintColor.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Stack(
          children: [
            // Left Accent Bar
            Positioned(
              left: 0,
              top: 20,
              bottom: 20,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: tintColor,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [tintColor, tintColor.withValues(alpha: 0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: tintColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: Icon(statusIcon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              alertTitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: tintColor,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: bgTileColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "Stok: $stock",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: tintColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alertMessage,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            color: context.colors.textDark,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.add_shopping_cart_rounded, size: 14, color: context.colors.primaryOrange),
                            const SizedBox(width: 6),
                            Text(
                              "Ketuk untuk Tambah Stok",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.colors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickRestockDialog(BuildContext context, Map<String, dynamic> product, AdminProductProvider provider, String token) {
    final TextEditingController stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Tambah Stok ${product['name']}",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: context.colors.textDark),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masukkan jumlah stok yang ditambahkan:",
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: context.colors.textDark),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.plusJakartaSans(color: context.colors.textDark),
              decoration: InputDecoration(
                hintText: "Contoh: 10",
                hintStyle: GoogleFonts.plusJakartaSans(color: context.colors.textHint),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.colors.primaryOrange),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Batal",
              style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final int addedStock = int.tryParse(stockController.text) ?? 0;
              if (addedStock <= 0) {
                PremiumSnackbar.showError(ctx, "Masukkan jumlah stok yang valid");
                return;
              }

              Navigator.pop(ctx);
              final int newStock = (product['stock'] ?? 0) + addedStock;

              bool success = await provider.updateProduct(
                id: product['id'],
                name: product['name'],
                category: product['category'] ?? "Lainnya",
                price: product['price'],
                stock: newStock,
                token: token,
              );

              if (context.mounted) {
                if (success) {
                  PremiumSnackbar.showSuccess(context, "Stok berhasil ditambahkan");
                } else {
                  PremiumSnackbar.showError(context, "Gagal menambah stok");
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primaryOrange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              "Simpan",
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
