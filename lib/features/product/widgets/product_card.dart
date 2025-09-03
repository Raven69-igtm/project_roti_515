import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/price_formatter.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/widgets/universal_image.dart';
import '../../cart/providers/cart_provider.dart';
import '../../favorite/providers/favorite_provider.dart';
import '../models/product_model.dart';
import '../../../core/utils/premium_snackbar.dart';
import '../screens/product_detail_screen.dart';
import 'cart_fly_animation.dart';
import 'animated_favorite_button.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;

  /// Key pada widget gambar produk, digunakan oleh fly animation.
  final GlobalKey imageKey;

  const ProductCard({
    super.key,
    required this.product,
    required this.imageKey,
  });

  void _showAddedSnackBar(BuildContext context) {
    PremiumSnackbar.showSuccess(context, "${product.nama} ditambahkan!");
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FavoriteProvider>(
      builder: (context, favProvider, _) {
        final bool isFav = favProvider.isFavorite(product);

        return Container(
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: context.colors.divider),
            boxShadow: [
              BoxShadow(
                color: context.colors.textDark.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gambar + badge rating + tombol favorit
              Padding(
                padding: EdgeInsets.all(13),
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ProductDetailScreen(product: product),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        // GlobalKey dipasang di sini supaya fly animation bisa
                        // membaca posisi gambar di layar.
                        child: Hero(
                          key: imageKey,
                          tag: 'product-image-${product.id}',
                          child: UniversalImage(
                            imageUrl: product.gambar.isNotEmpty
                                ? product.gambar
                                : 'https://placehold.co/400',
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                      // Badge rating
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _RatingBadge(
                        rating: "${product.rating}",
                      ),
                    ),
                    // Tombol favorit
                    Positioned(
                      top: 8,
                      right: 8,
                      child: AnimatedFavoriteButton(
                        isFavorite: isFav,
                        onTap: () => favProvider.toggleFavorite(product),
                      ),
                    ),
                    // Badge Stok (Animasi 2: Badge pada gambar)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: product.stok == 0 
                              ? context.colors.error.withValues(alpha: 0.9) 
                              : context.colors.primaryOrange.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                            )
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              product.stok == 0 ? Icons.block_flipped : Icons.inventory_2_rounded,
                              size: 10,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              product.stok == 0 ? "Habis" : "${product.stok}",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Badge Detail
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => Navigator.push(context,
                          FadePageRoute(
                            page: ProductDetailScreen(product: product),
                          ),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: context.colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Detail",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Color(0xFF475569)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Area Teks Detail: Judul, Deskripsi, Harga (Bagian paruh bawah kartu)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Rata kiri teks
                  children: [
                    // Label Judul "Nama Roti"
                    Text(
                      product.nama,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: context.colors.textDark,
                      ),
                      maxLines: 1, // Batasi 1 baris supaya layout rapi
                      overflow: TextOverflow.ellipsis, // Jika kepanjangan, potong dengan tanda "..."
                    ),
                    
                    // Label Deskripsi Varian Roti (Kecil)
                    Text(
                      product.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: context.colors.textGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),
                    
                    // Row untuk meletakkan "Label Harga" rata kiri dan "Tombol Plus" mentok di ujung kanan
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nilai angka harga Rupiah dengan format string converter kustom
                        Text(
                          "Rp ${formatRupiah(product.harga)}",
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: context.colors.textDark,
                          ),
                        ),
                    // ── Animasi 1: Bounce tombol add-to-cart ──
                    _AddCartButton(
                      isEnabled: product.stok > 0,
                      onTap: () {
                        if (product.stok > 0) {
                          Provider.of<CartProvider>(context, listen: false)
                              .addToCart(product);
                          _showAddedSnackBar(context);

                          // ── Animasi 4: Flying product ke cart icon ──
                          CartFlyAnimation.trigger(
                            context: context,
                            sourceKey: imageKey,
                            imageUrl: product.gambar,
                          );
                        }
                      },
                    ),
                  ],
                ),
                SizedBox(height: 16), // Padding bawah kartu dipindah ke sini
              ],
            ),
          ),
        ],
      ),
    );
  },
);
  }
}

// ----- Animated Add Cart Button (Animasi 1: Bounce) -----

class _AddCartButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isEnabled;
  const _AddCartButton({required this.onTap, this.isEnabled = true});

  @override
  State<_AddCartButton> createState() => _AddCartButtonState();
}

class _AddCartButtonState extends State<_AddCartButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 120),
      reverseDuration: Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.72)
        .chain(CurveTween(curve: Curves.easeInOut))
        .animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isEnabled ? _handleTap : null,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: widget.isEnabled ? context.colors.textDark : context.colors.textHint.withValues(alpha: 0.3),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.add_rounded,
              color: widget.isEnabled ? context.colors.white : context.colors.textHint, 
              size: 18),
        ),
      ),
    );
  }
}

// ----- Rating Badge (private) -----

class _RatingBadge extends StatelessWidget {
  final String rating;
  const _RatingBadge({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded,
              color: context.colors.primaryOrange, size: 12),
          SizedBox(width: 2),
          Text(
            rating,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              color: context.colors.primaryOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

