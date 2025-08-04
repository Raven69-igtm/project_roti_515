import 'package:flutter/material.dart';

// --- IMPORT MODEL BARU ---
// Gunakan jalur relatif untuk memanggil ProductModel dari fitur product
import '../../product/models/product_model.dart'; 

// --- DEFINISI CART ITEM ---
class CartItem {
  final ProductModel product; // Ganti dari Product lama ke ProductModel baru
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  // Total harga per item (Harga x Jumlah) - Menggunakan int
  int get totalPrice => product.price * quantity;
}

// --- CART PROVIDER (Otak Keranjang Roti 515) ---
class CartProvider extends ChangeNotifier {
  // List penyimpanan barang belanjaan
  final List<CartItem> _items = [];

  // Getter untuk UI
  List<CartItem> get items => _items;
  
  // Hitung total semua harga (Subtotal) - Output int
  int get totalPrice => _items.fold(0, (sum, item) => sum + item.totalPrice);
  
  // Hitung total jumlah barang (untuk badge di icon keranjang)
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  // 1. TAMBAH KE KERANJANG
  void addToCart(ProductModel product) { // Ganti tipe data ke ProductModel
    // Cek apakah produk ini sudah ada di keranjang?
    final existingIndex = _items.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      // Kalau sudah ada, tambah quantity-nya saja jika belum mencapai batas stok
      if (_items[existingIndex].quantity < product.stock) {
        _items[existingIndex].quantity++;
      }
    } else {
      // Kalau belum ada, masukkan sebagai item baru jika stok masih ada
      if (product.stock > 0) {
        _items.add(CartItem(product: product));
      }
    }
    notifyListeners(); // Update UI!
  }

  // 2. TAMBAH JUMLAH (Tombol +) 
  void increaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity < _items[index].product.stock) {
        _items[index].quantity++;
        notifyListeners();
      }
    }
  }

  // 3. KURANGI JUMLAH (Tombol -)
  void decreaseQuantity(int index) {
    if (index >= 0 && index < _items.length) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        // Jika sisa 1 dan dikurangi, maka hapus dari keranjang
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // 4. HAPUS SATU ITEM (Tombol Sampah)
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  // 5. BERSIHKAN KERANJANG (Setelah Checkout)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
