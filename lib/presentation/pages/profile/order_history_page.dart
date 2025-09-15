import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/network/api_service.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../features/cart/providers/cart_provider.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../features/product/models/product_model.dart';
import 'order_detail_page.dart';
import 'rating_dialog.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _orders = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    final auth = Provider.of<AuthProvider>(context, listen: false);

    try {
      final response = await http.get(
        Uri.parse(ApiService.userOrders),
        headers: {"Authorization": "Bearer ${auth.token}"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<dynamic> parsedOrders = [];
        if (data is List) {
          parsedOrders = data;
        } else if (data is Map && data.containsKey('data')) {
          parsedOrders = data['data'];
        }

        setState(() {
          _orders = parsedOrders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Gagal memuat pesanan (${response.statusCode})";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error: $e";
        _isLoading = false;
      });
    }
  }

  void _handleReorder(dynamic order) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final items = order['items'] as List;

    int addedCount = 0;
    for (var item in items) {
      final food = item['food'] ?? item['product'] ?? item['Produk'];
      if (food != null) {
        final product = ProductModel(
          id: food['id'] ?? 0,
          nama: food['name'] ?? 'Produk',
          description: food['description'] ?? '',
          harga: (item['price'] ?? 0).toDouble(),
          gambar: food['image_url'] ?? '',
          rating: (food['rating'] as num?)?.toDouble() ?? 0.0,
          category: food['category'] ?? '',
          isBestseller: food['is_bestseller'] ?? false,
          stok: food['stock'] ?? 99,
          soldCount: food['sold_count'] ?? 0,
        );

        final int qty = item['quantity'] ?? 1;
        for (int i = 0; i < qty; i++) {
          cart.addToCart(product);
        }
        addedCount += qty;
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$addedCount item berhasil ditambahkan ke keranjang!"),
        backgroundColor: Color(0xFFD47311),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── BATALKAN PESANAN ────────────────────────────────────────
  Future<void> _cancelOrder(dynamic order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Batalkan Pesanan?",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text(
          "Pesanan #${order['id']} akan dibatalkan. Tindakan ini tidak dapat diulang.",
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Tidak", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Ya, Batalkan",
                style: GoogleFonts.plusJakartaSans(
                    color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.put(
        Uri.parse(ApiService.cancelOrderById(order['id'])),
        headers: {
          "Authorization": "Bearer ${auth.token}",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"status": "cancelled"}),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Pesanan #${order['id']} berhasil dibatalkan"),
            backgroundColor: Colors.orange.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchOrders(); // Refresh list
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Gagal membatalkan pesanan. Coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── KONFIRMASI PENGAMBILAN ──────────────────────────────────
  Future<void> _confirmPickup(dynamic order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "Konfirmasi Pengambilan?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: context.colors.textDark),
        ),
        content: Text(
          "Apakah Anda yakin ingin mengonfirmasi bahwa Anda sudah mengambil pesanan #${order['order_ref'] ?? order['id']}?",
          style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.success,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text("Ya, Sudah Ambil", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.put(
        Uri.parse(ApiService.confirmOrderPickupById(order['id'])),
        headers: {
          "Authorization": "Bearer ${auth.token}",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Pesanan berhasil dikonfirmasi pengambilan"),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _fetchOrders(); // Refresh list
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text("Gagal mengonfirmasi pengambilan. Coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── HAPUS RIWAYAT PESANAN ───────────────────────────────────
  Future<void> _deleteOrder(dynamic order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Riwayat?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text("Riwayat pesanan #${order['id']} akan dihapus permanen.", style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Hapus", style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.delete(
        Uri.parse(ApiService.userOrderById(order['id'])),
        headers: {"Authorization": "Bearer ${auth.token}"},
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 204) {
        setState(() {
          _orders.removeWhere((o) => o['id'] == order['id']);
        });
        messenger.showSnackBar(
          SnackBar(
            content: Text("Riwayat pesanan berhasil dihapus"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text("Gagal menghapus riwayat. Coba lagi."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── HAPUS SEMUA RIWAYAT ──────────────────────────────────────
  Future<void> _showDeleteAllConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Hapus Semua Riwayat?", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
        content: Text("Seluruh riwayat pesanan yang sudah selesai atau dibatalkan akan dihapus permanen.", style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Batal", style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("Ya, Hapus Semua", style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _deleteAllHistory();
    }
  }

  Future<void> _deleteAllHistory() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    
    setState(() => _isLoading = true);
    
    try {
      final response = await http.delete(
        Uri.parse(ApiService.deleteAllUserOrders),
        headers: {"Authorization": "Bearer ${auth.token}"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Filter lokal hanya yang MASIH AKTIF (pending/processing)
        setState(() {
          _orders.removeWhere((o) => ['completed', 'done', 'completed_unconfirmed', 'cancelled'].contains(o['status']?.toString().toLowerCase()));
          _isLoading = false;
        });
        messenger.showSnackBar(
          SnackBar(content: Text("Seluruh riwayat berhasil dihapus")),
        );
      } else {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(content: Text("Gagal menghapus riwayat"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
       if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── BERI RATING ────────────────────────────────────────────
  Future<void> _showRatingDialog(dynamic order) async {
    final items = order['items'] as List;
    if (items.isEmpty) return;

    final food = items.first['food'] ?? items.first['product'] ?? items.first['Produk'];
    final int foodId = food?['id'] ?? 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RatingDialog(
        orderId: order['id'],
        foodId: foodId,
        foodName: food?['name'] ?? 'Produk',
      ),
    );
    // Refresh setelah rating disubmit
    if (mounted) _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. LIST CONTENT
            Column(
              children: [
                SizedBox(height: 80), // Padding for Sticky Header
                Expanded(
                  child: _isLoading
                      ? Center(child: CircularProgressIndicator(color: Color(0xFFD47311)))
                      : _errorMessage.isNotEmpty
                          ? Center(child: Text(_errorMessage))
                          : _orders.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  color: Color(0xFFD47311),
                                  onRefresh: _fetchOrders,
                                  child: ListView.builder(
                                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    itemCount: _orders.length,
                                    itemBuilder: (context, index) {
                                      return _buildOrderCard(_orders[index]);
                                    },
                                  ),
                                ),
                ),
              ],
            ),

            // 2. STICKY HEADER (Glassmorphism)
            Positioned(
              top: 0, left: 0, right: 0,
              child: _buildStickyHeader(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStickyHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.bgColor.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFD47311).withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(shape: BoxShape.circle),
              child: Center(child: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: context.colors.textDark)),
            ),
          ),
          Text(
            "Riwayat Pesanan",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textDark,
            ),
          ),
          if (_orders.any((o) => ['completed', 'done', 'completed_unconfirmed', 'cancelled'].contains(o['status']?.toString().toLowerCase())))
            IconButton(
              onPressed: _showDeleteAllConfirmation,
              icon: Icon(Icons.delete_sweep_outlined, color: Colors.redAccent),
              tooltip: "Hapus Semua Riwayat",
            )
          else
            SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFD47311).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_rounded, size: 64, color: Color(0xFFD47311)),
          ),
          SizedBox(height: 16),
          Text(
            "Belum ada riwayat pesanan.",
            style: GoogleFonts.plusJakartaSans(color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final items = order['items'] as List;
    final String status = (order['status'] ?? 'Pending');
    final String id = order['id']?.toString() ?? '0';
    final String orderRef = (order['order_ref'] != null && order['order_ref'].toString().isNotEmpty) ? order['order_ref'] : '#ROTI515-$id';
    final String date = order['created_at']?.toString().substring(0, 10) ?? '-';
    final double total = (order['total'] ?? 0).toDouble();
    final bool hasRated = order['has_rated'] == true;

    // Summary text
    String summary = "${items.length} item: ";
    if (items.isNotEmpty) {
      summary += "${(items.first['food'] ?? items.first['product'] ?? items.first['Produk'])?['name'] ?? ''}";
    }

    // Status Badge Colors
    Color badgeBg;
    Color badgeText;
    String statusLabel;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'done':
        badgeBg = Color(0xFFDCFCE7);
        badgeText = Color(0xFF15803D);
        statusLabel = "Selesai";
        break;
      case 'completed_unconfirmed':
        badgeBg = Color(0xFFFEF9C3);
        badgeText = Color(0xFFA16207);
        statusLabel = "Belum Konfirmasi Pengambilan";
        break;
      case 'processing':
        badgeBg = Color(0xFFFEF9C3);
        badgeText = Color(0xFFA16207);
        statusLabel = "Diproses";
        break;
      case 'cancelled':
        badgeBg = Color(0xFFF1F5F9);
        badgeText = Color(0xFF64748B);
        statusLabel = "Dibatalkan";
        break;
      default:
        badgeBg = Color(0xFFFEE2E2);
        badgeText = Color(0xFFB91C1C);
        statusLabel = "Menunggu";
    }

    final bool isPending = statusLabel == "Menunggu";
    final bool isCompleted = statusLabel == "Selesai";
    final bool isCancelled = statusLabel == "Dibatalkan";

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(48),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Color(0xFFD47311).withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: ID, Status, and Image
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          orderRef,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textDark,
                          ),
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBg,
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              statusLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: badgeText,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      date,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: items.isNotEmpty
                    ? Image.network(
                        ApiService.getDisplayImage((items.first['food'] ?? items.first['product'] ?? items.first['Produk'])?['image_url']),
                        width: 56, height: 56, fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) =>
                            Container(width: 56, height: 56, color: Colors.grey.shade100),
                      )
                    : Container(width: 56, height: 56, color: Colors.grey.shade100),
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5, color: Color(0x0DD47311)),
          ),

          // Row 2: Summary Text
          Text(
            summary,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: context.colors.textGrey,
            ),
          ),

          SizedBox(height: 12),

          // Row 3: Price & Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Rp ${formatRupiah(total)}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textDark,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 6,
                  runSpacing: 8,
                  children: [
                    // Tombol Detail (selalu ada)
                    _buildSecondaryButton(
                      "Detail",
                      () async {
                        final result = await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => OrderDetailPage(order: order)),
                        );
                        if (result == true && mounted) {
                          _fetchOrders();
                        }
                      },
                    ),

                    // Tombol Batalkan — hanya untuk pesanan pending
                    if (isPending)
                      _buildDangerButton("Batalkan", () => _cancelOrder(order)),

                    // Tombol Konfirmasi Ambil — hanya jika completed_unconfirmed
                    if (status.toLowerCase() == 'completed_unconfirmed')
                      _buildPrimaryButton("Konfirmasi Ambil", () => _confirmPickup(order)),

                    // Tombol Pesan Lagi — hanya jika selesai
                    if (isCompleted)
                      _buildPrimaryButton("Pesan Lagi", () => _handleReorder(order)),

                    // Tombol Beri Rating — hanya jika selesai & belum dirating
                    if (isCompleted && !hasRated)
                      _buildRatingButton(() => _showRatingDialog(order)),

                    // Tombol Hapus — untuk pesanan selesai atau dibatalkan
                    if (isCompleted || isCancelled || status.toLowerCase() == 'completed_unconfirmed')
                      _buildIconButton(Icons.delete_outline_rounded, Colors.red.shade300,
                          () => _deleteOrder(order)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Color(0xFFD47311).withValues(alpha: 0.2)),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFFD47311),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xFFD47311),
          borderRadius: BorderRadius.circular(99),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFD47311).withValues(alpha: 0.2),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerButton(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_rounded, size: 16, color: Colors.amber.shade600),
            SizedBox(width: 4),
            Text(
              "Rating",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Center(child: Icon(icon, size: 18, color: color)),
      ),
    );
  }
}

