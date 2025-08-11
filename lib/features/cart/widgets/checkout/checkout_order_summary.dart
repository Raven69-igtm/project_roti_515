import 'package:flutter/material.dart';
import '../../../../core/utils/price_formatter.dart';
import '../../providers/cart_provider.dart';
import 'checkout_styles.dart';
import 'package:roti_515/core/theme/app_theme.dart';

/// Ringkasan produk yang dipesan + total harga.
class CheckoutOrderSummary extends StatelessWidget {
  final CartProvider cart;
  final int deliveryFee;

  const CheckoutOrderSummary(
      {super.key, required this.cart, required this.deliveryFee});

  @override
  Widget build(BuildContext context) => Padding(
        padding: kSectionPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ringkasan Pesanan',
                style: jakartaBold(18, context.colors.textDark, height: 28 / 18)),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Color(0xFFF3F4F6)),
                boxShadow: kCardShadow,
              ),
              child: Column(
                children: [
                  ...List.generate(
                    cart.items.length,
                    (i) => _SummaryItem(
                      product: cart.items[i].product,
                      qty: cart.items[i].quantity,
                      showDivider: i < cart.items.length - 1,
                    ),
                  ),
                  Divider(color: Color(0xFFF3F4F6), height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total',
                          style: jakartaRegular(14, context.colors.textBrown)),
                      Text(
                          'Rp ${formatRupiah(cart.totalPrice + deliveryFee)}',
                          style: jakartaMedium(14, context.colors.textDark)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

// ── Private ───────────────────────────────────────────────────────────────────

class _SummaryItem extends StatelessWidget {
  final dynamic product;
  final int qty;
  final bool showDivider;

  const _SummaryItem(
      {required this.product, required this.qty, this.showDivider = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: showDivider ? 16 : 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.network(
                    product.imageUrl.isNotEmpty
                        ? product.imageUrl
                        : 'https://placehold.co/64x64',
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(product.name,
                                style: jakartaBold(14, context.colors.textDark,
                                    height: 20 / 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          SizedBox(width: 8),
                          Text('Rp ${formatRupiah(product.price)}',
                              style: jakartaBold(14, context.colors.textDark,
                                  height: 20 / 14)),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        product.description.isNotEmpty
                            ? product.description
                            : 'Roti 515',
                        style: pontano(12, context.colors.textGrey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text('Jumlah : $qty',
                          style: pontano(12, context.colors.primaryOrange,
                              weight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (showDivider)
            Divider(color: Color(0xFFF3F4F6), height: 16),
        ],
      );
}

