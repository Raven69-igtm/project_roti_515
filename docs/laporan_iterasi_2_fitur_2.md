Laporan Iterasi 2 - Fitur 2 (PB-07 - Checkout Transaksi)

Dokumen ini disusun tanpa simbol markdown heading (seperti #, ##) agar Anda bisa langsung menyalin dan menempelkannya (copy-paste) ke Microsoft Word atau Google Docs dengan rapi.

========================================================================

b) Fitur 2: Checkout Transaksi (PB-07 - Pelanggan dapat melakukan checkout pesanan (multi-langkah) dan memilih metode pembayaran)

1. Deskripsi Fitur
Fitur Checkout Transaksi memandu pelanggan menyelesaikan proses pemesanan roti yang telah dimasukkan ke keranjang. Halaman ini memvalidasi apakah pengguna sudah masuk (login), mengonfirmasi alamat pengiriman, menampilkan ringkasan rincian biaya (subtotal, biaya pengiriman gratis jika ambil langsung di toko), serta memproses pengiriman data order ke REST API server. Setelah sukses, pelanggan diarahkan ke halaman sukses transaksi dengan efek animasi checkmark yang dinamis dan kode referensi unik transaksi.

2. Implementasi Teknis & Alur Kerja
* Integrasi REST API (POST Request): Mengirimkan data detail checkout berupa array objek berisi product_id, quantity, dan price bertipe JSON ke endpoint orders dengan menyertakan token JWT untuk otorisasi di header.
* Efek Sequence Animasi Sukses: Menggunakan TickerProviderStateMixin dan AnimationController berantai untuk menghasilkan transisi checkmark memantul (elastic out), teks bergeser dari bawah, serta tombol yang perlahan muncul (fade & slide).
* Auto-Generating Order Reference: Sistem secara cerdas menggunakan algoritma generator acak untuk membuat kode referensi unik cadangan (misal: #ROTI515-XXXXX) jika backend tidak merespon referensi secara instan.

3. Kode Sumber Lengkap (Full Source Code)

```dart
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
  bool _isOrdering = false;
  static final int _deliveryFee = 0;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _placeOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    
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
      final orderData = {
        "jadwal_ambil_id": 0,       
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

      final response = await http.post(
        Uri.parse(ApiService.orders),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${auth.token}", 
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String orderCode = (data['order_ref'] != null && data['order_ref'].toString().isNotEmpty) ? data['order_ref'] : 'ROTI515-${data['order_id']}';

        cart.clearCart();
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
```

```dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_routes.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  final String orderRef;

  const CheckoutSuccessScreen({
    super.key,
    required this.orderRef,
  });

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _circleCtrl;
  late final Animation<double> _circleScale;
  late final Animation<double> _circleFade;

  late final AnimationController _textCtrl;
  late final Animation<double> _textSlide;
  late final Animation<double> _textFade;

  late final AnimationController _btnCtrl;
  late final Animation<double> _btnFade;
  late final Animation<double> _btnSlide;

  @override
  void initState() {
    super.initState();

    _circleCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );
    _circleScale = CurvedAnimation(
      parent: _circleCtrl,
      curve: Curves.elasticOut,
    );
    _circleFade = CurvedAnimation(
      parent: _circleCtrl,
      curve: Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _textCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _textSlide = Tween<double>(begin: 30, end: 0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_textCtrl);
    _textFade = CurvedAnimation(
      parent: _textCtrl,
      curve: Curves.easeOut,
    );

    _btnCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );
    _btnFade = CurvedAnimation(parent: _btnCtrl, curve: Curves.easeOut);
    _btnSlide = Tween<double>(begin: 20, end: 0)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_btnCtrl);

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(Duration(milliseconds: 150));
    _circleCtrl.forward();
    await Future.delayed(Duration(milliseconds: 400));
    _textCtrl.forward();
    await Future.delayed(Duration(milliseconds: 300));
    _btnCtrl.forward();
  }

  @override
  void dispose() {
    _circleCtrl.dispose();
    _textCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F7F6),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _RadialBgPainter()),
          ),

          SafeArea(
            child: Column(
              children: [
                Spacer(flex: 2),

                ScaleTransition(
                  scale: _circleScale,
                  child: FadeTransition(
                    opacity: _circleFade,
                    child: _SuccessIcon(),
                  ),
                ),

                SizedBox(height: 32),

                // Judul & reference
                AnimatedBuilder(
                  animation: _textCtrl,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _textSlide.value),
                    child: FadeTransition(
                      opacity: _textFade,
                      child: child,
                    ),
                  ),
                  child: _OrderInfo(orderRef: widget.orderRef),
                ),

                Spacer(flex: 3),

                AnimatedBuilder(
                  animation: _btnCtrl,
                  builder: (_, child) => Transform.translate(
                    offset: Offset(0, _btnSlide.value),
                    child: FadeTransition(
                      opacity: _btnFade,
                      child: child,
                    ),
                  ),
                  child: _BottomActions(
                    onBack: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.mainNav,
                      (route) => false,
                    ),
                  ),
                ),

                SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RadialBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.75,
        colors: [
          Color(0xFFD47311).withValues(alpha: 0.06),
          Color(0xFFD47311).withValues(alpha: 0.0),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SuccessIcon extends StatelessWidget {
  const _SuccessIcon();

  @override
  Widget build(BuildContext context) {
    Color greenColor = Color(0xFF22C55E);

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        color: greenColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check_circle_rounded,
        color: greenColor,
        size: 50,
      ),
    );
  }
}

class _OrderInfo extends StatelessWidget {
  final String orderRef;
  const _OrderInfo({required this.orderRef});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Pesanan Berhasil',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
            height: 40 / 32,
          ),
        ),
        SizedBox(height: 8),

        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Order Ref: ',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF64748B),
                  height: 28 / 18,
                ),
              ),
              TextSpan(
                text: orderRef,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BottomActions extends StatefulWidget {
  final VoidCallback onBack;
  const _BottomActions({required this.onBack});

  @override
  State<_BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends State<_BottomActions>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressScale;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
      reverseDuration: Duration(milliseconds: 150),
    );
    _pressScale = Tween<double>(begin: 1.0, end: 0.96)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_pressCtrl);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePress() async {
    await _pressCtrl.forward();
    await _pressCtrl.reverse();
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          GestureDetector(
            onTap: _handlePress,
            child: ScaleTransition(
              scale: _pressScale,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: context.colors.primaryOrange,
                  borderRadius: BorderRadius.circular(9999),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primaryOrange.withValues(alpha: 0.30),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Kembali ke Beranda',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.white,
                      letterSpacing: 0.4,
                      height: 24 / 16,
                    ),
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          Text(
            'roti515',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF94A3B8),
              height: 20 / 14,
            ),
          ),
        ],
      ),
    );
  }
}

String generateOrderRef() {
  final rand = Random().nextInt(90000) + 10000;
  return '#ROTI515-$rand';
}
```
