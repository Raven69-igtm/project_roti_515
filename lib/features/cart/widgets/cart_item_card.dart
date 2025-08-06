import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/universal_image.dart';
import '../providers/cart_provider.dart';
import 'package:roti_515/core/theme/app_theme.dart';

/// Satu baris item di keranjang — gambar, nama, harga, qty selector, hapus.
class CartItemCard extends StatelessWidget {
  final dynamic item;
  final int index;

  const CartItemCard({super.key, required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          // Gambar
          ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: UniversalImage(
              imageUrl: item.product.imageUrl.isNotEmpty
                  ? item.product.imageUrl
                  : "https://placehold.co/88x88",
              width: 88,
              height: 88,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.product.nama,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.colors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => cart.removeItem(index),
                      child: Icon(Icons.delete_outline_rounded,
                          color: context.colors.textHint, size: 20),
                    ),
                  ],
                ),
                Text(
                  item.product.description.isNotEmpty
                      ? item.product.description
                      : "Roti hangat dari oven",
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
                      "Rp ${formatRupiah(item.product.harga)}",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.colors.primaryOrange,
                      ),
                    ),
                    _QtySelector(cart: cart, index: index, quantity: item.quantity),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ----- Quantity Selector (private) -----

class _QtySelector extends StatelessWidget {
  final CartProvider cart;
  final int index;
  final int quantity;

  const _QtySelector({
    required this.cart,
    required this.index,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.colors.bgColor,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _CircleBtn(
            icon: Icons.remove_rounded,
            bg: context.colors.white,
            iconColor: context.colors.textDark,
            onTap: () => cart.decreaseQuantity(index),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "$quantity",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: context.colors.textDark,
              ),
            ),
          ),
          _CircleBtn(
            icon: Icons.add_rounded,
            bg: context.colors.primaryOrange,
            iconColor: context.colors.white,
            hasShadow: true,
            onTap: () => cart.increaseQuantity(index),
          ),
        ],
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final bool hasShadow;
  final VoidCallback onTap;

  const _CircleBtn({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.onTap,
    this.hasShadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          boxShadow: hasShadow
              ? [
                  BoxShadow(
                    color: context.colors.primaryOrange.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Icon(icon, size: 14, color: iconColor),
      ),
    );
  }
}

