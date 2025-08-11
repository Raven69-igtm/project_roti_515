import 'package:flutter/material.dart';
import 'checkout_styles.dart';
import 'package:roti_515/core/theme/app_theme.dart';

/// Opsi pengambilan produk — "Ambil Di Toko".
class CheckoutDeliveryOption extends StatelessWidget {
  const CheckoutDeliveryOption({super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: kSectionPadding,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: context.colors.primaryOrange.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: Offset(0, 4),
              )
            ],
            border: Border.all(
              color: context.colors.primaryOrange.withValues(alpha: 0.5), 
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleIconWidget(
                icon: Icons.storefront_rounded,
                bg: context.colors.primaryOrange.withValues(alpha: 0.1),
                color: context.colors.primaryOrange,
                margin: EdgeInsets.only(right: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ambil Di Toko',
                        style: jakartaBold(16, context.colors.textDark)),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.colors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('Gratis', style: jakartaBold(14, context.colors.success)),
              ),
            ],
          ),
        ),
      );
}
