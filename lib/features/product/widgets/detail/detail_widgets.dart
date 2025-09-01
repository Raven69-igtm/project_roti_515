import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../presentation/pages/profile/rating_dialog.dart';

import '../../../../core/utils/price_formatter.dart';
import '../../../../core/widgets/universal_image.dart';
import '../../models/product_model.dart';
import '../../../../core/utils/premium_snackbar.dart';
import '../../../../features/favorite/providers/favorite_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

/// Header gambar besar di atas halaman detail produk.
class DetailImageHeader extends StatelessWidget {
  final ProductModel product;
  const DetailImageHeader({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: context.colors.textDark.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        child: Hero(
          tag: 'product-image-${product.id}',
          child: UniversalImage(
            imageUrl: product.gambar.isNotEmpty
                ? product.gambar
                : "https://placehold.co/440x400",
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

/// Baris aksi floating (back + favorit) di atas gambar.
class DetailFloatingActions extends StatelessWidget {
  final ProductModel product;
  const DetailFloatingActions({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(
            icon: Icons.arrow_back_ios_new_rounded,
            size: 18,
            onTap: () => Navigator.pop(context),
          ),
          Consumer<FavoriteProvider>(
            builder: (context, favProvider, _) {
              final isFav = favProvider.isFavorite(product);
              return _GlassButton(
                icon: isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.red : null,
                onTap: () {
                  favProvider.toggleFavorite(product);
                  PremiumSnackbar.showSuccess(
                    context,
                    isFav ? "Dihapus dari Favorit" : "Ditambahkan ke Favorit!",
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Info produk: nama, badge rating, harga.
class DetailProductInfo extends StatelessWidget {
  final ProductModel product;
  const DetailProductInfo({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nama,
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 30,
                    color: context.colors.textBrown,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.colors.primaryOrange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded,
                              color: context.colors.primaryOrange, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "${product.rating}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: context.colors.primaryOrange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => RatingDialog(
                            orderId: 0, // 0 berarti review lepas (tanpa order)
                            foodId: product.id,
                            foodName: product.nama,
                          ),
                        );
                      },
                      child: Text(
                        "Beri Ulasan",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: context.colors.primaryOrange,
                          decoration: TextDecoration.underline,
                          decorationColor: context.colors.primaryOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Text(
            "Rp ${formatRupiah(product.harga)}",
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 24,
              color: context.colors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}

/// Bagian deskripsi + tag kategori.
class DetailDescription extends StatelessWidget {
  final ProductModel product;
  const DetailDescription({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Deskripsi",
            style: GoogleFonts.dmSerifDisplay(
              fontSize: 18,
              color: context.colors.textBrown,
            ),
          ),
          SizedBox(height: 8),
          Text(
            product.description.isNotEmpty
                ? product.description
                : "Deskripsi produk belum tersedia.",
            style: GoogleFonts.notoSans(
              fontSize: 14,
              color: context.colors.textGrey,
              height: 1.6,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Tag(
                  text: product.category.isNotEmpty
                      ? product.category
                      : "Roti"),
              if (product.isBestseller) _Tag(text: "Bestseller 🔥"),
              _Tag(
                text: product.stok == 0 ? "Stok Habis" : "Stok: ${product.stok}",
                color: product.stok == 0 ? context.colors.error : context.colors.primaryOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selector jumlah produk yang akan dibeli.
class DetailQuantitySelector extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const DetailQuantitySelector({
    super.key,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Sesuaikan",
                style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18,
                  color: context.colors.textBrown,
                ),
              ),
              Text(
                "Opsional",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: context.colors.textHint,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.colors.surface,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Jumlah",
                  style: GoogleFonts.pragatiNarrow(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textBrown,
                  ),
                ),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.white,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: context.colors.divider),
                    boxShadow: [
                      BoxShadow(
                          color: context.colors.textDark.withValues(alpha: 0.05),
                          blurRadius: 2,
                          offset: Offset(0, 1))
                    ],
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: onDecrease,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(24)),
                          child: Icon(Icons.remove_rounded,
                              color: context.colors.textHint, size: 18),
                        ),
                      ),
                      SizedBox(
                        width: 24,
                        child: Text(
                          "$quantity",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textBrown,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: onIncrease,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: context.colors.textBrown,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                  color: context.colors.textDark.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: Offset(0, 2))
                            ],
                          ),
                          child: Icon(Icons.add_rounded,
                              color: context.colors.white, size: 18),
                        ),
                      ),
                    ],
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

// ----- Private helpers -----

class _Tag extends StatelessWidget {
  final String text;
  final Color? color;
  const _Tag({required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color != null 
            ? color!.withValues(alpha: 0.1) 
            : context.colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: color != null 
                ? color!.withValues(alpha: 0.2) 
                : context.colors.divider),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          color: color ?? context.colors.textBrown,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? color;
  const _GlassButton(
      {required this.icon, required this.onTap, this.size = 20, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: context.colors.white.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border:
                  Border.all(color: context.colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(icon, color: color ?? context.colors.textDark, size: size),
          ),
        ),
      ),
    );
  }
}

