import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../cart/providers/cart_provider.dart';
import '../../cart/widgets/animated_cart_icon.dart';
import '../../notification/widgets/notification_icon_badge.dart';
import 'cart_fly_animation.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class ProductAppBar extends StatefulWidget {
  final void Function(String query) onSearchChanged;
  final VoidCallback onFilterTap;

  const ProductAppBar({
    super.key, 
    required this.onSearchChanged,
    required this.onFilterTap,
  });

  @override
  State<ProductAppBar> createState() => _ProductAppBarState();
}

class _ProductAppBarState extends State<ProductAppBar> {
  // Controller dan Timer untuk Debounce
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String query) {
    // Jika pengguna masih mengetik, batalkan timer sebelumnya
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    // Setel ulang timer untuk menunggu 500 milidetik
    _debounce = Timer(Duration(milliseconds: 500), () {
      widget.onSearchChanged(query); // <-- Panggil fungsi pencarian utama
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Container(
      padding: EdgeInsets.only(top: 50, bottom: 20),
      color: context.colors.bgColor,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "515",
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 30,
                    color: context.colors.textBrown,
                  ),
                ),
                // ── Animasi 2: Badge pop dengan AnimatedSwitcher ──
                Row(
                  children: [
                    NotificationIconBadge(),
                    SizedBox(width: 12),
                    AnimatedCartIcon(
                      cart: cart,
                      iconKey: CartFlyAnimation.cartIconKey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 15),
          _ProductSearchBar(
            controller: _searchController,
            onChanged: _onChanged,
            onFilterTap: widget.onFilterTap,
          ),
        ],
      ),
    );
  }
}

// ----- Search Bar -----

class _ProductSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onFilterTap;

  const _ProductSearchBar({
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20),
      height: 48,
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
              color: context.colors.textDark.withValues(alpha: 0.02), blurRadius: 5)
        ],
      ),
      child: Row(
        children: [
          SizedBox(width: 16),
          Icon(Icons.search,
              color: context.colors.primaryOrange.withValues(alpha: 0.7), size: 18),
          SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: "Cari Roti Pia Susu...",
                hintStyle: GoogleFonts.plusJakartaSans(
                    color: context.colors.textHint, fontSize: 14),
                border: InputBorder.none,
              ),
            ),
          ),
          GestureDetector(
            onTap: onFilterTap,
            child: Padding(
              padding: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: context.colors.primaryOrange,
                child: Icon(Icons.tune, color: context.colors.white, size: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
