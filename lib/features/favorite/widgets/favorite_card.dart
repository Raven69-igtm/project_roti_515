import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/universal_image.dart';
import '../../cart/providers/cart_provider.dart';
import '../../product/models/product_model.dart';
import '../../../core/utils/premium_snackbar.dart';
import '../providers/favorite_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class FavoriteCard extends StatelessWidget {
  final ProductModel product;
  const FavoriteCard({super.key, required this.product});

  void _showAddedSnackBar(BuildContext context, String name) {
    PremiumSnackbar.showSuccess(context, "$name ditambahkan!");
  }

  @override
  Widget build(BuildContext context) {
    final favProvider = Provider.of<FavoriteProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Container(
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Product Image ---
          Padding(
            padding: EdgeInsets.all(13),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Hero(
                    tag: 'product-image-${product.id}',
                    child: UniversalImage(
                      imageUrl: product.imageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Remove from favorites button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => favProvider.toggleFavorite(product),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: context.colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        color: context.colors.error,
                        size: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- Name & Description ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.colors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  product.description,
                  style: GoogleFonts.pontanoSans(
                    fontSize: 12,
                    color: context.colors.textGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rp ${formatRupiah(product.price)}",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: context.colors.textDark,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        cartProvider.addToCart(product);
                        _showAddedSnackBar(context, product.name);
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: context.colors.textDark,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: context.colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }
}

