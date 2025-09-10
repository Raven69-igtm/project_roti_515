import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class OrderDetailPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailPage({super.key, required this.order});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  late String _currentStatus;
  bool _isStatusChanged = false;
  bool _isLoadingConfirm = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.order['status'] ?? 'Pending';
  }

  Future<void> _confirmPickup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          "Konfirmasi Pengambilan?",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: context.colors.textDark,
          ),
        ),
        content: Text(
          "Apakah Anda yakin ingin mengonfirmasi bahwa Anda sudah mengambil pesanan #${widget.order['order_ref'] ?? widget.order['id']}?",
          style: GoogleFonts.plusJakartaSans(color: context.colors.textGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Batal",
              style: GoogleFonts.plusJakartaSans(
                color: context.colors.textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.primaryOrange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Ya, Sudah Ambil",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isLoadingConfirm = true);

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.put(
        Uri.parse(ApiService.confirmOrderPickupById(widget.order['id'])),
        headers: {
          "Authorization": "Bearer ${auth.token}",
          "Content-Type": "application/json",
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _currentStatus = 'completed';
          _isStatusChanged = true;
          _isLoadingConfirm = false;
        });
        messenger.showSnackBar(
          SnackBar(
            content: const Text("Pesanan berhasil dikonfirmasi pengambilan"),
            backgroundColor: context.colors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      } else {
        setState(() => _isLoadingConfirm = false);
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Gagal mengonfirmasi pengambilan. Coba lagi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingConfirm = false);
        messenger.showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget? _buildBottomBar() {
    if (_currentStatus.toLowerCase() != 'completed_unconfirmed') return null;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: 24 + MediaQuery.of(context).padding.bottom,
        top: 16,
      ),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _isLoadingConfirm
                ? Center(
                    child: CircularProgressIndicator(
                      color: context.colors.primaryOrange,
                    ),
                  )
                : GestureDetector(
                    onTap: _confirmPickup,
                    child: Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE28A2B),
                            context.colors.primaryOrange,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primaryOrange.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          "KONFIRMASI PENGAMBILAN",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.order['items'] as List?) ?? [];
    final String orderId = widget.order['id']?.toString() ?? '0';
    final String orderRef = widget.order['order_ref'] ?? '#ROTI515-$orderId';
    final String date = widget.order['created_at']?.toString().substring(0, 10) ?? '-';
    final double total = (widget.order['total'] ?? 0).toDouble();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.pop(context, _isStatusChanged);
      },
      child: Scaffold(
        backgroundColor: context.colors.bgColor,
        bottomNavigationBar: _buildBottomBar(),
        body: SafeArea(
          child: Column(
            children: [
              // --- CUSTOM HEADER ---
              _buildHeader(context),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- STATUS CARD ---
                      _buildStatusCard(_currentStatus, orderRef, date),

                      const SizedBox(height: 16),

                      // --- JADWAL PENGAMBILAN ---
                      _buildPickupTimeCard(context, widget.order['pickup_time'] ?? widget.order['jam_ambil']),

                      const SizedBox(height: 24),

                      // --- ITEMS SECTION ---
                      Text(
                        "Rincian Pesanan",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: context.colors.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...items.map((item) => _buildOrderItem(item)),

                      const SizedBox(height: 24),

                      // --- PAYMENT SUMMARY ---
                      _buildPaymentSummary(total),
                      
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.colors.bgColor.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: context.colors.primaryOrange.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context, _isStatusChanged),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            color: context.colors.textDark,
          ),
          Text(
            "Detail Pesanan",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.colors.textDark,
            ),
          ),
          const SizedBox(width: 48), // Spacer to center title
        ],
      ),
    );
  }

  Widget _buildStatusCard(String status, String ref, String date) {
    Color badgeBg;
    Color badgeText;
    String statusLabel;

    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
      case 'done':
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF15803D);
        statusLabel = "Selesai";
        break;
      case 'completed_unconfirmed':
        badgeBg = const Color(0xFFFEF9C3);
        badgeText = const Color(0xFFA16207);
        statusLabel = "Belum Konfirmasi Pengambilan";
        break;
      case 'processing':
        badgeBg = const Color(0xFFFEF9C3);
        badgeText = const Color(0xFFA16207);
        statusLabel = "Diproses";
        break;
      case 'cancelled':
        badgeBg = const Color(0xFFF1F5F9);
        badgeText = const Color(0xFF64748B);
        statusLabel = "Dibatalkan";
        break;
      default:
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFB91C1C);
        statusLabel = "Menunggu";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textDark,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: context.colors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
    );
  }

  Widget _buildOrderItem(dynamic item) {
    final food = item['food'] ?? item['product'] ?? {};
    final String name = food['name'] ?? 'Roti';
    final int qty = item['quantity'] ?? 1;
    final double price = (item['price'] ?? 0).toDouble();
    final String imageUrl = food['image_url'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              ApiService.getDisplayImage(imageUrl),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 56, height: 56, color: context.colors.surface,
                child: Icon(Icons.bakery_dining_rounded, color: context.colors.textGrey),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Kode Produk: #${food['id'] ?? item['food_id'] ?? item['product_id'] ?? '-'}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: context.colors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "$qty x Rp ${formatRupiah(price)}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: context.colors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            "Rp ${formatRupiah(price * qty)}",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: context.colors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummary(double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colors.primaryOrange.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          _buildSummaryRow("Subtotal", total),
          Divider(height: 24, thickness: 0.5, color: context.colors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Pembayaran",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textDark,
                ),
              ),
              Text(
                "Rp ${formatRupiah(total)}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: context.colors.primaryOrange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: context.colors.textGrey,
            ),
          ),
          Text(
            "Rp ${formatRupiah(value)}",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: context.colors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupTimeCard(BuildContext context, String? pickupTime) {
    final bool hasTime = pickupTime != null && pickupTime.trim().isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.colors.primaryOrange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.access_time_rounded,
              color: context.colors.primaryOrange,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Jadwal Pengambilan Produk",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textGrey,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  hasTime ? pickupTime : "Menunggu jadwal ditetapkan oleh Admin",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: hasTime ? context.colors.primaryOrange : context.colors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
