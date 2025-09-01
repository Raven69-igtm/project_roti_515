import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../cart/providers/cart_provider.dart';
import '../../models/product_model.dart';
import '../../../../core/utils/premium_snackbar.dart';
import 'package:roti_515/core/theme/app_theme.dart';

/// Sticky bottom bar di halaman detail produk.
/// Menampilkan tombol "Masukkan Keranjang" + total harga.
/// Animasi 3: squircle morph + ripple effect saat tombol ditekan.
class DetailBottomBar extends StatefulWidget {
  final ProductModel product;
  final int quantity;

  const DetailBottomBar({
    super.key,
    required this.product,
    required this.quantity,
  });

  @override
  State<DetailBottomBar> createState() => _DetailBottomBarState();
}

class _DetailBottomBarState extends State<DetailBottomBar>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  // Controller untuk efek ripple (pulse) pada tombol
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseScale;
  late final Animation<double> _pulseOpacity;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _pulseScale = Tween<double>(begin: 1.0, end: 1.18)
        .chain(CurveTween(curve: Curves.easeOut))
        .animate(_pulseCtrl);

    _pulseOpacity = Tween<double>(begin: 0.4, end: 0.0)
        .chain(CurveTween(curve: Curves.easeIn))
        .animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleAddToCart(BuildContext context) async {
    // Animasi squircle: tombol sedikit mengecil saat ditekan
    setState(() => _isPressed = true);
    // Trigger pulse/ripple
    _pulseCtrl.forward(from: 0);

    await Future.delayed(Duration(milliseconds: 100));
    setState(() => _isPressed = false);

    if (!context.mounted) return;

    if (widget.product.stok <= 0) return;
    
    final cart = Provider.of<CartProvider>(context, listen: false);
    for (int i = 0; i < widget.quantity; i++) {
      cart.addToCart(widget.product);
    }

    if (!context.mounted) return;

    PremiumSnackbar.showSuccess(context, "Pesanan masuk ke keranjang");
    
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final int totalPrice =
        (widget.product.harga * widget.quantity).toInt();

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.colors.white.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: context.colors.divider)),
          ),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.product.stok > 0 ? () => _handleAddToCart(context) : null,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // ── Lapisan pulse/ripple ──────────────────────────────────
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseScale.value,
                    child: Opacity(
                      opacity: _pulseOpacity.value,
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: context.colors.primaryOrange,
                          borderRadius: BorderRadius.circular(40),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Tombol utama dengan squircle morph ────────────────────
                AnimatedContainer(
                  duration: Duration(milliseconds: 120),
                  curve: Curves.easeInOut,
                  height: _isPressed ? 50 : 56,
                  decoration: BoxDecoration(
                    color: widget.product.stok == 0
                        ? context.colors.textHint.withValues(alpha: 0.3)
                        : _isPressed
                            ? context.colors.primaryOrange.withValues(alpha: 0.88)
                            : context.colors.primaryOrange,
                    // Border radius mengecil saat ditekan (squircle effect)
                    borderRadius:
                        BorderRadius.circular(_isPressed ? 24 : 40),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.primaryOrange
                            .withValues(alpha: _isPressed ? 0.15 : 0.3),
                        blurRadius: _isPressed ? 6 : 15,
                        offset: Offset(0, _isPressed ? 4 : 10),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: Duration(milliseconds: 200),
                        child: Icon(
                          _isPressed
                              ? Icons.shopping_bag_rounded
                              : Icons.shopping_bag_outlined,
                          key: ValueKey(_isPressed),
                          color: context.colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        widget.product.stok == 0 ? "Stok Telah Habis" : "Masukkan Keranjang  Rp ${formatRupiah(totalPrice)}",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.product.stok == 0 ? context.colors.textHint : context.colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

