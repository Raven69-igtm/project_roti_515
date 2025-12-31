Laporan Iterasi 2 - Fitur 1 (PB-06 - Keranjang & Favorit)

Dokumen ini disusun tanpa simbol markdown heading (seperti #, ##) agar Anda bisa langsung menyalin dan menempelkannya (copy-paste) ke Microsoft Word atau Google Docs dengan rapi.

========================================================================

a) Fitur 1: Keranjang & Favorit (PB-06 - Pelanggan dapat menambahkan produk ke keranjang belanja dan menandai produk sebagai favorit)

1. Deskripsi Fitur
Fitur Keranjang Belanja dan Favorit dirancang untuk membantu pelanggan mengelola produk roti pilihan mereka sebelum melakukan transaksi pembelian. Pelanggan dapat menambahkan produk dari katalog beranda langsung ke dalam keranjang, menaikkan atau menurunkan jumlah item (quantity), menghapus produk satu per satu, serta menghapus seluruh isi keranjang sekaligus. Di samping itu, pelanggan juga dapat menandai produk roti favorit mereka agar mudah diakses kembali melalui halaman khusus favorit.

2. Implementasi Teknis & Alur Kerja
* Manajemen State Belanja: Menggunakan CartProvider untuk mengoperasikan list belanjaan secara lokal (client-side) di memori HP. Setiap perubahan (seperti tombol +/- kuantitas) langsung memicu notifyListeners() sehingga total harga dan jumlah badge keranjang terupdate secara instan.
* Validasi Stok Batas Maksimum: Sistem secara otomatis mengecek sisa stok produk roti sebelum mengizinkan penambahan kuantitas di keranjang, sehingga kuantitas tidak akan pernah melebihi batas stok aman.
* State Toggling Favorit: Menggunakan FavoriteProvider dengan metode toggleFavorite() untuk menambah/menghapus item roti dari daftar favorit secara interaktif.

3. Kode Sumber Lengkap (Full Source Code)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/cart_provider.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary_bar.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      appBar: _buildAppBar(context),
      body: Consumer<CartProvider>(
        builder: (context, cart, child) {
          if (cart.items.isEmpty) {
            return CartEmptyState();
          }

          final int subtotal = cart.totalPrice;
          int deliveryFee = 0; // Gratis, Ambil Di Toko
          final int total = subtotal + deliveryFee;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) => CartItemCard(
                    item: cart.items[index],
                    index: index,
                  ),
                ),
              ),
              CartSummaryBar(
                subtotal: subtotal,
                deliveryFee: deliveryFee,
                total: total,
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: context.colors.bgColor.withValues(alpha: 0.95),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: context.colors.textDark, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text(
        "Keranjang",
        style: GoogleFonts.plusJakartaSans(
          color: context.colors.textDark,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      actions: [
        Consumer<CartProvider>(
          builder: (context, cart, _) => TextButton(
            onPressed: () => cart.clearCart(),
            child: Text(
              "Hapus Semua",
              style: GoogleFonts.plusJakartaSans(
                color: context.colors.primaryOrange,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
      ],
    );
  }
}
```

```dart
import 'package:flutter/material.dart';

import '../../product/models/product_model.dart'; 

class CartItem {
  final ProductModel product; 
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  int get totalPrice => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;
  
  int get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(ProductModel product) { 
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      if (_items[existingIndex].quantity < product.stock) {
        _items[existingIndex].quantity++;
      }
    } else {
      if (product.stock > 0) {
        _items.add(CartItem(product: product));
      }
    }
    notifyListeners(); 
  }

  void increaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity < _items[index].product.stock) {
        _items[index].quantity++;
        notifyListeners();
      }
    }
  }

  void decreaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
```

```dart
import 'package:flutter/material.dart';

import '../widgets/favorite_app_bar.dart';
import '../widgets/favorite_grid.dart';
import 'package:roti_515/core/theme/app_theme.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgColor,
      body: Stack(
        children: [
          FavoriteGrid(),
          FavoriteAppBar(),
        ],
      ),
    );
  }
}
```

```dart
import 'package:flutter/material.dart';

import '../../product/models/product_model.dart'; 

class FavoriteProvider extends ChangeNotifier {
  final List<ProductModel> _favoriteItems = [];

  List<ProductModel> get favorites => _favoriteItems;

  bool isFavorite(ProductModel product) {
    return _favoriteItems.any((item) => item.id == product.id);
  }

  void toggleFavorite(ProductModel product) {
    final index = _favoriteItems.indexWhere((item) => item.id == product.id);
    if (index >= 0) {
      _favoriteItems.removeAt(index);
    } else {
      _favoriteItems.add(product);
    }
    notifyListeners();
  }
}
```
