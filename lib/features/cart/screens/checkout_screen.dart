import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../widgets/checkout_widgets.dart';
import '../../../core/network/api_service.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}
class _CheckoutScreenState extends State<CheckoutScreen> {
  // Flag penanda proses pemesanan ke server sedang berjalan
  bool _isOrdering = false;
  // Biaya pengiriman/ongkir (diset 0 karena ambil langsung ke toko)
  static final int _deliveryFee = 0;

  @override
  void initState() {
    super.initState();
  }

  // --- LOGIKA UTAMA: PROSES CHECKOUT PESANAN ---
  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
    // Validasi 1: Pastikan keranjang belanja tidak kosong
    if (cart.items.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Keranjang belanja kosong",
                style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    setState(() => _isOrdering = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final int finalTotal = cart.totalPrice + _deliveryFee;

    // Validasi 2: Pastikan token user aktif (sudah login) sebelum checkout
    if (auth.token == null || auth.token!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Anda harus login untuk memesan",
                style: GoogleFonts.plusJakartaSans()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      setState(() => _isOrdering = false);
      return;
    }

    try {
      // 1. Menyusun payload data pesanan sesuai dengan parameter backend
      final orderData = {
        "jadwal_ambil_id": 0,       // 0 = tidak ada jadwal khusus (diambil langsung)
        "total": finalTotal.toDouble(),
        "metode_bayar": "Cash",
        "items": cart.items
            .map((item) => {
                  "product_id": item.product.id,
                  "quantity": item.quantity,
                  "price": item.product.price.toDouble(),
                })
            .toList(),
      };

      // 2. Mengirim data pesanan ke backend dengan otentikasi JWT Bearer Token
      final response = await http.post(
        Uri.parse(ApiService.orders),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth.token}", // Token otentikasi admin/pelanggan
        },
        body: jsonEncode(orderData),
      );

      // 3. Jika respon server 200 (OK/Sukses), bersihkan keranjang dan pindah ke halaman sukses
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String orderCode = (data['order_ref'] != null && data['order_ref'].toString().isNotEmpty) ? data['order_ref'] : 'ROTI515-${data['order_id']}';

        cart.clearCart(); // Kosongkan keranjang belanja setelah checkout sukses
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.checkoutSuccess,
            (route) => false,
            arguments: orderCode,
          );
        }
      } else {
        throw Exception("Gagal membuat pesanan (${response.statusCode})");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan: $e",
                style: GoogleFonts.plusJakartaSans(color: Colors.white)),
            backgroundColor: context.colors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isOrdering = false);
    }
  }

  // --- BUILD ---

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 220),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CheckoutStepper(),
                CheckoutDeliveryOption(),
                CheckoutConfirmationCard(),
                CheckoutOrderSummary(cart: cart, deliveryFee: _deliveryFee),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: CheckoutStickyBottom(
              cart: cart,
              deliveryFee: _deliveryFee,
              isOrdering: _isOrdering,
              onOrder: _placeOrder,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: context.colors.bgColor.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 60,
      leading: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: Icon(Icons.arrow_back_ios_new_rounded,
                color: context.colors.textDark, size: 18),
          ),
        ),
      ),
      centerTitle: true,
      title: Text(
        'Pembayaran',
        style: GoogleFonts.plusJakartaSans(
          color: context.colors.textDark,
          fontWeight: FontWeight.w700,
          fontSize: 18,
          height: 22.5 / 18,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Container(color: Color(0xFFF3F4F6), height: 1),
      ),
    );
  }
}
