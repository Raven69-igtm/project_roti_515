import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';
import '../../cart/providers/cart_provider.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/utils/price_formatter.dart';
import '../../../core/widgets/universal_image.dart';
import '../../product/models/product_model.dart';
import '../../../core/utils/premium_snackbar.dart';
import '../../product/screens/product_detail_screen.dart';
import '../../favorite/providers/favorite_provider.dart';
import '../../product/widgets/animated_favorite_button.dart';
import 'package:roti_515/core/theme/app_theme.dart';

/// Komponen UI berbentuk kartu untuk menampilkan produk terlaris di Home Screen.
class BestsellerCard extends StatelessWidget {
  // Properti model produk yang wajib dikirim saat menggunakan komponen ini
  final ProductModel product;
  const BestsellerCard({super.key, required this.product});

  void _showAddedSnackBar(BuildContext context, String productName) {
    PremiumSnackbar.showSuccess(context, "$productName ditambahkan!");
  }

  @override
  Widget build(BuildContext context) {
    // Container utama kartu pembungkus produk
    return Container(
      width: 170, // Sama seperti ukuran ideal ProductCard di layout grid 2 kolom
      margin: EdgeInsets.only(right: 16), // Jarak margin kanan antar kartu sebesar 16
      clipBehavior: Clip.hardEdge, // Pastikan konten tidak meluber keluar card
      decoration: BoxDecoration(
        color: context.colors.white, // Latar belakang kartu berwarna putih
        borderRadius: BorderRadius.circular(32), // Sama dengan ProductCard
        border: Border.all(color: context.colors.divider), // Garis tepi pinggiran (border) transparan/ringan
        boxShadow: [
          BoxShadow(
            color: context.colors.textDark.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      // Konten disusun secara vertikal (gambar di atas, teks di bawah)
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Rata kiri text
        children: [
          // Area Gambar Produk (Thumbnail)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6), // kurangi padding gambar
            // Menggunakan Stack untuk menumpuk elemen: [1]Gambar Roti, di atasnya ada [2]Rating, dan [3]Love
            child: Stack(
              children: [
                // Memotong sudut siku-siku gambar asli agar ikut melengkung sesuai tepi dalam kartu
                ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  // Memuat URL foto produk dari server melalui network
                  child: Hero(
                    tag: 'product-image-${product.id}',
                    child: UniversalImage(
                      imageUrl: product.gambar,
                      height: 135, // Kurangi dari 150 agar tidak overflow
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                
                // Elemen Mengambang Kiri Atas: Lencana Nilai Ulasan (Rating)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.colors.white.withValues(alpha: 0.9), // Putih sedikit transparan
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Ikon Bintang Kuning
                        Icon(Icons.star_rounded,
                            color: context.colors.primaryOrange, size: 10),
                        SizedBox(width: 4),
                        // Teks Angka Rating (contoh: 4.8)
                        Text(
                          "${product.rating}",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primaryOrange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Elemen Mengambang Kanan Atas: Tombol Favorit (Love/Heart)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer<FavoriteProvider>(
                    builder: (context, favProvider, _) {
                      final bool isFav = favProvider.isFavorite(product);
                      return AnimatedFavoriteButton(
                        isFavorite: isFav,
                        onTap: () => favProvider.toggleFavorite(product),
                      );
                    },
                  ),
                ),
                
                // Badge Stok (Animasi 2)
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

                // Elemen Mengambang Kanan Bawah: Badge Detail
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
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label Judul "Nama Roti"
                Text(
                  product.nama,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: context.colors.textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Label Deskripsi Varian Roti (Kecil)
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
                const SizedBox(height: 4),
                Text(
                  "Terjual ${product.soldCount}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: context.colors.primaryOrange,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Row Harga + Tombol (+)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Harga — dibungkus Flexible agar tidak overflow jika harga panjang
                    Flexible(
                      child: Text(
                        "Rp ${formatRupiah(product.harga)}",
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.colors.textDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Tombol (+) Tambah ke keranjang
                    GestureDetector(
                      onTap: () {
                        Provider.of<CartProvider>(context, listen: false).addToCart(product);
                        _showAddedSnackBar(context, product.nama);
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
        ],
      ),
    );
  }
}

