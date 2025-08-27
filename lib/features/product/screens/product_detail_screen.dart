import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../widgets/detail/detail_widgets.dart';
import '../widgets/detail/detail_bottom_bar.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _increaseQty() => setState(() => _quantity++);
  void _decreaseQty() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      body: Stack(
        children: [
          // Konten utama yang bisa di-scroll
          SingleChildScrollView(
            padding: EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DetailImageHeader(product: widget.product),
                DetailProductInfo(product: widget.product),
                DetailDescription(product: widget.product),
                DetailQuantitySelector(
                  quantity: _quantity,
                  onIncrease: _increaseQty,
                  onDecrease: _decreaseQty,
                ),
              ],
            ),
          ),

          // Tombol kembali & favorit (floating glassmorphism)
          DetailFloatingActions(product: widget.product),

          // Sticky bottom bar
          Align(
            alignment: Alignment.bottomCenter,
            child: DetailBottomBar(
              product: widget.product,
              quantity: _quantity,
            ),
          ),
        ],
      ),
    );
  }
}
